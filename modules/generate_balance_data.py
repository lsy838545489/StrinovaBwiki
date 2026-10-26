# modules/generate_balance_data.py
"""抓取卡拉彼丘官网「平衡数据」（角色胜率）并推送至 WIKI。

数据来源（公开接口，无需登录）：
  1. GET  /api/pages/KLBQ_BALANCE/index   —— 筛选维度的可选值（模式/地图/段位/赛季）
  2. POST /api/common/ide                 —— 各筛选组合下的角色数值

产出：
  GameOrganizeData/data/BalanceData.json  全量数据（供比对/回溯）
  GameOrganizeData/data/BalanceData.lua   数据模块正文，推送到 模块:平衡数据/Data

接口注意事项（均为实测结论，勿改）：
  * /api/common/ide 只接受 POST + Content-Type: application/json；
    GET 该路径返回 200 的 SPA HTML 壳，不进业务逻辑。
  * 业务状态是双层的：顶层 ret/iRet 与 jData.iRet 各一份，两层都要校验。
  * 响应体 data2 在 season2 == "0" 时是空数组 []，非 0 时是「以角色 id 为键的对象」
    而不是数组；本脚本第一期固定 season2="0"，故不涉及该分支。
  * data2.max 恒为全 0 占位值，不可信；data1.max 才是真实极值，且随筛选组合变化，
    必须随组合一起存，严禁跨组合复用。
  * 部分「段位 × 模式 × 赛季」组合官方返回全 0 占位行（例如排位爆破的「未定级」），
    这类快照按空处理并记入 meta.combos，避免下次误判为抓取失败。
"""

import json
import os
import sys
import time

# 支持「直接运行本文件」与「经 main.py 调用」两种方式
_PKG_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _PKG_ROOT not in sys.path:
    sys.path.insert(0, _PKG_ROOT)

from utils.common import (  # noqa: E402 - 必须在 sys.path 处理后导入
    id_to_Role_name,
    save_data_file,
    format_lua_table,
    upload_wiki_data,
)

# ================= 接口常量 =================

BASE_URL = "https://klbq-prod-www.idreamsky.com"
IDE_URL = BASE_URL + "/api/common/ide"
SETTING_URL = BASE_URL + "/api/pages/KLBQ_BALANCE/index"

# 固定查询标识：iChartId / iSubChartId / sIdeToken 由服务端下发，必须原样携带
IDE_TOKEN = {"iChartId": "338985", "iSubChartId": "338985", "sIdeToken": "b7FM3m"}

HEADERS = {
    "Content-Type": "application/json",
    "Origin": "https://klbq.idreamsky.com",
    "Referer": "https://klbq.idreamsky.com/",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
    ),
}

# 纳入快照的数值字段（与官网表格列一一对应）
FIELDS = ("winRate", "selectRate", "kd", "damageAve", "score")

# 官网 setting 只下发 11–18 赛季，但后端 chart（338985）至今仍返回 3–10 赛季的数据，
# 官方页面只是不再把入口列出来。老站 klbq.qq.com/web202305/balance-date.html 打的是
# 同一个 chart（其 token 51eda7 经 gmi_act.desc.js 的 alias 表解析后同样是 338985），
# 所以「从老站还能挖到更早赛季」是错觉：不把赛季清单补出来，这批数据永远抓不到。
# 名称取自 GameSourceDataCN/PaperMan/CSV/BattlePassSeason.json（形如 S<N>.<名称>）。
# 实测 season1=1 只有 1/31 行非零、season1=2 与 19 以后全 0，故只补 3–10。
EXTRA_SEASONS = (
    ("3", "暮光幻蝶"), ("4", "日珥鸣火"), ("5", "纵弦震音"), ("6", "虚像艺匠"),
    ("7", "绯息醒世"), ("8", "蚀刻迷局"), ("9", "隙间重构"), ("10", "敕魂命途"),
)
# 需要严格按 setting 抓取（不补历史赛季）时置 1
NO_EXTRA_SEASONS = os.environ.get("BALANCE_NO_EXTRA_SEASONS", "") not in ("", "0", "false", "False")

