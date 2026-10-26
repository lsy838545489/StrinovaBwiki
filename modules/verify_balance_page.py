# modules/verify_balance_page.py
"""线上验证：让 WIKI 真正解析 模板:平衡数据，检查是否渲染成功、多大、有无报错。

用 action=parse 预览渲染，不写入任何页面。
"""

import os
import re
import sys

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import wiki_login  # noqa: E402

CASES = [
    ("默认（最新赛季·排位爆破·全段位）", "{{平衡数据}}"),
    ("一般爆破", "{{平衡数据|mode=2}}"),
    ("指定赛季与段位", "{{平衡数据|season=11|rank=9}}"),
    ("按回合均伤排序", "{{平衡数据|sort=damageAve}}"),
]

ERROR_PATTERNS = [
    ("Lua 内存超限", r"not enough memory|out of memory|memory limit"),
    ("Lua 执行错误", r"Lua error|Script error|Lua 错误|脚本错误"),
    ("模块未找到", r"module .* not found|模块.*不存在"),
    ("页面过大", r"exceeds the maximum|page size|超过.*大小"),
    ("展开深度超限", r"node-count limit|expansion depth|展开深度"),
    ("表达式错误", r"Expression error|表达式错误"),
]


def parse(site, wikitext):
    """调用 action=parse 拿到渲染 HTML 与用到的模块/模板清单。"""
    return site.api("parse", text=wikitext, contentmodel="wikitext",
                    prop="text|templates|expandtemplates", disablelimitreport=1)


def main():
    site = wiki_login()
    print(f"登录态：{site.username}\n")

    overall_ok = True
    for label, wikitext in CASES:
        try:
            resp = parse(site, wikitext)
        except Exception as exc:  # noqa: BLE001
            print(f"❌ {label}: 解析请求失败 → {exc}")
            overall_ok = False
            continue

        if "error" in resp:
            print(f"❌ {label}: API 返回错误 → {resp['error'].get('info')}")
            overall_ok = False
            continue

        html = resp["parse"]["text"]["*"]
        chars = len(html)
        rows = html.count("klbq-balance-row")
        green = html.count("#2AA52F")
        zeros = html.count(">--<")

        hits = []
        for name, pattern in ERROR_PATTERNS:
            if re.search(pattern, html, re.IGNORECASE):
                hits.append(name)

        status = "✅" if not hits else "⚠️"
        print(f"{status} {label}")
        print(f"     HTML {chars:,} 字符 | 数据行 {rows} | 标绿 {green} | 无数据 {zeros}")
        if hits:
            overall_ok = False
            print(f"     ⚠️ 命中错误特征: {'、'.join(hits)}")
            snippet = re.search(r".{0,200}(Lua error|Script error|not enough memory).{0,300}",
                                html, re.IGNORECASE | re.DOTALL)
            if snippet:
                print(f"     片段: {re.sub(r'<[^>]+>', '', snippet.group(0))[:300]}")

    print("\n" + ("全部用例渲染正常" if overall_ok else "存在异常，见上"))
    return 0 if overall_ok else 1


if __name__ == "__main__":
    sys.exit(main())
