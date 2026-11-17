# -*- coding: utf-8 -*-
"""
Strinova BWiki <-> 本地 内容同步脚本

支持的命名空间与本地目录映射（目录名统一为纯英文首字母大写）：

    Templates/   <- Template   (NS 10)   扩展名 .wikitext
    Modules/     <- Module     (NS 828)  扩展名 .lua
    Widget/      <- Widget     (NS 274)  扩展名 .wikitext
    MediaWiki/   <- MediaWiki  (NS 8)    扩展名按页面标题后缀：.css / .js / .json / .wikitext

用法：
    模式 A（拉取）：保留文件末尾的 pull_all(...)，把线上内容拉到本地；
    模式 B（推送）：注释掉 pull_all，放开 push_all_changed，把本地改动增量推回线上。
"""

import os
import time
import random
import json
import hashlib
import threading
from dataclasses import dataclass

import mwclient
import rookiepy
import cloudscraper
from concurrent.futures import ThreadPoolExecutor, as_completed

# ================= 路径配置 =================
# 1. 获取当前脚本所在的绝对路径
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# 2. 设置项目根目录
PROJECT_ROOT = SCRIPT_DIR
os.chdir(PROJECT_ROOT)


# ================= 命名空间配置 =================
@dataclass(frozen=True)
class NamespaceSpec:
    """一个 MediaWiki 命名空间对应的本地目录与文件规则"""

    key: str                 # 内部标识
    ns_id: int               # 线上命名空间 ID
    dir_name: str            # 本地目录名（纯英文，首字母大写）
    label: str               # 日志里显示的说明
    prefixes: tuple          # 页面标题可能带的命名空间前缀（本地化 / 英文）
    default_ext: str         # 默认扩展名
    skip_doc: bool = True    # 是否跳过 /doc 文档说明页
    skip_sandbox: bool = True  # 是否跳过沙盒页
    ext_by_title: tuple = ()  # 按标题后缀决定扩展名（用于 MediaWiki 空间的 css/js/json）

    @property
    def push_exts(self):
        """该命名空间下允许推送的扩展名集合（小写）"""
        exts = {self.default_ext.lower()}
        exts.update(e.lower() for e in self.ext_by_title)
        return tuple(sorted(exts))


NAMESPACE_SPECS = (
    NamespaceSpec(
        key="template",
        ns_id=10,
        dir_name="Templates",
        label="模板 (Template · NS 10)",
        prefixes=("Template:", "模板:"),
        default_ext=".wikitext",
    ),
    NamespaceSpec(
        key="module",
        ns_id=828,
        dir_name="Modules",
        label="模块 (Module · NS 828)",
        prefixes=("Module:", "模块:"),
        default_ext=".lua",
    ),
    NamespaceSpec(
        key="widget",
        ns_id=274,
        dir_name="Widget",
        label="Widget (NS 274)",
        prefixes=("Widget:",),
        default_ext=".wikitext",
    ),
    NamespaceSpec(
        key="mediawiki",
        ns_id=8,
        dir_name="MediaWiki",
        label="MediaWiki (NS 8)",
        prefixes=("MediaWiki:",),
        default_ext=".wikitext",
        # 系统消息页不按 /doc、沙盒规则过滤，避免误杀真正的系统页
        skip_doc=False,
        skip_sandbox=False,
        ext_by_title=(".css", ".js", ".json"),
    ),
)

SPECS_BY_KEY = {spec.key: spec for spec in NAMESPACE_SPECS}

# 本地化前缀 -> 规范前缀（线上返回 "模块:Foo"，本地映射到 "Module:Foo"，比较时必须统一）
PREFIX_CANON = {}
for _spec in NAMESPACE_SPECS:
    for _prefix in _spec.prefixes:
        PREFIX_CANON[_prefix] = _spec.prefixes[0]

# 旧目录名 -> 新目录名：首次运行自动迁移，兼容历史工作副本
LEGACY_DIR_MAP = {
    "模板(templates)": "Templates",
    "模块(modules)": "Modules",
}

# 拉取完成后是否删除「本地有、线上已没有」的页面文件（会真实删除本地文件）
PRUNE_AFTER_PULL = False


