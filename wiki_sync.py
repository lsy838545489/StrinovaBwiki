import os
import sys
import time
import random
import json
import hashlib
import threading
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

# 2. 自动获取 Cookie 并初始化 Cloudscraper 伪装 Site 实例
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


# 3. 核心管理类：处理增量拉取、本地哈希缓存与增量推送
class WikiTemplateManager:
    def __init__(self, site, output_dir=SCRIPT_DIR, max_workers=3):
        self.site = site
        self.output_dir = output_dir
        self.templates_dir = os.path.join(output_dir, "模板(templates)")
        self.modules_dir = os.path.join(output_dir, "模块(modules)")
        self.cache_file = os.path.join(output_dir, ".sync_cache.json")
        self.max_workers = max_workers

        # 线程锁：保证多线程更新 JSON 缓存文件时的读写安全
        self.lock = threading.Lock()

        os.makedirs(self.templates_dir, exist_ok=True)
        os.makedirs(self.modules_dir, exist_ok=True)

        # 加载本地哈希缓存
        self.cache = self._load_cache()

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

    def _update_cache(self, relative_path, file_hash):
        """线程安全地更新并保存哈希缓存"""
        norm_rel_path = relative_path.replace("\\", "/")
        with self.lock:
            self.cache[norm_rel_path] = file_hash
            with open(self.cache_file, "w", encoding="utf-8") as f:
                json.dump(self.cache, f, ensure_ascii=False, indent=2)

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

    def _get_filepath_from_page(self, page):
        """将斜杠 / 替换为双下划线 __ 拍平保存喵"""
        title = page.name
        is_module = False

        # 1. 优先根据命名空间 ID 判定 (828 = Module)
        if hasattr(page, 'namespace') and page.namespace == 828:
            is_module = True
        # 2. 兼容字符串前缀判定
        elif title.startswith(("Module:", "模块:")):
            is_module = True

        if is_module:
            raw_name = title
            for prefix in ("Module:", "模块:"):
                if raw_name.startswith(prefix):
                    raw_name = raw_name[len(prefix):]
                    break
            # 将斜杠 / 替换为双下划线 __
            filename = raw_name.replace("/", "__") + ".lua"
            return os.path.join(self.modules_dir, filename)
        else:
            raw_name = title
            for prefix in ("Template:", "模板:"):
                if raw_name.startswith(prefix):
                    raw_name = raw_name[len(prefix):]
                    break
            # 将斜杠 / 替换为双下划线 __
            filename = raw_name.replace("/", "__") + ".wikitext"
            return os.path.join(self.templates_dir, filename)

    def _get_title_from_filepath(self, filepath):
        """根据文件名与所属目录精准还原带斜杠的 Wiki 页面标题喵"""
        abs_filepath = os.path.abspath(filepath)
        abs_modules = os.path.abspath(self.modules_dir)
        abs_templates = os.path.abspath(self.templates_dir)

        filename = os.path.basename(filepath)
        name_without_ext = os.path.splitext(filename)[0]

        # 将双下划线 __ 还原为斜杠 /
        wiki_name = name_without_ext.replace("__", "/")

        # 检查是否属于 模块(modules) 目录
        if abs_filepath.startswith(abs_modules):
            return f"Module:{wiki_name}"

        # 检查是否属于 模板(templates) 目录
        elif abs_filepath.startswith(abs_templates):
            return f"Template:{wiki_name}"

        # 兜底退化方案
        ext = os.path.splitext(filename)[1]
        if ext == ".lua":
            return f"Module:{wiki_name}"
        return f"Template:{wiki_name}"

    # ---------------- 1. 拉取逻辑 ----------------

    def fetch_single_page(self, page):
        """拉取单个页面，自动忽略 /doc 文档说明页喵"""
        if page.name.lower().endswith("/doc"):
            print(f"⏩ [跳过文档页] {page.name} 喵")
            return True

        if page.name.lower().endswith("沙盒") or page.name.lower().endswith("Sandbox"):
            print(f"⏩ [跳过沙盒页] {page.name} 喵")
            return True

        try:
            self._random_delay(0.5, 1.5)
            content = page.text()
            filepath = self._get_filepath_from_page(page)

            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)

            file_hash = self._calculate_file_hash(filepath)
            relative_path = os.path.relpath(filepath, self.output_dir)
            self._update_cache(relative_path, file_hash)

            print(f"✅ [已拉取并缓存] {page.name} -> {relative_path}")
            return True
        except Exception as e:
            print(f"❌ [拉取失败] {page.name}: {e} 喵")
            return False

    def pull_all_templates_and_modules(self, include_templates=True, include_modules=True):
        """批量拉取站内的所有模板(10)和模块(828)，自动剔除 /doc 页喵"""
        raw_pages = []

        if include_templates:
            print("🔍 正在检索线上所有模板 (Namespace: 10)...")
            templates = list(self.site.allpages(namespace=10))
            raw_pages.extend(templates)

        if include_modules:
            print("🔍 正在检索线上所有模块 (Namespace: 828)...")
            modules = list(self.site.allpages(namespace=828))
            raw_pages.extend(modules)

        # 核心过滤：剔除所有 /doc 结尾的文档说明页面
        pages_to_fetch = [p for p in raw_pages if not p.name.lower().endswith("/doc")]
        skipped_doc_count = len(raw_pages) - len(pages_to_fetch)

        print(f"📌 共检索到 {len(raw_pages)} 个页面，已自动过滤 {skipped_doc_count} 个 /doc 文档页，待拉取 {len(pages_to_fetch)} 个页面喵")

        print(f"\n🚀 开始多线程批量拉取到分类目录（并发线程数: {self.max_workers}）...")
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = [executor.submit(self.fetch_single_page, page) for page in pages_to_fetch]
            for future in as_completed(futures):
                future.result()

        print("🎉 批量拉取全部完成喵！")

    # ---------------- 2. 增量推送逻辑 ----------------

    def push_single_file(self, filepath, summary="Vibe Coding 自动化修改推送", force=False):
        """本地哈希校验推送：未修改则跳过请求"""
        if not os.path.isabs(filepath):
            filepath = os.path.join(self.output_dir, filepath)

        if not os.path.exists(filepath):
            print(f"⚠️️ 文件不存在: {filepath}")
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

    def push_all_changed(self, summary="智能增量同步本地修改"):
        """扫描本地 模板(templates) 和 模块(modules) 目录，只自动推送修改过的文件"""
        files_to_check = []
        for root, _, files in os.walk(self.output_dir):
            for file in files:
                if file.endswith((".wikitext", ".lua")) and not file.startswith("."):
                    files_to_check.append(os.path.join(root, file))

        print(f"\n🔍 正在检查 {len(files_to_check)} 个本地文件的修改状态...")
        changed_files = []
        for fp in files_to_check:
            rel = os.path.relpath(fp, self.output_dir).replace("\\", "/")
            if self.cache.get(rel) != self._calculate_file_hash(fp):
                changed_files.append(fp)

        if not changed_files:
            print("✨ 没有检测到任何被修改的文件，本次无需推送喵！")
            return

        print(f"🎯 发现 {len(changed_files)} 个被修改的文件，准备推送...")
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = [executor.submit(self.push_single_file, fp, summary) for fp in changed_files]
            for future in as_completed(futures):
                future.result()

        print("🎉 智能增量推送完成喵！")


# ================= 运行入口 =================
if __name__ == "__main__":
    # 1. 初始化 Site 实例（通过 rookiepy + cloudscraper 绕过防护并拿到登录态）
    site = get_site_instance()

    # 2. 创建同步管理器
    manager = WikiTemplateManager(
        site=site,
        output_dir=SCRIPT_DIR,
        max_workers=3  # 3 线程并发处理
    )

    # -------------------------------------------------------------
    # 模式 A: 首次使用/定期同步：拉取线上全站模板与模块到本地
    # -------------------------------------------------------------
    manager.pull_all_templates_and_modules(include_templates=True, include_modules=True)

    # -------------------------------------------------------------
    # 模式 B: 本地编辑完成后：自动检索修改过的文件并智能推送回 Wiki
    # -------------------------------------------------------------
    # manager.push_all_changed(summary="Vibe Coding 增量更新模板与 Lua 模块喵")
