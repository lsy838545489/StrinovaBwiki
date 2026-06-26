# modules/generate_growth.py
import json
import os

# 直接从 common.py 导入各种超好用的工具函数喵！
from utils.common import (
    id_to_Role_name,
    load_json_file,
    upload_wiki_data,
    format_lua_table,
    export_data_file,
    PROJECT_ROOT
)

def safe_get_nested_data(data, path, default=""):
    """安全获取嵌套字典数据的辅助函数"""
    try:
        for key in path:
            if isinstance(data, list) and isinstance(key, int):
                data = data[key]
            else:
                data = data.get(key, default)
        return data if data else default
    except (AttributeError, KeyError, IndexError):
        return default

def format_desc_field(desc_field):
    """用于格式化 QDesc 和 PassiveDesc 的函数"""
    if not desc_field:
        return [], []

    if isinstance(desc_field, list):
        all_descriptions = []
        for item in desc_field:
            source_fmt = safe_get_nested_data(item, ['SourceFmt', 'LocalizedString'])
            if source_fmt:
                arguments = safe_get_nested_data(item, ['Arguments'], [])
                if arguments:
                    formatted_desc = source_fmt.format(*[arg['Value'] for arg in arguments])
                    all_descriptions.append(formatted_desc)
                else:
                    all_descriptions.append(source_fmt)
            else:
                source_string = safe_get_nested_data(item, ['SourceString'])
                if source_string:
                    all_descriptions.append(source_string)
        return all_descriptions

    source_fmt = safe_get_nested_data(desc_field, ['SourceFmt', 'LocalizedString'])
    if source_fmt:
        arguments = safe_get_nested_data(desc_field, ['Arguments'], [])
        if arguments:
            formatted_desc = source_fmt.format(*[arg['Value'] for arg in arguments])
            return [formatted_desc], [arg['Value'] for arg in arguments]
        else:
            return [source_fmt], []

    localized_string = safe_get_nested_data(desc_field, ['SourceString'])
    if localized_string:
        return [localized_string], []
    else:
        return [], []

def fill_skill_data(role_id, formatted_data, role_skill_data):
    """填充主动与被动技能名字喵"""
    role_skills = role_skill_data.get(role_id, None)
    if role_skills:
        active_skills = role_skills.get("主动技能", [])
        passive_skills = role_skills.get("被动技能", [])

        for skill in active_skills:
            formatted_data["主动技能"]["name"] = skill.get("name", "")

        for skill in passive_skills:
            formatted_data["被动技能"]["name"] = skill.get("name", "")