# ================= 登录态 Site 实例 =================
def get_site_instance():
    """使用 rookiepy + cloudscraper 构建带登录态的 mwclient Site 实例"""
    cookies = rookiepy.firefox(["biligame.com", "bilibili.com"])

    scraper = cloudscraper.create_scraper(
        browser={
            'browser': 'firefox',
            'platform': 'windows',
            'desktop': True
        }
    )

    # 注入 Cookie
    for cookie in cookies:
        scraper.cookies.set(cookie['name'], cookie['value'])

    # 添加 Bwiki 防火墙防盗链 Header
    scraper.headers.update({
        "Referer": "https://wiki.biligame.com/klbq/",
        "Origin": "https://wiki.biligame.com"
    })

    # 初始化 mwclient 实例
    site = mwclient.Site(
        "wiki.biligame.com",
        path="/klbq/",
        clients_useragent=scraper.headers['User-Agent'],
        pool=scraper
    )
    return site


# ================= 核心管理类 =================
class WikiSyncManager:
    """处理增量拉取、本地哈希缓存与增量推送（模板 / 模块 / Widget / MediaWiki）"""

    def __init__(self, site, output_dir=SCRIPT_DIR, max_workers=3):
        self.site = site
        self.output_dir = output_dir
        self.max_workers = max_workers
        self.cache_file = os.path.join(output_dir, ".sync_cache.json")

        # 各命名空间对应的本地目录
        self.dirs = {
            spec.key: os.path.join(output_dir, spec.dir_name)
            for spec in NAMESPACE_SPECS
        }

        # 线程锁：保证多线程更新 JSON 缓存文件时的读写安全
        self.lock = threading.Lock()

        # 运行统计
        self.stats = {
            spec.key: {"ok": 0, "fail": 0, "skip": 0}
            for spec in NAMESPACE_SPECS
        }

        # 1. 老目录改名迁移（模板(templates) -> Templates，模块(modules) -> Modules）
        self._migrate_legacy_layout()

        # 2. 建目录
        for directory in self.dirs.values():
            os.makedirs(directory, exist_ok=True)

        # 3. 加载本地哈希缓存，并把老目录的缓存 key 迁移到新目录名下
        self.cache = self._load_cache()
        if self._remap_cache_keys():
            self._save_cache()

    # ---------------- 0. 目录迁移与缓存 ----------------

    def _migrate_legacy_layout(self):
        """把历史目录名下的内容搬到新的英文目录名，并清理空目录"""
        for legacy_name, new_name in LEGACY_DIR_MAP.items():
            legacy_path = os.path.join(self.output_dir, legacy_name)
            if not os.path.isdir(legacy_path):
                continue

            new_path = os.path.join(self.output_dir, new_name)
            os.makedirs(new_path, exist_ok=True)

            moved = 0
            failed = 0
            for root, _dirs, files in os.walk(legacy_path):
                rel = os.path.relpath(root, legacy_path)
                target_dir = new_path if rel == "." else os.path.join(new_path, rel)
                if files:
                    os.makedirs(target_dir, exist_ok=True)

                for name in files:
                    src = os.path.join(root, name)
                    dst = os.path.join(target_dir, name)
                    if os.path.abspath(src) == os.path.abspath(dst):
                        continue
                    try:
                        # 同名文件直接覆盖：旧目录视为过期副本
                        os.replace(src, dst)
                        moved += 1
                    except OSError as e:
                        failed += 1
                        print(f"⚠️ [迁移失败] {src} -> {dst}: {e}")

            self._prune_empty_dirs(legacy_path)
            print(f"📦 [目录迁移] {legacy_name}/ -> {new_name}/ ，已移动 {moved} 个文件")
            if failed:
                print(f"⚠️ 有 {failed} 个文件迁移失败，请手动检查 {legacy_name}/ 后再删除")
            elif os.path.isdir(legacy_path):
                print(f"⚠️ {legacy_name}/ 仍有残留内容，请手动确认")

    @staticmethod
    def _prune_empty_dirs(root):
        """自底向上删除空目录（绝不删除仍含文件的目录）"""
        for current, _dirs, files in os.walk(root, topdown=False):
            if files:
                continue
            try:
                if not os.listdir(current):
                    os.rmdir(current)
            except OSError:
                pass

    def _load_cache(self):
        """读取本地哈希缓存文件"""
        if os.path.exists(self.cache_file):
            try:
                with open(self.cache_file, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                print(f"⚠️ 读取缓存失败，将重新建立缓存: {e}")
                return {}
        return {}

    def _save_cache(self):
        """持久化哈希缓存（调用方负责加锁或处于单线程安全场景）"""
        with open(self.cache_file, "w", encoding="utf-8") as f:
            json.dump(self.cache, f, ensure_ascii=False, indent=2)

    def _remap_cache_keys(self):
        """把缓存里的老目录前缀替换成新目录名，返回是否有改动"""
        changed = False
        for legacy_name, new_name in LEGACY_DIR_MAP.items():
            old_prefix = legacy_name + "/"
            new_prefix = new_name + "/"
            for key in list(self.cache.keys()):
                if key.startswith(old_prefix):
                    self.cache[new_prefix + key[len(old_prefix):]] = self.cache.pop(key)
                    changed = True
        return changed

    def _update_cache(self, relative_path, file_hash):
        """线程安全地更新并保存哈希缓存"""
        norm_rel_path = relative_path.replace("\\", "/")
        with self.lock:
            self.cache[norm_rel_path] = file_hash
            self._save_cache()

    def _calculate_file_hash(self, filepath):
        """计算本地文件的 MD5 哈希值"""
        hasher = hashlib.md5()
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                hasher.update(chunk)
        return hasher.hexdigest()

    def _random_delay(self, min_s=1.0, max_s=2.5):
        """随机延迟，防高频拦截"""
        time.sleep(random.uniform(min_s, max_s))

    def _bump(self, spec, field):
        """线程安全地累加统计计数"""
        with self.lock:
            self.stats[spec.key][field] += 1

    # ---------------- 1. 页面 <-> 文件路径映射 ----------------

    @staticmethod
    def _page_spec(page):
        """判定页面属于哪个命名空间：优先看 namespace ID，其次看标题前缀"""
        ns_id = getattr(page, "namespace", None)
        for spec in NAMESPACE_SPECS:
            if ns_id == spec.ns_id:
                return spec

        name = page.name
        for spec in NAMESPACE_SPECS:
            if name.startswith(spec.prefixes):
                return spec

        # 兜底：无法判定时按模板处理（与老版本行为一致）
        return SPECS_BY_KEY["template"]

    @staticmethod
    def _resolve_ext(spec, title):
        """决定文件扩展名：MediaWiki 空间按标题后缀（.css/.js/.json）走"""
        if spec.ext_by_title:
            lowered = title.lower()
            for ext in spec.ext_by_title:
                if lowered.endswith(ext):
                    return ext
        return spec.default_ext

    def _get_filepath_from_page(self, page):
        """将页面标题换算成本地文件路径，斜杠 / 替换为双下划线 __ 拍平保存"""
        spec = self._page_spec(page)
        title = page.name

        raw_name = title
        for prefix in spec.prefixes:
            if raw_name.startswith(prefix):
                raw_name = raw_name[len(prefix):]
                break

        ext = self._resolve_ext(spec, title)
        base_dir = self.dirs[spec.key]

        # 默认方案：斜杠拍平成双下划线
        flat_name = raw_name.replace("/", "__")
        # MediaWiki:Common.css 这类标题本身已带扩展名，避免变成 Common.css.wikitext
        if not flat_name.lower().endswith(ext.lower()):
            flat_name += ext
        flat_path = os.path.join(base_dir, flat_name)

        # 兼容历史布局：早期版本按真实子目录保存过（如 A/B.wikitext），
        # 若该文件已存在则不新造拍平版，避免同一页面出现两份本地文件
        if "/" in raw_name:
            nested_name = raw_name if raw_name.lower().endswith(ext.lower()) else raw_name + ext
            nested_path = os.path.join(base_dir, *nested_name.split("/"))
            try:
                nested_exists = os.path.isfile(nested_path)
                flat_exists = os.path.isfile(flat_path)
            except OSError:
                nested_exists = flat_exists = False

            if nested_exists and not flat_exists:
                return nested_path
            if nested_exists and flat_exists:
                print(f"⚠️ [布局重复] {nested_name} 与 {flat_name} 指向同一页面 {title}，请手动保留其中一个")

        return flat_path

    def _get_title_from_filepath(self, filepath):
        """根据文件名与所属目录精准还原带斜杠的 Wiki 页面标题"""
        abs_filepath = os.path.abspath(filepath)
        filename = os.path.basename(filepath)
        name_without_ext, ext = os.path.splitext(filename)

        # 兜底：仅用文件名（不含目录层级）还原
        fallback_name = name_without_ext.replace("__", "/")

        for spec in NAMESPACE_SPECS:
            base_dir = os.path.abspath(self.dirs[spec.key])
            try:
                common = os.path.commonpath([abs_filepath, base_dir])
            except ValueError:
                # 不同盘符等情况
                continue
            if os.path.normcase(common) != os.path.normcase(base_dir):
                continue

            prefix = spec.prefixes[0]
            # 相对路径的每一段都还原 __ -> /，保证子目录形式（A/B.wikitext）也能还原成 A/B
            rel_path = os.path.relpath(abs_filepath, base_dir)
            rel_no_ext = os.path.splitext(rel_path)[0]
            segments = [seg.replace("__", "/") for seg in rel_no_ext.split(os.sep)]
            wiki_name = "/".join(seg for seg in segments if seg)

            # MediaWiki 空间的 css/js/json 页面，标题本身就是带扩展名的
            if ext and ext.lower() in tuple(e.lower() for e in spec.ext_by_title):
                return f"{prefix}{wiki_name}{ext}"
            return f"{prefix}{wiki_name}"

        # 兜底退化方案
        if ext.lower() == ".lua":
            return f"Module:{fallback_name}"
        if ext.lower() in (".css", ".js", ".json"):
            return f"MediaWiki:{fallback_name}{ext}"
        return f"Template:{fallback_name}"

    # ---------------- 2. 拉取逻辑 ----------------

    @staticmethod
    def _skip_reason(spec, title):
        """返回跳过原因，None 表示需要拉取"""
        lowered = title.lower()
        if spec.skip_doc and lowered.endswith("/doc"):
            return "文档页"
        if spec.skip_sandbox and (lowered.endswith("沙盒") or lowered.endswith("sandbox")):
            return "沙盒页"
        return None

    def fetch_single_page(self, page):
        """拉取单个页面到本地并写入缓存"""
        spec = self._page_spec(page)
        reason = self._skip_reason(spec, page.name)
        if reason:
            print(f"⏩ [跳过{reason}] {page.name} 喵")
            self._bump(spec, "skip")
            return True

        try:
            self._random_delay(0.5, 1.5)
            content = page.text()
            filepath = self._get_filepath_from_page(page)
            os.makedirs(os.path.dirname(filepath), exist_ok=True)

            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)

            file_hash = self._calculate_file_hash(filepath)
            relative_path = os.path.relpath(filepath, self.output_dir)
            self._update_cache(relative_path, file_hash)

            self._bump(spec, "ok")
            print(f"✅ [已拉取并缓存] {page.name} -> {relative_path.replace(os.sep, '/')}")
            return True
        except Exception as e:
            self._bump(spec, "fail")
            print(f"❌ [拉取失败] {page.name}: {e} 喵")
            return False

    def pull_all(self, include_templates=True, include_modules=True,
                 include_widgets=True, include_mediawiki=True):
        """批量拉取站内模板(10)、模块(828)、Widget(274)、MediaWiki(8)"""
        enabled = {
            "template": include_templates,
            "module": include_modules,
            "widget": include_widgets,
            "mediawiki": include_mediawiki,
        }

        active_specs = [spec for spec in NAMESPACE_SPECS if enabled[spec.key]]
        if not active_specs:
            print("✨ 没有勾选任何命名空间，本次不拉取")
            return

        pages_to_fetch = []
        for spec in active_specs:
            print(f"🔍 正在检索线上{spec.label} ...")
            try:
                pages = list(self.site.allpages(namespace=spec.ns_id))
            except Exception as e:
                print(f"❌ [检索失败] {spec.label}: {e}")
                continue

            kept = [p for p in pages if not self._skip_reason(spec, p.name)]
            skipped = len(pages) - len(kept)
            print(
                f"   └─ 检索到 {len(pages)} 个页面，自动过滤 {skipped} 个（/doc、沙盒），"
                f"待拉取 {len(kept)} 个 -> {spec.dir_name}/"
            )
            pages_to_fetch.extend(kept)

        if not pages_to_fetch:
            print("✨ 线上没有需要拉取的页面")
            return

        print(f"\n🚀 开始多线程批量拉取（并发线程数: {self.max_workers}）...")
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = [executor.submit(self.fetch_single_page, page) for page in pages_to_fetch]
            for future in as_completed(futures):
                future.result()

        self._print_stats("拉取")
        print("🎉 批量拉取全部完成喵！")

    def _print_stats(self, action):
        """打印各命名空间的成功/失败/跳过统计"""
        print(f"\n📊 {action}结果统计：")
        for spec in NAMESPACE_SPECS:
            stat = self.stats[spec.key]
            if not any(stat.values()):
                continue
            print(
                f"   • {spec.dir_name:<10} 成功 {stat['ok']:>4} / "
                f"失败 {stat['fail']:>3} / 跳过 {stat['skip']:>3}"
            )

    # ---------------- 3. 本地孤儿清理 ----------------

    @staticmethod
    def _normalize_title(title):
        """标题归一化：本地化前缀统一成规范前缀、下划线换空格、首字母大写

        线上 allpages 返回的是本地化标题（如「模块:Foo」「模板:Foo」），
        而本地文件按规范前缀还原成「Module:Foo」「Template:Foo」，
        不统一前缀就会把所有模板/模块都误判成孤儿。
        """
        normalized = title.replace("_", " ").strip()
        lowered = normalized.lower()
        for prefix, canonical in PREFIX_CANON.items():
            if lowered.startswith(prefix.lower()):
                normalized = canonical + normalized[len(prefix):]
                break
        return normalized[:1].upper() + normalized[1:] if normalized else normalized

    def collect_online_titles(self, specs=None):
        """读取各命名空间线上的全部页面标题（用于判断本地文件是否还有对应页面）"""
        titles = {}
        for spec in (specs or NAMESPACE_SPECS):
            print(f"🔍 正在读取线上{spec.label}的页面清单 ...")
            try:
                titles[spec.key] = {
                    self._normalize_title(page.name)
                    for page in self.site.allpages(namespace=spec.ns_id)
                }
            except Exception as e:
                print(f"❌ [读取失败] {spec.label}: {e}")
                titles[spec.key] = None
                continue
            print(f"   └─ {len(titles[spec.key])} 个页面")
        return titles

    def _page_exists(self, title):
        """线上是否存在该页面；查询异常时保守返回 True（宁可留着也不误删）"""
        try:
            return bool(self.site.pages[title].exists)
        except Exception as e:
            print(f"⚠️ [查询失败] {title}: {e}，按「仍存在」处理")
            return True

    def prune_local_orphans(self, online_titles=None, dry_run=False):
        """删除「本地存在、线上已不存在」的页面文件，并清掉对应缓存键

        注意：判断依据是页面标题，不是文件内容；拉取失败或标题无法判定的文件不会被删。
        """
        if online_titles is None:
            online_titles = self.collect_online_titles()

        orphans = []
        for spec, filepath in self._iter_local_files():
            known = online_titles.get(spec.key)
            if known is None:
                # 该命名空间的线上清单读取失败，跳过清理以免误删
                continue
            title = self._get_title_from_filepath(filepath)
            if self._normalize_title(title) in known:
                continue
            # 二次确认：清单之外再问一次接口，同时兼容文件名里本就带 __ 的页面
            # 注意必须限速，否则连续上百次 exists 会被防火墙判定为异常流量
            self._random_delay(0.2, 0.6)
            if self._page_exists(title) or self._page_exists(title.replace("/", "__")):
                continue
            orphans.append((spec, filepath, title))

        if not orphans:
            print("✨ 本地没有「线上已不存在」的页面，无需清理")
            return []

        print(f"\n🧹 发现 {len(orphans)} 个本地孤儿文件（线上已无对应页面）：")
        for _spec, filepath, title in orphans:
            rel = os.path.relpath(filepath, self.output_dir).replace(os.sep, "/")
            print(f"   - {rel}    (对应 {title})")

        if dry_run:
            print("（dry-run：仅列出，未删除）")
            return orphans

        removed = 0
        for spec, filepath, title in orphans:
            rel = os.path.relpath(filepath, self.output_dir).replace("\\", "/")
            try:
                os.remove(filepath)
            except OSError as e:
                print(f"⚠️ [删除失败] {rel}: {e}")
                continue
            with self.lock:
                self.cache.pop(rel, None)
            removed += 1

        # 清掉因此变空的子目录，并持久化缓存
        for spec in NAMESPACE_SPECS:
            self._prune_empty_dirs(self.dirs[spec.key])
        with self.lock:
            self._save_cache()

        print(f"🗑️ 已删除 {removed} 个孤儿文件（缓存键同步清理）")
        return orphans

    # ---------------- 4. 增量推送逻辑 ----------------

    def push_single_file(self, filepath, summary="Vibe Coding 自动化修改推送", force=False):
        """本地哈希校验推送：未修改则跳过请求"""
        if not os.path.isabs(filepath):
            filepath = os.path.join(self.output_dir, filepath)

        if not os.path.exists(filepath):
            print(f"⚠️ 文件不存在: {filepath}")
            return False

        relative_path = os.path.relpath(filepath, self.output_dir)
        norm_rel_path = relative_path.replace("\\", "/")
        current_hash = self._calculate_file_hash(filepath)
        cached_hash = self.cache.get(norm_rel_path)

        # 智能跳过逻辑：哈希一致且未指定强制推送时，完全不发起 API 请求
        if not force and cached_hash and current_hash == cached_hash:
            print(f"⚡ [跳过] {norm_rel_path} 本地未修改，不发起 API 请求")
            return True

        page_title = self._get_title_from_filepath(filepath)

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                local_content = f.read()

            self._random_delay(1.5, 3.0)
            page = self.site.pages[page_title]

            # 再次校验线上内容（双保险）
            if page.exists and page.text() == local_content:
                print(f"⚠️ [跳过] {page_title} 线上已有相同内容，同步更新本地缓存")
                self._update_cache(relative_path, current_hash)
                return True

            # 保存覆盖线上
            page.save(local_content, summary=summary, bot=True)
            # 推送成功后更新本地哈希缓存
            self._update_cache(relative_path, current_hash)
            print(f"🚀 [推送成功] {page_title}")
            return True
        except Exception as e:
            print(f"💥 [推送失败] {page_title}: {e}")
            return False

    def _iter_local_files(self):
        """只遍历受管的四个命名空间目录，避免误推 main 下的其它文件（如 bili/css）"""
        for spec in NAMESPACE_SPECS:
            root_dir = self.dirs[spec.key]
            exts = spec.push_exts
            for root, _dirs, files in os.walk(root_dir):
                for name in files:
                    if name.startswith("."):
                        continue
                    if name.lower().endswith(exts):
                        yield spec, os.path.join(root, name)

    def push_all_changed(self, summary="智能增量同步本地修改"):
        """扫描本地四个命名空间目录，只自动推送修改过的文件"""
        files_to_check = []
        for spec, filepath in self._iter_local_files():
            files_to_check.append((spec, filepath))

        print(f"\n🔍 正在检查 {len(files_to_check)} 个本地文件的修改状态...")
        changed_files = []
        for spec, filepath in files_to_check:
            rel = os.path.relpath(filepath, self.output_dir).replace("\\", "/")
            if self.cache.get(rel) != self._calculate_file_hash(filepath):
                changed_files.append((spec, filepath))

        if not changed_files:
            print("✨ 没有检测到任何被修改的文件，本次无需推送喵！")
            return

        print(f"🎯 发现 {len(changed_files)} 个被修改的文件，准备推送...")
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = [
                executor.submit(self.push_single_file, filepath, summary)
                for _spec, filepath in changed_files
            ]
            for future in as_completed(futures):
                future.result()

        print("🎉 智能增量推送完成喵！")