# 第一期固定维度：全地图 + 不对比赛季（见 §接口注意事项）
FIXED_MAP = "-255"
FIXED_SEASON2 = "0"

WIKI_PAGE_TITLE = "模块:平衡数据/Data"
LOCAL_LUA_FILENAME = "BalanceData.lua"

# 抓取节流与重试
SLEEP_BETWEEN = 0.85
MAX_RETRY = 3
RETRY_BACKOFF = 2.0

# 本地调试开关（环境变量）
#   BALANCE_LIMIT=4        只抓前 N 个组合，用于快速验证体积与结构
#   BALANCE_SKIP_UPLOAD=1  只落盘、不推送 WIKI
#   BALANCE_CACHE_DIR=...  响应缓存目录：命中即不发请求（调试时免于反复打接口）
#   BALANCE_OUT_DIR=...    覆盖落盘目录（默认 GameOrganizeData/data）
LIMIT = int(os.environ.get("BALANCE_LIMIT", "0") or 0)
SKIP_UPLOAD = os.environ.get("BALANCE_SKIP_UPLOAD", "") not in ("", "0", "false", "False")
CACHE_DIR = os.environ.get("BALANCE_CACHE_DIR", "").strip()
OUT_DIR = os.environ.get("BALANCE_OUT_DIR", "").strip()


def _requests():
    """延迟导入并给出可读的环境错误提示。"""
    try:
        import requests
    except ImportError as exc:  # pragma: no cover
        raise RuntimeError(
            "缺少 requests，请使用装了依赖的 Python 环境运行"
            "（例：G:\\conda-envs\\wiki\\python.exe）"
        ) from exc
    return requests


def _check_status(payload):
    """校验双层业务状态（顶层 + jData），返回 data1 字典。"""
    if payload.get("ret") != 0 or payload.get("iRet") != 0:
        raise RuntimeError(f"接口业务失败: {payload.get('sMsg')!r} (ret={payload.get('ret')})")
    jdata = payload.get("jData") or {}
    if str(jdata.get("iRet", "0")) != "0":
        raise RuntimeError(f"jData 业务失败: {jdata.get('sMsg')!r} (iRet={jdata.get('iRet')})")
    data1 = jdata.get("data1") or {}
    if not isinstance(data1, dict):
        raise RuntimeError(f"data1 结构异常: {type(data1).__name__}")
    return data1


def fetch_setting():
    """取筛选维度可选值，返回 {mode, map, rank, season} 的 code/name 列表。"""
    requests = _requests()
    resp = requests.get(SETTING_URL, headers=HEADERS, timeout=20)
    resp.raise_for_status()
    value = (resp.json().get("data") or {}).get("value") or {}
    setting = value.get("setting") or {}

    def expand(key):
        out = []
        for item in setting.get(key) or []:
            # content 是被二次转义的 JSON 字符串，需再解一层
            content = item.get("content")
            if isinstance(content, str):
                try:
                    content = json.loads(content)
                except json.JSONDecodeError:
                    continue
            if isinstance(content, dict) and content.get("code"):
                out.append({"code": str(content["code"]), "name": content.get("name", "")})
        return out

    dims = {k: expand(k) for k in ("mode", "map", "rank", "season")}
    for k, v in dims.items():
        if not v:
            raise RuntimeError(f"筛选维度 {k} 为空，接口结构可能已变更")

    # 官网不再下发的历史赛季在这里补回（原因见 EXTRA_SEASONS 的注释）
    if not NO_EXTRA_SEASONS:
        by_code = {s["code"]: s for s in dims["season"]}
        added = []
        for code, name in EXTRA_SEASONS:
            if code not in by_code:
                by_code[code] = {"code": code, "name": name}
                added.append(f'{code}({name})')
        if added:
            dims["season"] = sorted(by_code.values(), key=lambda s: int(s["code"]))
            print(f"ℹ️ 已补回 setting 未下发的历史赛季：{'、'.join(added)}"
                  f"（现共 {len(dims['season'])} 个赛季）")
    return dims