def process_growth_data(mode_name, json_filename, page_title):
    """
    高度模块化的通用数据处理逻辑
    :param mode_name: 模式中文名称 (如 '爆破')
    :param json_filename: 数据源 JSON 键名 (如 'Growth_Bomb')
    :param page_title: 目标 WIKI 页面路径
    """
    print(f"开始处理弦能增幅网络{mode_name}模式数据...")

    # 获取成就源数据
    growth_data = load_json_file(json_filename)

    # 读取角色技能数据
    skill_file_path = os.path.join(PROJECT_ROOT, 'data', 'RoleSkill.json')
    role_skill_data = {}
    try:
        with open(skill_file_path, 'r', encoding='utf-8') as file:
            role_skill_data = json.load(file)
    except FileNotFoundError:
        print("未找到 角色技能.json，将跳过技能名填充喵~")

    output_data = {}

    for item in growth_data:
        for row in item['Rows'].values():
            role_id = id_to_Role_name.get(row['RoleId'], row['RoleId'])

            # 获取 QDesc 和 PassiveDesc，并进行格式化
            q_desc_1, q_desc_2 = [], []
            if len(row.get('QDesc', [])) > 0:
                q_desc_1, _ = format_desc_field(row['QDesc'][0])
            if len(row.get('QDesc', [])) > 1:
                q_desc_2, _ = format_desc_field(row['QDesc'][1])

            passive_desc_1, passive_desc_2 = [], []
            if len(row.get('PassiveDesc', [])) > 0:
                passive_desc_1, _ = format_desc_field(row['PassiveDesc'][0])
            if len(row.get('PassiveDesc', [])) > 1:
                passive_desc_2, _ = format_desc_field(row['PassiveDesc'][1])

            # 提取与组织数据（利用 get 规避潜在的 KeyError）
            formatted_data = {
                "Parts1": {
                    "name": safe_get_nested_data(row, ['PartName', 0, 'LocalizedString']),
                    "need": row.get('Parts1Need', ''),
                    "desc": [safe_get_nested_data(row, ['Part1Desc', 0, 'LocalizedString']),
                            safe_get_nested_data(row, ['Part1Desc', 1, 'LocalizedString'])]
                },
                "Parts2": {
                    "name": safe_get_nested_data(row, ['PartName', 1, 'LocalizedString']),
                    "need": row.get('Parts2Need', ''),
                    "desc": [safe_get_nested_data(row, ['Part2Desc', 0, 'LocalizedString']),
                            safe_get_nested_data(row, ['Part2Desc', 1, 'LocalizedString'])]
                },
                "Parts4": {
                    "name": safe_get_nested_data(row, ['PartName', 2, 'LocalizedString']),
                    "need": row.get('Parts4Need', ''),
                    "desc": [safe_get_nested_data(row, ['Part4Desc', 0, 'LocalizedString']),
                            safe_get_nested_data(row, ['Part4Desc', 1, 'LocalizedString'])]
                },
                "Parts5": {
                    "name": safe_get_nested_data(row, ['PartName', 3, 'LocalizedString']),
                    "need": row.get('Parts5Need', ''),
                    "desc": [safe_get_nested_data(row, ['Part5Desc', 0, 'LocalizedString']),
                            safe_get_nested_data(row, ['Part5Desc', 1, 'LocalizedString'])]
                },
                "护甲": {
                    "name": "护甲",
                    "need": row.get('ShieldNeed', ''),
                    "desc": [safe_get_nested_data(row, ['ShieldDesc', 0, 'LocalizedString']),
                             safe_get_nested_data(row, ['ShieldDesc', 1, 'LocalizedString'])]
                },
                "弦化": {
                    "name": "弦化",
                    "need": row.get('SurviveNeed', ''),
                    "desc": [
                        safe_get_nested_data(row, ['SurviveDesc', 0, 'SourceFmt', 'LocalizedString']).format(safe_get_nested_data(row, ['SurviveDesc', 0, 'Arguments', 0, 'Value'])),
                        safe_get_nested_data(row, ['SurviveDesc', 1, 'SourceFmt', 'LocalizedString']).format(safe_get_nested_data(row, ['SurviveDesc', 1, 'Arguments', 0, 'Value']))
                    ]
                },
                "主动技能": {
                    "name": "",
                    "need": row.get('QNeed', ''),
                    "desc": q_desc_1 + q_desc_2
                },
                "被动技能": {
                    "name": "",
                    "need": row.get('PassiveNeed', ''),
                    "desc": passive_desc_1 + passive_desc_2
                },
                "技能觉醒": {
                    "ArousalUnlock": row.get('ArousalUnlock', ''),
                    "Active1Need": row.get('Arousal1ActivateNeed', ''),
                    "Active2Need": row.get('Arousal2ActivateNeed', ''),
                    "Active3Need": row.get('Arousal3ActivateNeed', '')
                }
            }

            fill_skill_data(role_id, formatted_data, role_skill_data)
            output_data[role_id] = formatted_data

    # 1. 借用 common.py 将字典转化为标准的 Lua 格式字符串
    lua_content = format_lua_table(output_data)

    # 2. 借用 common.py 导出数据并自动备份
    file_name = f"Growth_{mode_name}"
    export_data_file(file_name, lua_content, fileType='lua')

    # 3. 构建本地输出路径以上传到 WIKI
    lua_file_path = os.path.join(PROJECT_ROOT, "data", f"{file_name}.lua")
    upload_wiki_data(page_title, lua_file_path)


# ----------------- 提供给外部调用的三个模式接口 -----------------

def export_growth_bomb_data():
    process_growth_data("爆破", "Growth_Bomb", "模块:弦能增幅网络3/BombData")

def export_growth_escort_data():
    process_growth_data("极限推进", "Growth_Escort", "模块:弦能增幅网络3/EscortData")

def export_growth_hotzone_data():
    process_growth_data("弦区争夺", "Growth_HotZone", "模块:弦能增幅网络3/HotZoneData")
