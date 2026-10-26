# modules/measure_render_limits.py
"""测量线上解析的真实开销：耗时、展开节点数、HTML 大小。

确定「数据模块能拆到多大 / 卡片能放多少张」的真实天花板。只读。
"""

import os
import sys
import time

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import wiki_login  # noqa: E402


def find_namespace(site, keyword):
    """按名字找命名空间 ID（Widget/小部件 等）。"""
    info = site.api("query", meta="siteinfo", siprop="namespaces")
    found = {}
    for ns_id, ns in (info.get("query", {}).get("namespaces", {}) or {}).items():
        name = ns.get("*") or ns.get("name") or ""
        if keyword.lower() in name.lower():
            found[int(ns_id)] = name
    return found


def measure(site, wikitext, label):
    """返回 (用时秒, html 长度, 节点数, lua 耗时)。节点数取自解析耗时报告。"""
    t0 = time.time()
    resp = site.api("parse", text=wikitext, contentmodel="wikitext",
                    prop="text|parsetree", disablelimitreport=0)
    dt = time.time() - t0
    parse = resp.get("parse") or {}
    if "error" in resp:
        return dt, 0, None, str(resp["error"].get("info"))[:200]
    html = (parse.get("text") or {}).get("*", "")

    # parsetree 里的节点数（NewPP 限制按 DOM 节点算）
    tree = (parse.get("parsetree") or {}).get("*", "")
    nodes = tree.count("<") if tree else None
    return dt, len(html), nodes, None


def main():
    site = wiki_login()
    print(f"登录态：{site.username}\n")

    for kw in ("Widget", "小部件", "CardSelect"):
        ns = find_namespace(site, kw)
        if ns:
            print(f"命名空间匹配「{kw}」: {ns}")

    ns_widget = find_namespace(site, "Widget") or {}
    if ns_widget:
        ns_id = list(ns_widget)[0]
        print(f"\nWidget 命名空间（{ns_id}）页面：")
        try:
            for page in site.allpages(namespace=ns_id):
                print("   ", page.name)
        except Exception as exc:  # noqa: BLE001
            print("    查询失败:", exc)

    print("\n=== 解析开销测量 ===")
    cases = [
        ("现有表格视图", "{{平衡数据}}"),
        # 用已有模板堆叠来估算「节点/卡片」成本
        ("5 张道具卡片", "{{#invoke:功能道具|道具筛选}}"),
    ]
    for label, wikitext in cases:
        dt, size, nodes, err = measure(site, wikitext, label)
        if err:
            print(f"  {label:16s} 失败: {err}")
            continue
        print(f"  {label:16s} 往返 {dt:5.2f}s | HTML {size:>8,} 字符 | 节点≈{nodes}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
