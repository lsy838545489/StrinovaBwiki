import json
import os
import re
from pathlib import Path
import pandas as pd

# ========== 路径配置（自动定位为当前脚本所在的根目录） ==========
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# 工作区根目录（即 ExportScripts 的上一级），各分支以同级文件夹并列存放
WIKI_ROOT = os.path.abspath(os.path.join(BASE_DIR, os.pardir))
# 源数据目录：国服（CN）解包数据，目录结构与本脚本所需一致
Files_DIR = os.path.join(WIKI_ROOT, "GameSourceDataCN", "PaperMan")
WEAPON_ROOT = os.path.join(Files_DIR, "CyWeapons")
CSV_DIR = os.path.join(Files_DIR, "CSV")
GAME_MODE_CURVE_FILE = os.path.join(Files_DIR, "CyAbilities", "Shared", "CurveTable", "CT_GameModeWeaponAttribute.json")
# 整理数据目录：与 utils/common.py 的 DATA_ROOT 保持一致，统一落在 GameOrganizeData
DATA_ROOT = os.path.join(WIKI_ROOT, "GameOrganizeData", "data")
DATA_OLD_ROOT = os.path.join(WIKI_ROOT, "GameOrganizeData", "data_old")
# =========================================================

def compare_json_data(old_data, new_data, id_key="ID"):
    if old_data is None:
        return new_data

    if isinstance(new_data, dict):
        if not isinstance(old_data, dict):
            return new_data

        diff = {}
        top_level_keys = {"DirectoryName", "ID", "WeaponName", "WeaponType"}
        old_key_map = {str(k): v for k, v in old_data.items()}

        for key, val in new_data.items():
            if key in top_level_keys:
                continue

            str_key = str(key)
            if str_key not in old_key_map:
                diff[key] = val
            else:
                old_val = old_key_map[str_key]
                if val != old_val:
                    diff[key] = val

        if diff:
            ordered_diff = {}
            for top_key in ["DirectoryName", "ID", "WeaponName", "WeaponType"]:
                if top_key in new_data:
                    ordered_diff[top_key] = new_data[top_key]
            for k, v in diff.items():
                ordered_diff[k] = v
            return ordered_diff

        return None

    elif isinstance(new_data, list):
        if not isinstance(old_data, list):
            return new_data

        old_item_map = {
            str(item[id_key]): item
            for item in old_data
            if isinstance(item, dict) and id_key in item
        }

        diff_list = []
        for new_item in new_data:
            if isinstance(new_item, dict) and id_key in new_item:
                item_id = str(new_item[id_key])
                if item_id not in old_item_map:
                    diff_list.append(new_item)
                else:
                    item_diff = compare_json_data(old_item_map[item_id], new_item, id_key=id_key)
                    if item_diff:
                        diff_list.append(item_diff)
            else:
                if new_item not in old_data:
                    diff_list.append(new_item)

        return diff_list if diff_list else None

    return new_data if new_data != old_data else None

