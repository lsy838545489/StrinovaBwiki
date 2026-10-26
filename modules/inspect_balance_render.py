# modules/inspect_balance_render.py
"""抓取线上真实渲染结果做抽查：空值数量、角色行、与数据源的一致性。只读。
"""

import os
import re
import sys

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import WIKI_ROOT, wiki_login  # noqa: E402


def main():
    site = wiki_login()
    resp = site.api("parse", text="{{平衡数据}}", contentmodel="wikitext",
                    prop="text|templates")
    html = resp["parse"]["text"]["*"]

    out = os.path.join(WIKI_ROOT, ".bsk-setup", "wiki-render.html")
    with open(out, "w", encoding="utf-8") as f:
        f.write('<meta charset="utf-8">\n' + html)
    print(f"已保存渲染结果 → {out}（{len(html):,} 字符）\n")

    # 用到的模板/模块（API 返回结构不完全统一，做兼容取值）
    templates = []
    for item in resp["parse"].get("templates", []):
        title = item.get("title") or item.get("*")
        if title:
            templates.append(title)
    print("渲染中引用的页面：", templates or "(无)")

    # 空值占位统计
    dashes = re.findall(r'<span style="color:#26262666;">--</span>', html)
    print(f"空值单元格（--）数量: {len(dashes)}")

    # 角色行：头像文件名 + 数值
    rows = re.findall(r'<td class="klbq-balance-name".*?</td>', html, re.DOTALL)
    print(f"角色行数: {len(rows)}\n")

    print("前 5 行抽查看板（角色 / 该行前两个数值块）：")
    for row in rows[:5]:
        name = re.search(r"link=([^|\]]+)\]\]", row)
        name = name.group(1) if name else "?"
        cells = re.findall(r'<td class="klbq-balance-pair".*?</td>', html, re.DOTALL)
        nums = re.findall(r'>([\d.]+%?)<', row)
        print(f"  {name:12s} {nums}")

    # 与本地样例对照：绿标数量
    print(f"\n标绿单元格: {html.count('#2AA52F')}")

    # 是否存在报错痕迹
    for pattern in (r"Lua error", r"Script error", r"not enough memory"):
        if re.search(pattern, html, re.IGNORECASE):
            print(f"⚠️ 发现错误特征: {pattern}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
