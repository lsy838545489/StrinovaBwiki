# modules/verify_card_view.py
"""线上验证卡片视图：模板解析结果 + JSON 分片可访问性。只读。
"""

import json
import os
import re
import sys
import urllib.parse

_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import wiki_login  # noqa: E402

ERROR_PATTERNS = [
    ("Lua 错误", r"Lua error|Script error|Lua 错误"),
    ("内存超限", r"not enough memory"),
    ("展开超限", r"post-expand include size|node-count limit"),
    ("模块未找到", r"module .* not found"),
]

SHARDS = ["MediaWiki:平衡数据-排位.json", "MediaWiki:平衡数据-一般.json"]


def main():
    site = wiki_login()
    print(f"登录态：{site.username}\n")

    # ---- 1. 模板解析 ----
    resp = site.api("parse", text="{{平衡数据}}", contentmodel="wikitext", prop="text")
    if "error" in resp:
        print("❌ 解析失败:", resp["error"].get("info"))
        return 1
    html = resp["parse"]["text"]["*"]
    print(f"【模板解析】HTML {len(html):,} 字符")

    cards = re.findall(r'data-hero="(\d+)"', html)
    fbtns = re.findall(r'class="[^"]*klbq-balance-fbtn[^"]*"[^>]*data-dim="(\w+)"', html)
    sbtns = re.findall(r'data-key="(\w+)"', html)
    dims = {}
    for m in re.finditer(r'data-dim="(\w+)" data-val="([^"]+)"', html):
        dims.setdefault(m.group(1), []).append(m.group(2))

    checks = [
        ("根容器", 'id="klbq-balance-root"' in html),
        ("默认赛季 18", 'data-season="18"' in html),
        ("默认模式 5", 'data-mode="5"' in html),
        ("默认地图 207", 'data-map="207"' in html),
        ("默认段位 -255", 'data-rank="-255"' in html),
        ("卡片数 = 24", len(cards) == 24),
        ("排序按钮 5 个", len(sbtns) == 5),
        ("模式分片后缀", 'data-shard="排位"' in html),
        # 只要没有「类名 token 形式」的使用即可；CSS 注释里提到该词是无害的
        ("未误用全站筛选类",
         not re.search(r'class="[^"]*\bcardSelectOption\b[^"]*"', html)),
        ("首屏有真实数值", bool(re.search(r'class="s1[^"]*">\d', html))),
    ]
    for label, ok in checks:
        print(f"     {'✅' if ok else '❌'} {label}")
    print(f"     卡片: {len(cards)} 个，前 5: {cards[:5]}")
    for d, vals in dims.items():
        print(f"     筛选 {d:7s} {len(vals):2d} 项: {vals}")
    print(f"     排序键: {sbtns}")

    hits = [name for name, pat in ERROR_PATTERNS if re.search(pat, html, re.IGNORECASE)]
    if hits:
        print(f"     ⚠️ 错误特征: {hits}")

    # ---- 2. JSON 分片可访问性 ----
    print("\n【JSON 分片】")
    art = site.site["articlepath"] if hasattr(site, "site") else "/klbq/$1"
    for title in SHARDS:
        url = art.replace("$1", urllib.parse.quote(title.replace(" ", "_")))
        try:
            resp = site.api("query", prop="revisions", titles=title, rvprop="size|contentmodel")
            pages = resp["query"]["pages"]
            page = list(pages.values())[0]
            if "missing" in page:
                print(f"     ❌ {title} 不存在")
                continue
            rev = page["revisions"][0]
            print(f"     ✅ {title}: {rev['size']:,} 字节, contentmodel={rev.get('contentmodel')}")
        except Exception as exc:  # noqa: BLE001
            print(f"     ❌ {title} 查询失败: {exc}")

    # ---- 3. 直接抓 JSON 内容，确认可被 JSON.parse ----
    import requests
    for title in SHARDS:
        raw_url = f"https://wiki.biligame.com/klbq/index.php?title={urllib.parse.quote(title)}&action=raw"
        try:
            r = requests.get(raw_url, timeout=30, headers={"User-Agent": "Mozilla/5.0"})
            data = json.loads(r.text)
            n = len(data.get("heroes", {}))
            keys = len(data.get("meta", {}).get("keys", {}))
            print(f"     ✅ raw 可解析: {title.split(':')[1]}  heroes={n}  keys={keys}  "
                  f"HTTP {r.status_code}  {len(r.content):,} 字节")
        except Exception as exc:  # noqa: BLE001
            print(f"     ❌ raw 抓取/解析失败 {title}: {type(exc).__name__} {exc}")

    out = r"Z:\Gitee\StrinovaBwiki\.bsk-setup\wiki-cards.html"
    with open(out, "w", encoding="utf-8") as f:
        f.write('<meta charset="utf-8">\n' + html)
    print(f"\n渲染结果已保存: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
