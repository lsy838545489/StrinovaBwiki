# modules_mobile/generate_escort2_card.py
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
        except Exception:
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
        except Exception:
            key = rid

        # 仅添加有效存在的角色
        if key in id_to_Role_name:
            mapped.append(id_to_Role_name[key])

    return mapped


def parse_icon_number(icon_white):
    """从 IconWhite.AssetPathName 中解析末尾数字，解析失败返回 None"""
    if not isinstance(icon_white, dict):
        return None
    asset_path_name = icon_white.get('AssetPathName', '')
    if not asset_path_name:
        return None
    try:
        return int(asset_path_name.split('/')[-1].split('_')[-1])
    except (ValueError, IndexError):
        return None


def export_escort2_card_data():
    print("开始处理极限推进卡牌(Escort2Card)数据喵...")

    card_data = load_json_file("GameplayCard_Escort2")
    string_table = load_json_file("ST_Escort2_Mobile")
    if not card_data or not string_table:
        return

    keys_to_entries = string_table[0].get("StringTable", {}).get("KeysToEntries", {})

    output_data = []

    for item in card_data:
        # Rows 可能是字典或列表，兼容处理
        rows = item.get('Rows', {}) if isinstance(item, dict) else {}
        iterable_rows = rows.values() if isinstance(rows, dict) else rows
        for row in iterable_rows:
            ability_type_name = keys_to_entries.get(row.get('TagDesc', {}).get('Key'), "未找到文本") or "UnknownAbility"
            name_source = row.get('Name', {}).get('Key', '')
            name_value = keys_to_entries.get(name_source)

            unlock_roles = process_unlock_roles(row.get("UnlockRoles", []))
            rarity_value = value_to_rarity_name.get(row.get('Rarity'), row.get('Rarity'))

            icon_value = parse_icon_number(row.get('IconWhite'))

            desc_source = keys_to_entries.get(row.get('Desc', {}).get('Key'), "未找到文本")
            desc_string = multi_replace(desc_source, replace_str)
            param_values = row.get("DescParamLevel1", [])

            card_entry = {
                "id": row.get('CardId'),
                "name": name_value,
                "category": ability_type_name,
                "quality": rarity_value,
                "icon": icon_value,
                "unlockRoles": unlock_roles,
                "desc": replace_placeholders(desc_string, param_values),
            }

            output_data.append(card_entry)

    if not output_data:
        print("未提取到任何极限推进卡牌数据，跳过导出。")
        return

    # 对比并保存主数据表（全量与增量）
    save_and_diff_data("Escort2Card", output_data)

    print("极限推进卡牌(Escort2Card)数据处理完成喵！")


if __name__ == "__main__":
    export_escort2_card_data()