def save_and_diff_json(file_name, new_data, id_key="ID"):
    # 输出到 GameOrganizeData/data 与 data_old，与 utils/common.py 的 DATA_ROOT 保持一致
    data_dir = DATA_ROOT
    data_old_dir = DATA_OLD_ROOT

    os.makedirs(data_dir, exist_ok=True)
    os.makedirs(data_old_dir, exist_ok=True)

    json_path = os.path.join(data_dir, f"{file_name}.json")
    old_json_path = os.path.join(data_old_dir, f"{file_name}.json")
    diff_json_path = os.path.join(data_dir, f"{file_name}_diff.json")

    old_data = None

    if os.path.exists(json_path):
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                old_data = json.load(f)
            os.replace(json_path, old_json_path)
            print(f"[{file_name}] 旧数据已备份至 data_old/{file_name}.json 喵！")
        except Exception as e:
            print(f"[{file_name}] 备份旧 JSON 数据失败: {e} 喵！")
    elif os.path.exists(old_json_path):
        try:
            with open(old_json_path, "r", encoding="utf-8") as f:
                old_data = json.load(f)
            print(f"[{file_name}] 从 data_old/ 读取到了历史数据喵！")
        except Exception as e:
            print(f"[{file_name}] 读取历史 JSON 数据失败: {e} 喵！")

    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(new_data, f, ensure_ascii=False, indent=4)
    print(f"[{file_name}] 最新全量数据已保存至 data/{file_name}.json 喵！")

    diff_data = compare_json_data(old_data, new_data, id_key=id_key)

    if diff_data:
        with open(diff_json_path, "w", encoding="utf-8") as f:
            json.dump(diff_data, f, ensure_ascii=False, indent=4)
        count = len(diff_data) if isinstance(diff_data, (dict, list)) else "若干"
        print(f"✨ [{file_name}] 检测到 {count} 条存在属性变更的武器记录，精炼差异已保存至 data/{file_name}_diff.json 喵！")
    else:
        print(f"[{file_name}] 与原数据一致，无新增或修改项喵！")

    return diff_data

def build_nested_json_data(raw_data_list, chinese_map):
    nested_list = []
    top_level_keys = {"DirectoryName", "ID", "WeaponName", "WeaponType"}

    for item in raw_data_list:
        nested_item = {}
        for k, v in item.items():
            if k in top_level_keys:
                nested_item[k] = v
            else:
                nested_item[k] = {
                    "name_en": k,
                    "name_cn": chinese_map.get(k, k),
                    "value": v
                }
        nested_list.append(nested_item)
    return nested_list

def generate_mediawiki_templates(nested_data_list, output_filepath):
    param_mapping = [
        ("单发间隔", "AttackInterval"),
        ("快速换弹", "TacticalReloadDuration"),
        ("空仓换弹", "EmptyReloadDuration"),
        ("最小散布", "SpreadMin"),
        ("最大散布", "SpreadMax"),
        ("散布修正系数", "SpreadModifierInc"),
        ("散布衰减速度", "SpreadDecSpeed"),
        ("移动散布增量", "SpreadIncSpeed"),
        ("静止散布衰减", "SpreadNoMove"),
        ("腰射散布缩放系数", "SpreadWaist"),
        ("肩射散布缩放系数", "SpreadAiming"),
        ("开镜散布缩放系数", "ADSSpreadScale"),

        ("后坐力持续时间", "RecoilTime"),
        ("后坐力恢复时间", "RecoveryTime"),
        ("后坐力恢复峰值", "RecoveryPeak"),

        ("垂直后坐力随机值下限", "PitchRecoilLower"),
        ("垂直后坐力随机值上限", "PitchRecoilHigher"),
        ("垂直后坐力修正系数", "PitchRecoilModifier"),
        ("垂直后坐力修正上限", "PitchRecoilModifierLimit"),
        ("垂直后坐力缩放系数", "PitchRecoilScale"),
        ("垂直后坐力上限", "PitchRecoilUpperLimit"),

        ("水平后坐力随机值下限", "YawRecoilLower"),
        ("水平后坐力随机值上限", "YawRecoilHigher"),
        ("水平后坐力修正系数", "YawRecoilModifier"),
        ("水平后坐力修正上限", "YawRecoilModifierLimit"),
        ("水平后坐力上限", "YawRecoilUpperLimit"),
    ]

    blocks = []

    for item in nested_data_list:
        dir_name = item.get("DirectoryName", "")
        weapon_id = item.get("ID", "")
        weapon_name = item.get("WeaponName", "")

        lines = ["{{武器详细数据"]
        for wiki_param, json_key in param_mapping:
            val_obj = item.get(json_key)
            if isinstance(val_obj, dict) and "value" in val_obj:
                val = val_obj["value"]
            else:
                val = val_obj

            val_str = str(val) if val is not None else ""
            lines.append(f"|{wiki_param}={val_str}")
        lines.append("}}")

        header = f"<!-- 武器: {dir_name} ({weapon_name}) ID: {weapon_id} -->"
        block_text = header + "\n" + "\n".join(lines)
        blocks.append(block_text)

    full_text = "\n\n".join(blocks)

    with open(output_filepath, "w", encoding="utf-8") as f:
        f.write(full_text)

    print(f"Mediawiki 模板文本已成功生成并保存至：{output_filepath} 喵！")

