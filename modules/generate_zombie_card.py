# modules/generate_zombie_card.py
import re
from utils.common import id_to_Role_name, load_json_file, format_lua_table, export_data_file

def export_zombie_card_data():
    print("开始处理卡牌数据...")
    # 稀有度映射表
    value_to_rarity_name = {
        "ECyCardRarityType::White": 1,
        "ECyCardRarityType::Blue": 2,
        "ECyCardRarityType::Purple": 3,
        "ECyCardRarityType::Gold": 4
    }

    # 阵营映射表
    value_to_TeamType_name = {
        "ECyCardTeamType::Zombie": "晶源体",
        "ECyCardTeamType::Human": "超弦体",
        "ECyCardTeamType::All": "全阵营"
    }

    # 分类映射表
    value_to_category_name = {
        "ECyCardCategory::Global": "随机事件",
        "ECyCardCategory::Hextech": "天赋",
        "ECyCardCategory::Weapon": "武器",
        "ECyCardCategory::Rule": "规则",
        "ECyCardCategory::Skill": "技能",
        "ECyCardCategory::Role": "角色"
    }

    # 加载卡牌数据
    Card_data = load_json_file("GameplayCard_Zombie")

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


    card_data = {}        # 存放常规卡牌
    hextech_data = {}     # 存放 Hextech 卡牌
    global_data = {}      # 存放 Global (随机事件)
    card_name_map = {}

    for item in Card_data:
        for row in item['Rows'].values():
            name_data = row.get('Name', {})
            localized_string = name_data.get('LocalizedString')
            if localized_string is None or str(localized_string).lower() == "null":
                continue

            id = int(row['Id'])
            card_id = row['CardId']
            card_name = row['Name']['LocalizedString']

            # 提前提取原始 Category，用于后续分流判断
            raw_category = row.get('Category')
            category_value = value_to_category_name.get(raw_category, raw_category)
            max_level = row['MaxLevel']

            # 阵营与稀有度
            TeamType_value = value_to_TeamType_name.get(row.get('TeamType'), row.get('TeamType'))
            rarity_value = value_to_rarity_name.get(row.get('Rarity'), None)

            # 原始描述文本（带 {0} {1}）
            desc_template = row['Desc'].get('LocalizedString', '')

            # 处理解锁角色
            if TeamType_value == "晶源体":
                unlock_roles = None
            else:
                unlock_roles = process_unlock_roles(row.get("UnlockRoles", []))

            extracted_data = {
                "cardid": card_id,
                "name": card_name,
                "quality": rarity_value,
                "category": category_value if raw_category != "ECyCardCategory::Hextech" else None,
                "teamType": TeamType_value,
                "unlockRoles": unlock_roles,
                "maxLevel": max_level,
                "extension": True if row.get("Extension") else None,  # 使用get防止键缺失报错
                "default": True if row.get("Default") else None,      # 使用get防止键缺失报错
            }

            desc_list = []
            for level in range(1, max_level + 1):
                params = row.get(f"DescParamLevel{level}", [])
                params = convert_numbers(params)
                filled = fill_desc(desc_template, params)
                desc_list.append(filled)

            # 利用 set() 集合的特性判断是否所有字符串都一模一样
            if desc_list and len(set(desc_list)) == 1:
                extracted_data["descLevel1"] = desc_list[0]
            else:
                # 存在不同，正常遍历保存各个等级的描述
                for i, desc_text in enumerate(desc_list, start=1):
                    extracted_data[f"descLevel{i}"] = desc_text

            # === 核心修改：数据分流 ===
            if raw_category == "ECyCardCategory::Global":
                global_data[id] = extracted_data
            elif raw_category == "ECyCardCategory::Hextech":
                hextech_data[id] = extracted_data
            else:
                card_data[id] = extracted_data
                card_name_map[card_name] = ""

    # 导出为JSON与LUA文件
    # 1. 导出常规卡牌 (除 Global 和 Hextech 以外)
    export_data_file('ZombieCard', card_data, fileType='json')
    export_data_file('ZombieCard', format_lua_table(card_data), fileType='lua')
    export_data_file('ZombieCard_NameList', format_lua_table(card_name_map), fileType='lua')

    # 2. 导出 Global (随机事件) 专属卡牌文件
    if global_data:
        export_data_file('ZombieCard_Global', global_data, fileType='json')
        export_data_file('ZombieCard_Global', format_lua_table(global_data), fileType='lua')

    # 3. 导出 Hextech 专属卡牌文件
    if hextech_data:
        export_data_file('ZombieCard_Hextech', hextech_data, fileType='json')
        export_data_file('ZombieCard_Hextech', format_lua_table(hextech_data), fileType='lua')

    print("卡牌数据处理并分拆导出完成！")
