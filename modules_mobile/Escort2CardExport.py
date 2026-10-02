import sys
import os
import re
import json
from pathlib import Path

# ========== 配置区 ==========
PROJECT_ROOT = r'Z:\BwikiScript'
os.chdir(PROJECT_ROOT)
sys.path.append(PROJECT_ROOT)
from common_mobile import load_json_file, save_with_backup
# ===========================

# 角色ID映射表（省略长表，使用你原来的）
id_to_Role_name = {
    101: "米雪儿",
    105: "奥黛丽",
    107: "玛德蕾娜",
    108: "信",
    109: "令",
    110: "白墨",
    112: "绯莎",
    115: "芙拉薇娅",
    119: "艾卡",
    120: "珐格兰丝",
    121: "忧雾",
    122: "玛拉",
    123: "蕾欧娜",
    124: "心夏",
    125: "千代",
    128: "拉薇",
    131: "伊薇特",
    132: "明",
    133: "梅瑞狄斯",
    137: "香奈美",
    146: "星绘",
    205: "加拉蒂亚"
}

# 稀有度映射表
value_to_rarity_name = {
    "ECyCardRarityType::Blue": 2,
    "ECyCardRarityType::Purple": 3,
    "ECyCardRarityType::Gold": 4
}

replace_str = [
    "<Purple-Medium-Dynamic>",
    "<Purple-Medium-Black-Dynamic>",
    "<Blue-Medium-Dynamic>",
    "<Orange-Medium-Dynamic>",
    "<Blue-Medium-Black-Dynamic>",
    "</>"
]

def multi_replace(text, replacements):
    if not text:
        return text
    for s in replacements:
        text = text.replace(s, "")
    return text

def replace_placeholders(template, values):
    """改进版占位符替换函数，处理 {0} { 1 } 等各种空格格式占位符"""
    if not template:
        return template
    if not values:
        return template  # 没有参数就返回原字符串

    def convert_number(value):
        try:
            num = float(value)
            if num.is_integer():
                return str(int(num))
            return str(num)
        except (ValueError, TypeError):
            return str(value)

    # 对每个下标做全局替换（相同下标的多个占位都会被替换）
    for i, value in enumerate(values):
        str_value = convert_number(value)
        # 使用 \b 边界不可靠（模板里可能不是纯数字边界），用更严格的正则
        template = re.sub(r'\{\s*' + re.escape(str(i)) + r'\s*\}', str_value, template)
    return template

def process_unlock_roles(role_ids):
    """
    处理解锁角色字段：
    - 如果 role_ids 为空 -> 返回 None
    - 统计唯一有效角色数量（仅计算存在的ID）
    - 若有效角色数量达到全部角色数量 -> 返回 None（全角色）
    - 否则返回有效角色的中文名列表（自动过滤无效ID）
    """
    if not role_ids:
        return None

    valid_ids = set()
    mapped = []

    # 第一轮：筛选有效ID并统计
    for rid in role_ids:
        if rid is None:
            continue
        try:
            # 统一转换为整数型ID（兼容字符串数字）
            key = int(rid) if isinstance(rid, str) and rid.isdigit() else rid
        except:
            key = rid

        # 仅保留存在的有效ID
        if key in id_to_Role_name:
            valid_ids.add(key)

    # 全角色判断（仅计算有效ID）
    if len(valid_ids) >= len(id_to_Role_name):
        return None

    # 第二轮：构建有效角色名称列表
    for rid in role_ids:
        if rid is None:
            continue
        try:
            key = int(rid) if isinstance(rid, str) and rid.isdigit() else rid
        except:
            key = rid

        # 仅添加有效存在的角色
        if key in id_to_Role_name:
            mapped.append(id_to_Role_name[key])

    return mapped

def escape_lua_string(s: str) -> str:
    """简单转义字符串以写入 Lua 双引号字符串"""
    if s is None:
        return ""
    s = str(s)
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    s = s.replace('\r', '\\r')
    return s

# 读取数据
card_data = load_json_file("GameplayCard_Escort2")
string_table = load_json_file("ST_Escort2_Mobile")
keys_to_entries = string_table[0].get("StringTable", {}).get("KeysToEntries", {})

output_data = []

for item in card_data:
    # Rows 可能是字典或列表，兼容处理
    rows = item.get('Rows', {}) if isinstance(item, dict) else {}
    # 如果 rows 是 dict，用 values；如果是 list，直接遍历
    iterable_rows = rows.values() if isinstance(rows, dict) else rows
    for row in iterable_rows:
        ability_type_name = keys_to_entries.get(row.get('TagDesc', {}).get('Key'), "未找到文本") or "UnknownAbility"
        name_source = row.get('Name', {}).get('Key', '')
        name_value = keys_to_entries.get(name_source)
        # 处理解锁角色和稀有度
        unlock_roles = process_unlock_roles(row.get("UnlockRoles", []))
        rarity_value = value_to_rarity_name.get(row.get('Rarity'), row.get('Rarity'))

        Icon_name = row.get('IconWhite', {}).get('AssetPathName', '')
        Icon_value = int(Icon_name.split('/')[-1].split('_')[-1])
        # 处理描述占位符与替换
        desc_source = keys_to_entries.get(row.get('Desc', {}).get('Key'), "未找到文本")
        desc_string = multi_replace(desc_source, replace_str)
        param_values = row.get("DescParamLevel1", [])

        card_entry = {
            "id": row.get('CardId'),
            "name": name_value,
            "category": ability_type_name,
            "quality": rarity_value,
            "icon": Icon_value,
            "unlockRoles": unlock_roles,
            "desc": replace_placeholders(desc_string, param_values),
        }

        # 把卡片加入对应 ability_type 的数组中（保留多个卡片）
        output_data.append(card_entry)

# 输出目录与文件
out_dir = Path('.') / 'MobileBatch' / 'NewData'
out_dir.mkdir(parents=True, exist_ok=True)

json_path = out_dir / 'Escort2Card.json'
try:
    save_with_backup(str(json_path), output_data)
except Exception:
    with json_path.open('w', encoding='utf-8') as jf:
        json.dump(output_data, jf, ensure_ascii=False, indent=2)


lua_path = out_dir / 'Escort2Card.lua'
with lua_path.open('w', encoding='utf-8') as file:
    file.write('return {\n')
    for card in output_data:
        file.write(f'	{{\n')
        for key, value in card.items():
            if value is None:
                continue
            elif isinstance(value, bool):
                file.write(f"		{key} = {'true' if value else 'false'},\n")
            elif isinstance(value, list):
                if value:
                    items = "', '".join(str(v) for v in value)
                    file.write(f"		{key} = {{ '{items}' }},\n")
                else:
                    file.write(f"		{key} = {{}},\n")
            elif isinstance(value, (int, float)):
                file.write(f"		{key} = {value},\n")
            elif value == "":
                file.write(f"		{key} = '',\n")
            else:
                file.write(f"		{key} = '{value}',\n")
        file.write("	},\n")
    file.write('}\n')
