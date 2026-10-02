# modules_mobile/generate_zombie_card.py
import re

from utils.common_mobile import load_json_file, save_and_diff_data

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


def convert_numbers(arr):
    """把列表中的数字字符串转成 int / float，非数字保持原样"""
    result = []
    for item in arr:
        s = str(item).strip()
        try:
            num = float(s)
        except ValueError:
            result.append(item)
            continue
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


def fill_desc(template, params):
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


def export_zombie_card_data():
    print("开始处理晶源感染卡牌(ZombieCard)数据喵...")

    Card_data = load_json_file("GameplayCard_Zombie")
    string_table = load_json_file("ST_ZombieCard_Mobile")
    string_table2 = load_json_file("ST_Escort2_Mobile")
    if not Card_data or not string_table or not string_table2:
        return

    keys_to_entries = string_table[0].get("StringTable", {}).get("KeysToEntries", {})
    keys_to_entries2 = string_table2[0].get("StringTable", {}).get("KeysToEntries", {})

    output_data = []
    for item in Card_data:
        for row in item['Rows'].values():
            name_source = row.get('Name', {}).get('Key', '')
            name_value = keys_to_entries.get(name_source)

            # 跳过付费（Extension）卡牌
            if row.get("Extension") is True:
                continue

            id = row.get('Id')
            card_id = row.get('CardId')
            max_level = row.get('MaxLevel', 0)

            category_source = row.get('TagDesc', {}).get('Key', '')
            category_value = keys_to_entries2.get(category_source, "未找到文本")

            # 阵营与稀有度（安全访问，避免遇到未映射取值时崩溃）
            raw_team = row.get('TeamType')
            TeamType_value = value_to_TeamType_name.get(raw_team, raw_team)
            raw_rarity = row.get('Rarity')
            rarity_value = value_to_rarity_name.get(raw_rarity, raw_rarity)

            # 原始描述文本（带 {0} {1}）
            desc_source = keys_to_entries.get(row.get('Desc', {}).get('Key'), "未找到文本")
            desc_template = desc_source.replace("<Orange-Medium-Dynamic>", "").replace("</>", "")

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
                "extension": "付费" if row.get("Extension") else "免费",
            }

            for level in range(1, max_level + 1):
                params = row.get(f"DescParamLevel{level}", [])
                params = convert_numbers(params)
                filled = fill_desc(desc_template, params)
                extracted_data[f"descLevel{level}"] = filled

            output_data.append(extracted_data)

    if not output_data:
        print("未提取到任何晶源感染卡牌数据，跳过导出。")
        return

    # 对比并保存主数据表（全量与增量）
    save_and_diff_data("ZombieCard", output_data)

    print("晶源感染卡牌(ZombieCard)数据处理完成喵！")


if __name__ == "__main__":
    export_zombie_card_data()