def cache_key(body):
    """缓存的参数指纹。fetch_ide 与 fetch_all_combos 必须共用同一个键，
    否则 fetch_all_combos 的「命中即跳过」永远不成立，已缓存的组合仍会白等 SLEEP_BETWEEN。"""
    return (f"{body['season1']}_{body['mode']}_{'_'.join(body['rank'])}_"
            f"{body['map']}_{body['season2']}.json")


def fetch_ide(body):
    """POST 单个组合，返回 (data1, meta)，meta 含 sAmsSerial 与响应日期用于定版。

    设置 BALANCE_CACHE_DIR 后按参数指纹读写本地 JSON 缓存，命中即不发请求。
    """
    requests = _requests()
    cache_path = None
    if CACHE_DIR:
        os.makedirs(CACHE_DIR, exist_ok=True)
        cache_path = os.path.join(CACHE_DIR, cache_key(body))
        if os.path.exists(cache_path):
            with open(cache_path, "r", encoding="utf-8") as f:
                cached = json.load(f)
            return _check_status(cached), {
                "serial": cached.get("sAmsSerial", ""),
                "date": cached.get("_date", ""),
                "fromCache": True,
            }

    last_err = None
    for attempt in range(1, MAX_RETRY + 1):
        try:
            resp = requests.post(IDE_URL, headers=HEADERS, json=body, timeout=20)
            resp.raise_for_status()
            payload = resp.json()
            data1 = _check_status(payload)
            meta = {
                "serial": payload.get("sAmsSerial", ""),
                "date": resp.headers.get("date", ""),
            }
            if cache_path:
                payload["_date"] = meta["date"]
                with open(cache_path, "w", encoding="utf-8") as f:
                    json.dump(payload, f, ensure_ascii=False)
            return data1, meta
        except Exception as exc:  # noqa: BLE001 - 网络/结构错误统一重试
            last_err = exc
            if attempt < MAX_RETRY:
                time.sleep(RETRY_BACKOFF * attempt)
    raise RuntimeError(f"抓取失败（重试 {MAX_RETRY} 次）: {body} -> {last_err}")


def _is_zero_row(row):
    """五项指标全 0 视为占位行（例如 id=126 诺诺，或整段位无数据时的占位）。"""
    for field in FIELDS:
        try:
            if float(row.get(field) or 0) != 0:
                return False
        except (TypeError, ValueError):
            return False
    return True


def _build_side(rows):
    """把接口的行数组转成 {角色码: 指标} 字典，丢弃占位行与冗余字段。"""
    out = {}
    for row in rows or []:
        if _is_zero_row(row):
            continue
        hero_id = str(row.get("id") or "")
        if not hero_id:
            continue
        out[hero_id] = {field: row.get(field) for field in FIELDS}
    return out


def _build_max(side_max):
    """data1.max 是真实极值，原样保留（缺失字段补 None 由 save 层过滤）。"""
    out = {}
    for side in ("side1", "side2"):
        value = (side_max or {}).get(side) or {}
        out[side] = {field: value.get(field) for field in FIELDS}
    return out


