# modules/measure_card_ceiling.py
"""量出「一次能渲染多少张卡片」的真实上限：解析往返耗时、HTML 体积、是否触发 NewPP 限制。

用已存在的 模板:平衡数据/卡片 重复 N 次来测。只读，不写入页面。
"""

import os
import sys
import time

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import wiki_login  # noqa: E402

ERROR_MARKERS = [
    ("节点数超限", r"node-count limit|Node-count limit exceeded"),
    ("展开深度超限", r"expansion depth|Expansion depth limit"),
    ("展开体积超限", r"post-expand include size|Post-expand include size"),
    ("页面过大", r"exceeds the maximum|page size limit"),
    ("Lua 内存超限", r"not enough memory|out of memory"),
    ("模板循环", r"template loop"),
]


def make_cards(n):
    """生成 n 张卡片（用当前真实数据结构）。"""
    pieces = []
    for i in range(n):
        pieces.append(
            "{{平衡数据/卡片"
            "|模式=5|赛季=16|段位=-255|地图=-255"
            "|角色=星绘"
            "|防守胜率=53.09|进攻胜率=49.12"
            "|防守选取率=57.30|进攻选取率=36.35"
            "|防守KD=0.93|进攻KD=0.93"
            "|防守均伤=239.75|进攻均伤=243.85"
            "|防守表现分=234.86|进攻表现分=220.11"
            "}}"
        )
    return '<div class="gallerygrid">' + "".join(pieces) + "</div>"


def main():
    site = wiki_login()
    print(f"登录态：{site.username}\n")

    for n in (50, 200, 500):
        wikitext = make_cards(n)
        t0 = time.time()
        try:
            resp = site.api("parse", text=wikitext, contentmodel="wikitext",
                            prop="text")
            dt = time.time() - t0
        except Exception as exc:  # noqa: BLE001
            print(f"  n={n:>4}  请求失败: {exc}")
            continue

        if "error" in resp:
            print(f"  n={n:>4}  API 错误: {str(resp['error'].get('info'))[:160]}")
            continue

        html = (resp.get("parse", {}).get("text", {}) or {}).get("*", "")
        hits = [name for name, pat in ERROR_MARKERS
                if __import__("re").search(pat, html, __import__("re").IGNORECASE)]
        cards = html.count("gallerygrid-item")

        status = "✅" if not hits else "❌ " + "、".join(hits)
        print(f"  n={n:>4}  往返 {dt:6.2f}s | HTML {len(html):>9,} 字符 | "
              f"实际卡片 {cards:>4} | {status}")
        if hits:
            import re as _re
            m = _re.search(r".{0,120}(node-count limit|expansion depth|Post-expand).{0,200}",
                           html, _re.IGNORECASE | _re.DOTALL)
            if m:
                print("        片段:", _re.sub(r"<[^>]+>", "", m.group(0))[:260])
    return 0


if __name__ == "__main__":
    sys.exit(main())
