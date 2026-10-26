# modules/check_balance_pages.py
"""只读检查：平衡数据相关目标页面在 WIKI 上是否存在、当前多大。不做任何写入。

用法：python -m modules.check_balance_pages
"""

import os
import sys

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import wiki_login  # noqa: E402

TARGETS = [
    "模块:平衡数据/Data",
    "模块:平衡数据",
    "模板:平衡数据",
]


def main():
    site = wiki_login()
    if not site.logged_in:
        print("⚠️ 未取得登录态（rookiepy 未从 Firefox 读到 biligame cookie）")
    else:
        print(f"✅ 登录态正常：{site.username or '(已登录)'}")
    print()

    for title in TARGETS:
        page = site.pages[title]
        try:
            exists = page.exists
        except Exception as exc:  # noqa: BLE001
            print(f"  {title:20s} 查询失败: {exc}")
            continue
        if exists:
            text = page.text()
            print(f"  {title:20s} 已存在，{len(text):,} 字符"
                  f"（约 {len(text.encode('utf-8')):,} 字节）")
            print(f"      首行: {text.strip().splitlines()[0][:80] if text.strip() else '(空)'}")
        else:
            print(f"  {title:20s} 不存在（将新建）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
