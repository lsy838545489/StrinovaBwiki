# modules/push_balance_pages.py
"""把平衡数据相关的三个页面推送到 WIKI（按依赖顺序）。

  1. 模块:平衡数据/Data  ← GameOrganizeData/data/BalanceData.lua（数据，最大）
  2. 模块:平衡数据        ← main/模块(modules)/平衡数据.lua
  3. 模板:平衡数据        ← main/模板(templates)/平衡数据.wikitext

只做"新建"：若目标页面已存在且内容不同，默认拒绝覆盖，避免误伤线上内容。
传 --force 才允许覆盖。

用法：
  python -m modules.push_balance_pages            # 检查后推送
  python -m modules.push_balance_pages --dry-run  # 只检查不写
"""

import argparse
import glob
import os
import sys
import time

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import WIKI_ROOT, wiki_login  # noqa: E402

# 分片粒度 = 模式 × 赛季，文件名形如 BalanceCards-排位-16.json
SHARD_GLOB = os.path.join(WIKI_ROOT, "GameOrganizeData", "data", "BalanceCards-*.json")

# 早期版本按模式整体分片（4 MB），现已被按赛季拆分取代，推送时顺手删除
OBSOLETE_TITLES = [
    "MediaWiki:平衡数据-排位.json",
    "MediaWiki:平衡数据-一般.json",
]


def discover_shards():
    pages = []
    for path in sorted(glob.glob(SHARD_GLOB)):
        name = os.path.basename(path)                      # BalanceCards-排位-16.json
        stem = name[len("BalanceCards-"):-len(".json")]    # 排位-16
        pages.append({
            "title": f"MediaWiki:平衡数据-{stem}.json",
            "path": path,
            "summary": f"Bot：更新平衡数据客户端分片（{stem}）",
            "content_model": "json",
            "allow_update": True,
        })
    return pages


PAGES = [
    {
        "title": "模块:平衡数据/Default",
        "path": os.path.join(WIKI_ROOT, "GameOrganizeData", "data", "BalanceDefault.lua"),
        "summary": "Bot：更新平衡数据默认切片（卡片视图首屏）",
        "allow_update": True,
    },
    {
        "title": "Widget:BalanceFilter",
        "path": os.path.join(WIKI_ROOT, "main", "Widget", "BalanceFilter.wikitext"),
        "summary": "Bot：平衡数据卡片筛选 widget",
        "allow_update": True,
    },
    # 注意：卡片模板现在叫「模板:Gallerygrid/BalanceCard」，由 模块:平衡数据 的
    # frame:expandTemplate 展开，线上早已存在、内容也手工维护过，本脚本不再推送它。
    # 本地 main/模板(templates)/平衡数据__卡片.wikitext 是迁移前的旧副本，
    # 线上从未有过「模板:平衡数据/卡片」这一页；先前这里会把它当成新页面创建，
    # 结果是造一个没有任何页面引用的孤儿模板，故删除该条目。
    {
        "title": "模块:平衡数据",
        "path": os.path.join(WIKI_ROOT, "main", "模块(modules)", "平衡数据.lua"),
        "summary": "Bot：平衡数据卡片筛选视图",
        "allow_update": True,
    },
    {
        "title": "模板:平衡数据",
        "path": os.path.join(WIKI_ROOT, "main", "模板(templates)", "平衡数据.wikitext"),
        "summary": "Bot：更新平衡数据模板",
        "allow_update": True,
    },
    {
        "title": "模块:平衡数据/Data",
        "path": os.path.join(WIKI_ROOT, "GameOrganizeData", "data", "BalanceData.lua"),
        "summary": "Bot：更新平衡数据（表格视图保留）",
        "allow_update": True,
    },
] + discover_shards()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="只检查，不写入")
    parser.add_argument("--force", action="store_true", help="允许覆盖已存在页面")
    parser.add_argument("--only", help="只推送标题包含该子串的页面（调试用）")
    args = parser.parse_args()

    site = wiki_login()
    if not site.logged_in:
        print("❌ 未取得登录态，中止（请确认 Firefox 已登录 biligame）")
        return 1
    print(f"✅ 登录态正常：{site.username}\n")

    pages = PAGES
    if args.only:
        pages = [p for p in pages if args.only in p["title"]]
        print(f"（--only {args.only} 过滤后剩 {len(pages)} 个页面）\n")

    failed = 0
    for item in pages:
        title, path = item["title"], item["path"]
        content_model = item.get("content_model")
        if not os.path.exists(path):
            print(f"❌ 本地文件不存在：{path}")
            failed += 1
            continue

        with open(path, "r", encoding="utf-8") as f:
            content = f.read().lstrip("\ufeff")
        size = len(content.encode("utf-8"))

        page = site.pages[title]
        exists = page.exists
        if exists and not args.force:
            current = page.text()
            if current.strip() == content.strip():
                print(f"⚡ [跳过] {title} 线上内容一致")
                continue
            # 由脚本托管的页面允许覆盖；其余页面必须显式 --force
            if not item.get("allow_update"):
                print(f"⛔ [拒绝覆盖] {title} 线上内容不同"
                      f"（{len(current):,} / {len(content):,} 字符），未声明 allow_update")
                failed += 1
                continue
            delta = len(content) - len(current)
            print(f"♻️  [更新] {title}：{len(current):,} → {len(content):,} 字符"
                  f"（{'+' if delta >= 0 else ''}{delta:,}）")

        if args.dry_run:
            print(f"🔍 [dry-run] 将写入 {title}，{size:,} 字节"
                  f"（{'覆盖' if exists else '新建'}）"
                  f"{'，content_model=' + content_model if content_model else ''}")
            continue

        try:
            if content_model and (not exists or page.contentmodel != content_model):
                page.save(content, summary=item["summary"], bot=True,
                          contentmodel=content_model)
            else:
                page.save(content, summary=item["summary"], bot=True)
            print(f"🚀 [已推送] {title}（{size:,} 字节）")
        except Exception as exc:  # noqa: BLE001
            print(f"💥 [推送失败] {title}: {type(exc).__name__} {exc}")
            failed += 1
        time.sleep(1.5)

    print("\n完成" + ("（有失败项）" if failed else "，全部成功"))

    # 清理被取代的旧分片页（避免留下 4 MB 的孤儿页面）
    if not args.dry_run:
        for title in OBSOLETE_TITLES:
            page = site.pages[title]
            if page.exists:
                try:
                    page.delete(reason="已被按赛季拆分的分片取代")
                    print(f"🧹 [已删除] {title}")
                except Exception as exc:  # noqa: BLE001
                    print(f"⚠️ [删除失败] {title}: {exc}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