# ================= 运行入口 =================
if __name__ == "__main__":
    # 1. 初始化 Site 实例（通过 rookiepy + cloudscraper 绕过防护并拿到登录态）
    site = get_site_instance()

    # 2. 创建同步管理器（首次运行会自动把 模板(templates)/模块(modules) 迁移成 Templates/Modules）
    manager = WikiSyncManager(
        site=site,
        output_dir=SCRIPT_DIR,
        max_workers=3  # 3 线程并发处理
    )

    # -------------------------------------------------------------
    # 模式 A: 首次使用/定期同步：拉取线上全站内容到本地
    #         包含 模板(10)、模块(828)、Widget(274)、MediaWiki(8)
    # -------------------------------------------------------------
    manager.pull_all(
        include_templates=True,
        include_modules=True,
        include_widgets=True,
        include_mediawiki=True,
    )

    # 拉取后清理孤儿文件（线上已删除的页面）：把 PRUNE_AFTER_PULL 改成 True 即可启用
    if PRUNE_AFTER_PULL:
        manager.prune_local_orphans()

    # -------------------------------------------------------------
    # 模式 B: 本地编辑完成后：自动检索修改过的文件并智能推送回 Wiki
    # -------------------------------------------------------------
    # manager.push_all_changed(summary="Bot：批量更新模板、模块、Widget 与 MediaWiki 页面喵")