def export_balance_data(limit=None, skip_upload=None, verbose=True):
    """主流程：抓取 → 组装 → 落盘 → 推送。返回统计信息字典。"""
    limit = LIMIT if limit is None else limit
    skip_upload = SKIP_UPLOAD if skip_upload is None else skip_upload

    dims = fetch_setting()
    modes = dims["mode"]
    ranks = dims["rank"] + [{"code": "-255", "name": "全选"}]
    seasons = dims["season"]

    combos = [
        (season["code"], mode["code"], rank["code"])
        for season in seasons
        for mode in modes
        for rank in ranks
    ]
    if limit:
        combos = combos[:limit]

    print(f"开始抓取平衡数据：{len(combos)} 个组合"
          f"（模式 {len(modes)} × 段位 {len(ranks)} × 赛季 {len(seasons)}）")
    if limit:
        print(f"⚠️ 已启用 BALANCE_LIMIT={limit}，仅抓取前 {len(combos)} 个组合")

    body_tree = {}
    combos_meta = []
    hero_ids = {}
    serial, resp_date = "", ""
    ok = zero = 0

    for index, (season, mode, rank) in enumerate(combos, start=1):
        body = dict(IDE_TOKEN, mode=mode, map=FIXED_MAP, rank=[rank],
                    season1=season, season2=FIXED_SEASON2)
        data1, meta = fetch_ide(body)
        serial = meta["serial"] or serial
        resp_date = meta["date"] or resp_date

        side1 = _build_side(data1.get("side1"))
        side2 = _build_side(data1.get("side2"))
        for source in (data1.get("side1") or [], data1.get("side2") or []):
            for row in source:
                hero_ids[str(row.get("id"))] = row.get("heroName", "")

        if side1 or side2:
            body_tree.setdefault(season, {}).setdefault(mode, {}).setdefault(rank, {})[FIXED_MAP] = {
                "side1": side1,
                "side2": side2,
                "max": _build_max(data1.get("max")),
            }
            ok += 1
        else:
            zero += 1

        combos_meta.append({"season": season, "mode": mode, "rank": rank,
                            "map": FIXED_MAP, "season2": FIXED_SEASON2,
                            "hasData": bool(side1 or side2)})

        if verbose and (index % 20 == 0 or index == len(combos)):
            print(f"  … {index}/{len(combos)}（有效 {ok}，空档 {zero}）", flush=True)
        if index < len(combos):
            time.sleep(SLEEP_BETWEEN)

    # 角色码 → 全名（只写一次；接口的 heroName 是简称，不一致时以 id_to_Role_name 为准）
    roles = {}
    unmapped = []
    for hero_id in sorted(hero_ids, key=lambda x: int(x) if str(x).isdigit() else 0):
        code = int(hero_id) if str(hero_id).isdigit() else hero_id
        full_name = id_to_Role_name.get(code)
        if not full_name:
            unmapped.append(hero_id)
        roles[hero_id] = full_name or hero_ids[hero_id] or str(hero_id)

    if unmapped:
        print(f"⚠️ 以下角色码在 id_to_Role_name 中缺失，暂用接口简称：{unmapped}")
    else:
        print(f"角色名映射：{len(roles)} 个角色码全部命中 id_to_Role_name 全名")

    data = {
        "meta": {
            "updateTime": time.strftime("%Y-%m-%d %H:%M:%S"),
            "serial": serial,
            "serverDate": resp_date,
            "source": IDE_URL,
            "fixed": {"map": FIXED_MAP, "season2": FIXED_SEASON2},
            "seasons": seasons,
            "modes": modes,
            "ranks": ranks,
            "roles": roles,
            "combos": combos_meta,
        },
        "data": body_tree,
    }

    if OUT_DIR:
        # 调试/离线模式：只写指定目录，不触碰 GameOrganizeData 的备份逻辑
        os.makedirs(OUT_DIR, exist_ok=True)
        with open(os.path.join(OUT_DIR, "BalanceData.json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
        lua_path = os.path.join(OUT_DIR, LOCAL_LUA_FILENAME)
        with open(lua_path, "w", encoding="utf-8") as f:
            f.write(format_lua_table(data))
        print(f"（BALANCE_OUT_DIR 生效，已写入 {OUT_DIR}）")
    else:
        save_data_file("BalanceData", data, fileType="json")
        save_data_file("BalanceData", format_lua_table(data), fileType="lua")
        lua_path = os.path.normpath(os.path.join(
            os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")),
            "..", "GameOrganizeData", "data", LOCAL_LUA_FILENAME,
        ))

    size = os.path.getsize(lua_path) if os.path.exists(lua_path) else 0
    print(f"数据模块大小：{size:,} B（{size / 1024:.0f} KiB）→ {lua_path}")

    if skip_upload:
        print("⏭ 已设置 BALANCE_SKIP_UPLOAD，跳过推送 WIKI")
    else:
        upload_wiki_data(WIKI_PAGE_TITLE, lua_path)
        print(f"✅ 已推送 {WIKI_PAGE_TITLE}")

    summary = {"combos": len(combos), "withData": ok, "empty": zero,
               "bytes": size, "roles": len(roles)}
    print(f"完成：{summary}")
    return summary


def fetch_all_combos():
    """先把四维（赛季×模式×地图×段位）全部响应抓进缓存，供后续快速重算。

    这是长时间任务（1760 次请求，约 25 分钟）。缓存命中即跳过。
    """
    dims = fetch_setting()
    maps = [{"code": "-255", "name": "全选"}] + dims["map"]
    ranks = [{"code": "-255", "name": "全选"}] + dims["rank"]
    combos = [(s["code"], m["code"], mp["code"], r["code"])
              for s in dims["season"] for m in dims["mode"]
              for mp in maps for r in ranks]

    total = len(combos)
    print(f"开始抓取 {total} 个组合并写入缓存：{CACHE_DIR or '(未设置 BALANCE_CACHE_DIR)'}")
    if not CACHE_DIR:
        print("⚠️ 未设置 BALANCE_CACHE_DIR，本次抓取不会有缓存收益")
    t0 = time.time()
    ok = cached = failed = 0
    for i, (season, mode, mp, rank) in enumerate(combos, 1):
        path = os.path.join(CACHE_DIR, cache_key(
            dict(IDE_TOKEN, mode=mode, map=mp, rank=[rank],
                 season1=season, season2=FIXED_SEASON2))) if CACHE_DIR else None
        if path and os.path.exists(path):
            cached += 1
            continue
        body = dict(IDE_TOKEN, mode=mode, map=mp, rank=[rank],
                    season1=season, season2=FIXED_SEASON2)
        try:
            fetch_ide(body)
            ok += 1
        except Exception as exc:  # noqa: BLE001
            failed += 1
            print(f"  ❌ {season}/{mode}/{mp}/{rank}: {exc}")
        if i % 100 == 0 or i == total:
            speed = i / max(time.time() - t0, 1)
            eta = (total - i) / max(speed, 0.001) / 60
            print(f"  … {i}/{total}（新增 {ok}，缓存命中 {cached}，失败 {failed}）"
                  f"  ETA {eta:.1f} 分钟", flush=True)
        if path:
            time.sleep(SLEEP_BETWEEN)
    print(f"抓取完成：新增 {ok}，缓存命中 {cached}，失败 {failed}，"
          f"用时 {(time.time() - t0) / 60:.1f} 分钟")
    return {"new": ok, "cached": cached, "failed": failed}


# 内置职业兜底（与官网页面配置的 position_code 推导结果一致，24/24 核对过）
ROLE_JOBS = {
    "101": "守护", "105": "守护", "107": "控场", "108": "守护", "109": "控场",
    "110": "决斗", "112": "决斗", "115": "决斗", "119": "决斗", "120": "支援",
    "121": "控场", "122": "决斗", "123": "守护", "124": "支援", "125": "决斗",
    "126": "先锋", "128": "先锋", "130": "决斗", "131": "控场", "132": "决斗",
    "133": "控场", "137": "先锋", "146": "支援", "205": "先锋",
}


def fetch_role_jobs():
    """从 /api/pages/KLBQ_BALANCE/index 的 role_list 推导「角色码 -> 职业」。

    注意：/api/common/ide 返回的 job 字段实测恒为空字符串，不能用。
    """
    requests = _requests()
    resp = requests.get(SETTING_URL, headers=HEADERS, timeout=20)
    resp.raise_for_status()
    value = (resp.json().get("data") or {}).get("value") or {}
    role_list = value.get("role_list") or {}

    positions = {}
    for item in role_list.get("position") or []:
        content = item.get("content")
        if isinstance(content, str):
            try:
                content = json.loads(content)
            except json.JSONDecodeError:
                continue
        if isinstance(content, dict):
            positions[str(content.get("position_code"))] = content.get("position_name", "")

    jobs = {}
    for item in role_list.get("role_list") or []:
        content = item.get("content")
        if isinstance(content, str):
            try:
                content = json.loads(content)
            except json.JSONDecodeError:
                continue
        if isinstance(content, dict) and content.get("character_code"):
            code = str(content["character_code"])
            jobs[code] = positions.get(str(content.get("position_code")), "") or ROLE_JOBS.get(code, "")
    return jobs




# 分片页后缀：与 模块:平衡数据 的 SHARD_SUFFIX、Widget:BalanceFilter 的 data-shard 必须一致
SHARD_SUFFIX = {"5": "排位", "2": "一般"}

# 客户端 JSON 页面标题前缀（Widget 会拼成 <前缀>-<后缀>.json）
SHARD_PAGE_PREFIX = "MediaWiki:平衡数据"

DEFAULT_MAP = "-255"     # 全选（全地图）
DEFAULT_MODE = "5"       # 排位爆破
DEFAULT_RANK = "-255"    # 全段位


def _dims_4d(dims):
    """把 setting 展开成四维选项列表（地图/段位都带「全选」）。"""
    return {
        "season": dims["season"],
        "mode": dims["mode"],
        "map": [{"code": "-255", "name": "全选"}] + dims["map"],
        "rank": [{"code": "-255", "name": "全选"}] + dims["rank"],
    }


def _load_snapshot(season, mode, map_code, rank):
    """取一个切片（走缓存），返回 (side1, side2, hero_names) 或 None。"""
    body = dict(IDE_TOKEN, mode=mode, map=map_code, rank=[rank],
                season1=season, season2=FIXED_SEASON2)
    data1, _ = fetch_ide(body)
    side1 = _build_side(data1.get("side1"))
    side2 = _build_side(data1.get("side2"))
    names = {}
    for source in (data1.get("side1") or [], data1.get("side2") or []):
        for row in source:
            names[str(row.get("id"))] = row.get("heroName", "")
    return side1, side2, names


def export_card_view(dry_run=False):
    """产出卡片筛选视图需要的两个文件：

      1. MediaWiki:平衡数据-<后缀>.json  每个模式一份紧凑分片，供 Widget 按需加载
      2. 模块:平衡数据/Default           默认切片（很小），供服务端首屏直填数值
    """
    dims = _dims_4d(fetch_setting())
    seasons = dims["season"]
    modes = dims["mode"]
    maps = dims["map"]
    ranks = dims["rank"]

    # 默认赛季 = code 最大（官方数组顺序不可靠：17/18 是后追加的）
    default_season = max(seasons, key=lambda s: int(s["code"]))["code"]

    total = len(seasons) * len(modes) * len(maps) * len(ranks)
    print(f"卡片视图导出：{total} 个切片"
          f"（赛季 {len(seasons)} × 模式 {len(modes)} × 地图 {len(maps)} × 段位 {len(ranks)}）"
          f"｜默认 = 赛季{default_season} 模式{DEFAULT_MODE} 地图{DEFAULT_MAP} 段位{DEFAULT_RANK}")

    # 维度可用性：某维度某取值在任意组合下出现过有数据的切片
    usable = {k: {} for k in ("season", "mode", "map", "rank")}
    map_names = {m["code"]: m["name"] for m in maps}
    rank_names = {r["code"]: r["name"] for r in ranks}
    season_names = {s["code"]: s["name"] for s in seasons}
    mode_names = {m["code"]: m["name"] for m in modes}

    roles, jobs, all_ids = {}, {}, set()
    default_slice = None
    shards = {}
    empty_slices = 0
    t0 = time.time()

    for mode in modes:
        mcode = mode["code"]
        shard = {
            "mode": mcode,
            "modeName": mode["name"],
            "seasons": [s["code"] for s in seasons],
            "maps": [m["code"] for m in maps],
            "ranks": [r["code"] for r in ranks],
            "keys": {},
            "heroes": {},
        }
        idx = 0
        for season in seasons:
            scode = season["code"]
            for mp in maps:
                mpcode = mp["code"]
                for rk in ranks:
                    rkcode = rk["code"]
                    side1, side2, names = _load_snapshot(scode, mcode, mpcode, rkcode)
                    if not side1 and not side2:
                        empty_slices += 1
                        continue

                    ids = set(side1) | set(side2)
                    all_ids |= ids
                    for hid in ids:
                        roles.setdefault(hid, "")
                        jobs.setdefault(hid, "")
                    for hid, nm in names.items():
                        if not roles.get(hid):
                            roles[hid] = nm

                    key = f"{scode}|{mpcode}|{rkcode}"
                    shard["keys"][key] = idx
                    for hid in ids:
                        entry = {}
                        if hid in side1:
                            entry["s1"] = [side1[hid][f] for f in FIELDS]
                        if hid in side2:
                            entry["s2"] = [side2[hid][f] for f in FIELDS]
                        hero = shard["heroes"].setdefault(hid, {"v": {}})
                        hero["v"][str(idx)] = entry
                    idx += 1

                    # 维度可用性 & 默认切片
                    usable["season"][scode] = True
                    usable["mode"][mcode] = True
                    usable["map"][mpcode] = True
                    usable["rank"][rkcode] = True
                    if (scode == default_season and mcode == DEFAULT_MODE
                            and mpcode == DEFAULT_MAP and rkcode == DEFAULT_RANK):
                        default_slice = {hid: {"s1": [side1[hid][f] for f in FIELDS]}
                                         if hid in side1 else {}
                                         for hid in ids}
                        for hid in ids:
                            if hid in side2:
                                default_slice[hid]["s2"] = [side2[hid][f] for f in FIELDS]

        shard["_count"] = idx
        shards[mcode] = shard
        print(f"  模式 {mcode}({mode['name']})：{idx} 个有效切片，"
              f"{len(shard['heroes'])} 个角色", flush=True)

    # 用 utils.common 的全名覆盖官方简称
    for hid in list(roles):
        code = int(hid) if str(hid).isdigit() else hid
        full = id_to_Role_name.get(code)
        if full:
            roles[hid] = full

    # 职业：官方接口的 job 字段恒为空，改用 role_list 的 position 推导（内置表兜底）
    try:
        api_jobs = fetch_role_jobs()
    except Exception as exc:  # noqa: BLE001
        print(f"  ⚠️ 职业推导失败，改用内置映射：{exc}")
        api_jobs = {}
    for hid in list(jobs):
        jobs[hid] = api_jobs.get(hid) or ROLE_JOBS.get(hid, "")
    print(f"  职业映射：{len([v for v in jobs.values() if v])}/{len(jobs)} 个角色有职业")

    if default_slice is None:
        raise RuntimeError(f"默认切片缺失：{default_season}/{DEFAULT_MODE}/{DEFAULT_MAP}/{DEFAULT_RANK}")

    common_meta = {
        "updateTime": time.strftime("%Y-%m-%d %H:%M:%S"),
        "source": IDE_URL,
        "seasons": [{"code": c, "name": season_names[c]} for c in season_names],
        "modes": [{"code": c, "name": mode_names[c]} for c in mode_names],
        "maps": [{"code": c, "name": map_names[c]} for c in map_names],
        "ranks": [{"code": c, "name": rank_names[c]} for c in rank_names],
        "roles": roles,
        "jobs": jobs,
        "heroes": sorted(all_ids, key=lambda x: int(x) if str(x).isdigit() else 0),
        "usable": {k: sorted(v.keys()) for k, v in usable.items()},
        "default": {"season": default_season, "mode": DEFAULT_MODE,
                    "map": DEFAULT_MAP, "rank": DEFAULT_RANK},
    }

    # ---- 落盘：每个「模式 × 赛季」一个 JSON 分片 ----
    # 不按模式整体分片：那样单文件 4 MB，浏览器拉取/解析都很吃力（实测）。
    out_dir = OUT_DIR or os.path.normpath(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", "GameOrganizeData", "data"))
    os.makedirs(out_dir, exist_ok=True)

    # 把原来的按模式分片拆成按「模式 × 赛季」
    season_of_key = {}
    for mcode, shard in shards.items():
        for key in shard["keys"]:
            season_of_key[key] = key.split("|")[0]

    shard_report = []
    for mcode, shard in shards.items():
        suffix = SHARD_SUFFIX.get(mcode, mcode)
        per_season = {}
        for key in shard["keys"]:
            per_season.setdefault(season_of_key[key], []).append(key)

        for season, keys in per_season.items():
            # 直接从「键」重建嵌套：heroes[id][地图][段位] = {s1,s2}
            # 故意不再用「键 -> 下标」的间接索引：客户端取数时那层换算容易与
            # 服务端的键格式不一致（实测在浏览器里全部取空），扁平嵌套没有这个风险。
            # 注意 shard["keys"] 是「键 -> 下标」，而 hero["v"] 的键就是那个下标。
            heroes_out = {}
            for hid, entry in shard["heroes"].items():
                by_map = {}
                for key in keys:
                    slice_ = (entry.get("v") or {}).get(str(shard["keys"][key]))
                    if not slice_:
                        continue
                    _, map_code, rank_code = key.split("|")
                    by_map.setdefault(map_code, {})[rank_code] = slice_
                if by_map:
                    heroes_out[hid] = by_map

            # 自校验：不允许静默产出空数据（重构时踩过一次，分片从 1.6 MB 掉到 42 KB）
            if not heroes_out:
                raise RuntimeError(
                    f"分片 {suffix}-{season} 角色数据为空，"
                    f"检查 shard['heroes'][*]['v'] 的键格式是否与 {keys[0]!r} 一致")

            meta_out = dict(common_meta)
            meta_out["mode"] = mcode
            meta_out["modeName"] = shard["modeName"]
            meta_out["season"] = season
            meta_out["mapsOfSeason"] = sorted({k.split("|")[1] for k in keys})
            meta_out["ranksOfSeason"] = sorted({k.split("|")[2] for k in keys})
            meta_out["sliceCount"] = len(keys)
            payload = {"meta": meta_out, "heroes": heroes_out}
            text = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
            fname = f"BalanceCards-{suffix}-{season}.json"
            if not dry_run:
                with open(os.path.join(out_dir, fname), "w", encoding="utf-8") as f:
                    f.write(text)
            shard_report.append((fname, len(text.encode("utf-8")), len(keys)))

    total_bytes = sum(s for _, s, _ in shard_report)
    print(f"\n  共 {len(shard_report)} 个分片，合计 {total_bytes / 1024:.0f} KiB，"
          f"单分片 {min(s for _, s, _ in shard_report) / 1024:.0f}"
          f"–{max(s for _, s, _ in shard_report) / 1024:.0f} KiB")

    # ---- 默认切片 Lua（服务端首屏） ----
    default_data = {"meta": common_meta, "slice": default_slice}
    lua_text = format_lua_table(default_data)
    lua_path = os.path.join(out_dir, "BalanceDefault.lua")
    if not dry_run:
        with open(lua_path, "w", encoding="utf-8") as f:
            f.write(lua_text)

    print(f"\n汇总：空切片 {empty_slices}，角色 {len(roles)}，"
          f"用时 {(time.time() - t0) / 60:.1f} 分钟")
    for fname, size, count in sorted(shard_report):
        print(f"  {fname:36s} {size / 1024:7.0f} KiB  {count:>3} 切片")
    print(f"  {'BalanceDefault.lua':32s} {len(lua_text.encode('utf-8')) / 1024:7.0f} KiB")
    return shard_report


if __name__ == "__main__":
    if os.environ.get("BALANCE_FETCH_ALL"):
        fetch_all_combos()
    else:
        # 默认直接导出卡片视图需要的 Default 模块与 JSON 分片
        export_card_view()