def load_mode_curve_table(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for obj in data:
        if obj.get("Type") == "ModeCurveTable":
            props = obj.get("Properties", {})
            tables = props.get("CurveTables", [])
            for entry in tables:
                if entry.get("Key") == "EModeCurveType::Default":
                    val = entry.get("Value")
                    if val:
                        raw = val.get("ObjectName", "")
                        match = re.search(r"CurveTable'([^']+)'", raw)
                        if match:
                            return match.group(1) + ".json"
    raise ValueError("未找到 Default 模式对应的曲线表喵！")

curve_table_name = load_mode_curve_table(GAME_MODE_CURVE_FILE)
CURVE_FILE = os.path.join(CSV_DIR, curve_table_name)
print(f"实际公共曲线表: {CURVE_FILE}")

def load_curve_table(filepath):
    if not os.path.exists(filepath):
        return {}
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for obj in data:
        if obj.get("Type") == "CurveTable" and "Rows" in obj:
            rows = obj["Rows"]
            curve_values = {}
            for row_name, row_data in rows.items():
                keys = row_data.get("Keys", [])
                if keys:
                    curve_values[row_name] = keys[0]["Value"]
                else:
                    curve_values[row_name] = None
            return curve_values
    return {}

global_curve_values = load_curve_table(CURVE_FILE)
print(f"已加载 {len(global_curve_values)} 条公共曲线数据喵！")

def safe_get(obj, path, default=None):
    if not obj:
        return default
    keys = path.split('.')
    for key in keys:
        if isinstance(obj, dict) and key in obj:
            obj = obj[key]
        else:
            return default
    return obj

def resolve_value(obj, curve_values):
    if obj is None:
        return None
    if isinstance(obj, (int, float, str)):
        return obj
    if isinstance(obj, dict):
        curve = obj.get("Curve")
        if isinstance(curve, dict):
            row_name = curve.get("RowName")
            if row_name and row_name != "None" and row_name in curve_values:
                return curve_values[row_name]
        if "Value" in obj:
            return obj["Value"]
        if "MobileValue" in obj:
            return obj["MobileValue"]
        return None
    return obj

def dereference_object(ref_obj, obj_map):
    if not isinstance(ref_obj, dict):
        return None
    obj_name_raw = ref_obj.get("ObjectName", "")
    if not obj_name_raw:
        return None
    match = re.search(r":([^\'\"]+)", obj_name_raw)
    if match:
        sub_name = match.group(1)
        if sub_name in obj_map:
            return obj_map[sub_name]
    match_name = re.search(r"'([^':]+)'", obj_name_raw)
    if match_name:
        short_name = match_name.group(1)
        if short_name in obj_map:
            return obj_map[short_name]
    return None

def find_cached_component_obj(cached_list, key_name, obj_map):
    for comp in cached_list:
        if comp.get("Key") == key_name:
            val_ref = comp.get("Value")
            if val_ref:
                return dereference_object(val_ref, obj_map)
    return None

CHINESE_MAP = {
    "DirectoryName": "文件所在目录",
    "ID": "武器ID",
    "WeaponName": "武器内部名称",
    "WeaponType": "武器类型",
    "WalkSpeed": "步行速度",
    "RunSpeed": "跑步速度",
    "SprintSpeed": "冲刺速度",
    "AttackDamage": "基础伤害",
    "AttackInterval": "全自动射击间隔(秒)",
    "RPM": "理论射速(发/分钟)",
    "RecoilTime": "后坐力作用时间(秒)",
    "RecoveryTime": "后坐力恢复时间(秒)",
    "RecoveryPeak": "恢复峰值",
    "PitchRecoilLower": "垂直后坐力下限",
    "PitchRecoilHigher": "垂直后坐力上限",
    "PitchRecoilModifier": "垂直后坐力修正系数",
    "PitchRecoilModifierLimit": "垂直后坐力修正上限",
    "PitchRecoilScale": "垂直后坐力缩放",
    "PitchRecoilUpperLimit": "垂直后坐力总上限",
    "YawRecoilLower": "水平后坐力下限",
    "YawRecoilHigher": "水平后坐力上限",
    "YawRecoilModifier": "水平后坐力修正系数",
    "YawRecoilModifierLimit": "水平后坐力修正上限",
    "YawRecoilUpperLimit": "水平后坐力总上限",
    "SpreadMin": "最小散布",
    "SpreadMax": "最大散布",
    "SpreadModifierBase": "散布基础修正",
    "SpreadModifierInc": "散布增加修正",
    "SpreadModifierMax": "散布最大修正",
    "SpreadDecSpeed": "散布衰减速度",
    "SpreadIncSpeed": "散布增加速度",
    "SpreadNoMove": "静止时散布缩放",
    "SpreadWalk": "步行时散布缩放",
    "SpreadRun": "跑步时散布缩放",
    "SpreadInAir": "空中散布缩放",
    "SpreadWaist": "腰射散布缩放系数",
    "SpreadAiming": "肩射散布缩放系数",
    "ADSSpreadScale": "开镜散布缩放系数",
    "ReloadStartDuration": "换弹-卸弹匣阶段(秒)",
    "ReloadSecondStartDuration": "换弹-空仓拉栓阶段(秒)",
    "ReloadDuration": "换弹-装弹匣阶段(秒)",
    "ReloadEndDuration": "换弹-结束动作阶段(秒)",
    "TacticalReloadDuration": "战术换弹时间(秒)",
    "EmptyReloadDuration": "空仓换弹时间(秒)",
    "MagazineCapacity": "弹匣容量(发)",
    "AmmoMax": "总备弹量",
}

def extract_weapon_data(weapon_path, global_curve_values):
    with open(weapon_path, 'r', encoding='utf-8') as f:
        raw = json.load(f)

    # 动态加载当前武器的专属 CurveTable 数据
    weapon_curve_values = global_curve_values.copy()
    weapon_dir = os.path.dirname(weapon_path)
    mode_curve_dir = os.path.join(weapon_dir, "CurveTable")
    if os.path.exists(mode_curve_dir):
        for cf in os.listdir(mode_curve_dir):
            if cf.endswith(".json"):
                cf_path = os.path.join(mode_curve_dir, cf)
                local_curves = load_curve_table(cf_path)
                weapon_curve_values.update(local_curves)

    obj_map = {obj.get("Name"): obj for obj in raw if "Name" in obj}
    type_map = {obj.get("Type"): obj for obj in raw if "Type" in obj}

    default_obj = None
    for obj in raw:
        props = obj.get("Properties")
        if props and "SpeedConfig" in props:
            default_obj = obj
            break
    if not default_obj:
        print(f"警告：在 {weapon_path} 中未找到主 CDO 对象喵！")
        return None

    props = default_obj.get("Properties", {})
    data = {}

    data["DirectoryName"] = os.path.basename(os.path.dirname(weapon_path))
    data["ID"] = props.get("ID")
    data["WeaponName"] = props.get("WeaponName")
    data["WeaponType"] = props.get("WeaponType")

    speed_cfg = props.get("SpeedConfig", {})
    speed3d = speed_cfg.get("Speed3D", [])
    for item in speed3d:
        key = item.get("Key", "")
        val_obj = item.get("Value")
        val = resolve_value(val_obj, weapon_curve_values)
        if "Walk" in key:
            data["WalkSpeed"] = val
        elif "Run" in key:
            data["RunSpeed"] = val
        elif "Sprint" in key:
            data["SprintSpeed"] = val

    cached = props.get("CachedComponents", [])

    attack_comp_obj = dereference_object(props.get("AttackComponent"), obj_map)
    attack_props = attack_comp_obj.get("Properties", {}) if attack_comp_obj else {}

    attack_damage = attack_props.get("AttackDamage")
    data["AttackDamage"] = resolve_value(attack_damage, weapon_curve_values)

    auto_switch = find_cached_component_obj(cached, "AttackSwitchAuto", obj_map)
    total_dur = safe_get(auto_switch, "Properties.TotalDuration") if auto_switch else None

    if total_dur is None:
        single_switch = find_cached_component_obj(cached, "AttackSwitchSingle", obj_map)
        total_dur = safe_get(single_switch, "Properties.TotalDuration")

    if total_dur is None:
        effect_comp = dereference_object(props.get("EffectComponent"), obj_map)
        total_dur = safe_get(effect_comp, "Properties.DefaultTriggerRateShotDuration")

    interval = resolve_value(total_dur, weapon_curve_values)
    data["AttackInterval"] = interval
    data["RPM"] = round(60 / interval, 2) if interval and interval > 0 else None

    recoil = attack_props.get("RecoilProcessor")
    if recoil:
        for field in ["RecoilTime", "RecoveryTime", "RecoveryPeak",
                      "PitchRecoilLower", "PitchRecoilHigher",
                      "PitchRecoilModifier", "PitchRecoilModifierLimit",
                      "PitchRecoilScale", "PitchRecoilUpperLimit",
                      "YawRecoilLower", "YawRecoilHigher",
                      "YawRecoilModifier", "YawRecoilModifierLimit",
                      "YawRecoilUpperLimit"]:
            val = recoil.get(field)
            data[field] = resolve_value(val, weapon_curve_values) if val else None

    spread = attack_props.get("SpreadProcessor")
    if spread:
        for field in ["SpreadMin", "SpreadMax", "SpreadModifierBase",
                      "SpreadModifierInc", "SpreadModifierMax",
                      "SpreadDecSpeed", "SpreadIncSpeed"]:
            val = spread.get(field)
            data[field] = resolve_value(val, weapon_curve_values) if val else None
        spread_scale = spread.get("SpreadScale", {})
        for key in ["NoMove", "Walk", "Run", "InAir"]:
            val = spread_scale.get(key)
            data[f"Spread{key}"] = resolve_value(val, weapon_curve_values) if val else None

    # ---- 各持枪姿态散布缩放系数提取 ----
    # 1. 腰射散布 (HoldSwitchWaist 兜底 HoldSwitchRelaxed)
    hold_waist = find_cached_component_obj(cached, "HoldSwitchWaist", obj_map) or find_cached_component_obj(cached, "HoldSwitchRelaxed", obj_map)
    if hold_waist:
        spread_scale = safe_get(hold_waist, "Properties.SpreadScale")
        data["SpreadWaist"] = resolve_value(spread_scale, weapon_curve_values) if spread_scale else None
    else:
        data["SpreadWaist"] = None

    # 2. 肩射散布 (HoldSwitchAiming)
    hold_aiming = find_cached_component_obj(cached, "HoldSwitchAiming", obj_map)
    if hold_aiming:
        spread_scale = safe_get(hold_aiming, "Properties.SpreadScale")
        data["SpreadAiming"] = resolve_value(spread_scale, weapon_curve_values) if spread_scale else None
    else:
        data["SpreadAiming"] = None

    # 3. 开镜散布 (HoldSwitchADS)
    hold_ads = find_cached_component_obj(cached, "HoldSwitchADS", obj_map)
    if hold_ads:
        spread_scale = safe_get(hold_ads, "Properties.SpreadScale")
        data["ADSSpreadScale"] = resolve_value(spread_scale, weapon_curve_values) if spread_scale else None
    else:
        data["ADSSpreadScale"] = None

    reload_start = find_cached_component_obj(cached, "StateStartReload", obj_map) or type_map.get("CyFStartReloadState")
    reload_second_start = find_cached_component_obj(cached, "StateSecondStartReload", obj_map) or type_map.get("CyFSecondStartReloadState")
    reload_state = find_cached_component_obj(cached, "StateReload", obj_map) or type_map.get("CyFReloadState")
    reload_end = find_cached_component_obj(cached, "StateEndReload", obj_map) or type_map.get("CyFEndReloadState")

    if reload_start:
        dur = safe_get(reload_start, "Properties.TotalDuration")
        data["ReloadStartDuration"] = resolve_value(dur, weapon_curve_values)

    if reload_second_start:
        dur = safe_get(reload_second_start, "Properties.TotalDuration")
        data["ReloadSecondStartDuration"] = resolve_value(dur, weapon_curve_values)
    else:
        data["ReloadSecondStartDuration"] = None

    if reload_state:
        dur = safe_get(reload_state, "Properties.TotalDuration")
        data["ReloadDuration"] = resolve_value(dur, weapon_curve_values)

    if reload_end:
        dur = safe_get(reload_end, "Properties.TotalDuration")
        data["ReloadEndDuration"] = resolve_value(dur, weapon_curve_values)

    tactical_reload = 0
    for k in ["ReloadStartDuration", "ReloadDuration", "ReloadEndDuration"]:
        v = data.get(k)
        if isinstance(v, (int, float)):
            tactical_reload += v
    data["TacticalReloadDuration"] = round(tactical_reload, 4) if tactical_reload > 0 else None

    sec_start = data.get("ReloadSecondStartDuration")
    if isinstance(sec_start, (int, float)) and sec_start > 0:
        empty_reload = tactical_reload + sec_start
    else:
        empty_reload = tactical_reload
    data["EmptyReloadDuration"] = round(empty_reload, 4) if tactical_reload > 0 else None

    part_mag = find_cached_component_obj(cached, "PartMagazine", obj_map)
    if part_mag:
        ammo = safe_get(part_mag, "Properties.AmmoPerMagazine")
        data["MagazineCapacity"] = resolve_value(ammo, weapon_curve_values)
        ammo_max = safe_get(part_mag, "Properties.AmmoMax")
        data["AmmoMax"] = resolve_value(ammo_max, weapon_curve_values)

    return data

# ---------- 主流程 ----------
all_data = []
weapon_files = list(Path(WEAPON_ROOT).rglob("Weapon*.json"))
print(f"找到 {len(weapon_files)} 个武器 JSON 文件喵！")

for wfile in weapon_files:
    print(f"处理: {wfile}")
    data = extract_weapon_data(str(wfile), global_curve_values)
    if data:
        all_data.append(data)

if not all_data:
    print("没有提取到任何数据，请检查路径和文件结构喵！")
    exit()

all_data.sort(key=lambda x: x.get("ID", 0))

# 1. 导出 CSV 文件至 GameOrganizeData/data
df = pd.DataFrame(all_data)
new_columns = {col: f"{col} ({CHINESE_MAP.get(col, col)})" for col in df.columns}
df.rename(columns=new_columns, inplace=True)

os.makedirs(DATA_ROOT, exist_ok=True)
output_csv = os.path.join(DATA_ROOT, "weapons_summary.csv")
df.to_csv(output_csv, index=False, encoding='utf-8-sig')
print(f"汇总数据已成功导出至 CSV 文件：{output_csv} 喵！")

# 2. 转换为嵌套结构的 JSON 数据
nested_json_data = build_nested_json_data(all_data, CHINESE_MAP)

# 3. 保存嵌套 JSON 并自动对比导出精炼差异 JSON
save_and_diff_json("weapons_summary", nested_json_data, id_key="ID")

# 4. 生成 Mediawiki 模板文本文件至 GameOrganizeData/data
output_txt = os.path.join(DATA_ROOT, "weapons_wiki_template.txt")
generate_mediawiki_templates(nested_json_data, output_txt)
