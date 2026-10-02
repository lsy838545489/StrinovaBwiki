import sys
import os
import re
import json

# 设置项目根目录
PROJECT_ROOT = r'Z:\BwikiScript'  # 使用原始字符串以防止转义字符问题
os.chdir(PROJECT_ROOT)  # 更改当前工作目录为项目根目录

# 导入所需模块
sys.path.append(PROJECT_ROOT)
from common_mobile import load_json_file, save_with_backup

# 角色ID映射表
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

# 阵营映射表
value_to_TeamType_name = {
    "ECyCardTeamType::Zombie": "晶源体",
    "ECyCardTeamType::Human": "超弦体"
}

# 加载卡牌数据
Card_data = load_json_file("GameplayCard_Zombie")
string_table = load_json_file("ST_ZombieCard_Mobile")
string_table2 = load_json_file("ST_Escort2_Mobile")
keys_to_entries = string_table[0].get("StringTable", {}).get("KeysToEntries", {})
keys_to_entries2 = string_table2[0].get("StringTable", {}).get("KeysToEntries", {})

def convert_numbers(arr):
    result = []

    for item in arr:
        # 尝试转换为字符串处理
        s = str(item).strip()

        # 不是数字格式（包含字母等）则保持原样
        try:
            num = float(s)
        except ValueError:
            result.append(item)
            continue

        # 判断是否是整数值（小数部分为 0）
        if num.is_integer():
            result.append(int(num))
        else:
            result.append(num)

    return result

def process_unlock_roles(role_ids):
    """
    处理解锁角色字段：
    - 如果 role_ids 为空 -> 返回 None
    - 统计唯一角色数量；若达到全部角色数量 (len(id_to_Role_name)) -> 返回 None（表示全角色）
    - 否则按 id_to_Role_name 映射返回名字列表，找不到映射则保留原值
    """
    if not role_ids:
        return None

    # 计算唯一 id 的数量（尝试把能转换为 int 的值转换为 int，避免 "101" 与 101 被视为不同）
    unique_ids = set()
    for rid in role_ids:
        if rid is None:
            continue
        try:
            unique_ids.add(int(rid))
        except Exception:
            unique_ids.add(rid)

    # 如果等于或超过映射表中的总角色数（认为是全角色），则返回 None
    if len(unique_ids) >= len(id_to_Role_name):
        return None

    # 否则按映射表把 id 转为中文名（找不到则保留原值）
    mapped = []
    for rid in role_ids:
        if rid is None:
            continue
        try:
            key = int(rid)
        except Exception:
            key = rid
        mapped.append(id_to_Role_name.get(key, rid))
    return mapped

def fill_desc(template: str, params: list):
    """
    将模板文本中的 {0},{1},... 用 params 填入。
    params 为列表，0-based 输入。
    """
    if not template:
        return template

    def repl(match):
        idx = int(match.group(1))
        return str(params[idx]) if idx < len(params) else ""

    return re.sub(r"\{\s*(\d+)\s*\}", repl, template)


output_data = []
for item in Card_data:
    for row in item['Rows'].values():
        name_source = row.get('Name', {}).get('Key', '')
        name_value = keys_to_entries.get(name_source)
        if row["Extension"] == True:
            continue

        id = row['Id']
        card_id = row['CardId']
        max_level = row['MaxLevel']
        name_source = row.get('Name', {}).get('Key', '')
        name_value = keys_to_entries.get(name_source)
        category_source = row.get('TagDesc', {}).get('Key', '')
        category_value = keys_to_entries2.get(name_source)

        # 阵营与稀有度
        TeamType_value = value_to_TeamType_name[row['TeamType']]
        rarity_value = value_to_rarity_name[row['Rarity']]

        # 原始描述文本（带 {0} {1}）
        desc_source = keys_to_entries.get(row.get('Desc', {}).get('Key'), "未找到文本")
        desc_template = desc_source.replace("<Orange-Medium-Dynamic>","").replace("</>","")

        # 处理解锁角色
        if TeamType_value == "晶源体":
            unlock_roles = None
        else:
            unlock_roles = process_unlock_roles(row.get("UnlockRoles", []))

        extracted_data = {
            "id": id,
            "cardid": card_id,
            "name": name_value,
            "quality": rarity_value,
            "category": category_value,
            "teamType": TeamType_value,
            "unlockRoles": unlock_roles,
            "maxLevel": max_level,
            "extension": "付费" if row["Extension"] else "免费",
        }

        for level in range(1, max_level + 1):
            params = row.get(f"DescParamLevel{level}", [])
            params = convert_numbers(params)
            filled = fill_desc(desc_template, params)
            extracted_data[f"descLevel{level}"] = filled

        output_data.append(extracted_data)

# 导出为JSON文件
save_with_backup('.\\MobileBatch\\NewData\\ZombieCard.json', output_data)

with open('.\\MobileBatch\\NewData\\ZombieCard.lua', 'w', encoding='utf-8') as file:
    file.write('return {\n')
    for card in output_data:
        card_id = card['id']
        file.write(f'	[{card_id}] = {{\n')
        for key, value in card.items():
            if key != 'id':
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
