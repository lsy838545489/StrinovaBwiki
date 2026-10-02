# modules/generate_growth_weapon.py
import json
import os

# 直接从 common.py 导入各种超好用的工具函数喵！
from utils.common import (
    Weapon_id_to_cn_name,
    load_json_file,
    upload_wiki_data,
    format_lua_table,
    save_data_file,
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

def build_part_info(row, part_index, desc_prefix):
    """提取单个 Part 的数据，并根据有效 desc 数量自动填充 need 列表喵"""
    name = safe_get_nested_data(row, ['PartName', part_index, 'LocalizedString'])

    # 获取原始描述列表并过滤掉空文本
    raw_desc = [
        safe_get_nested_data(row, [f'{desc_prefix}Desc', 0, 'LocalizedString']),
        safe_get_nested_data(row, [f'{desc_prefix}Desc', 1, 'LocalizedString'])
    ]
    descs = [d for d in raw_desc if d]

    return {
        "name": name,
        "need": [150] * len(descs),
        "desc": descs
    }

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

    output_data = {}

    for item in growth_data:
        for row in item['Rows'].values():
            weapon_id = Weapon_id_to_cn_name.get(row['WeaponId'], row['WeaponId'])

            # 提取与组织数据（调用辅助函数自动处理 need 和 desc）
            formatted_data = {
                "Parts1": build_part_info(row, 0, "Part1"),
                "Parts2": build_part_info(row, 1, "Part2"),
                "Parts4": build_part_info(row, 2, "Part4"),
                "Parts5": build_part_info(row, 3, "Part5"),
            }

            output_data[weapon_id] = formatted_data

    # 1. 借用 common.py 将字典转化为标准的 Lua 格式字符串
    lua_content = format_lua_table(output_data)

    # 2. 借用 common.py 导出数据并自动备份
    file_name = f"Growth_{mode_name}"
    save_data_file(file_name, lua_content, fileType='lua')

    # 3. 构建本地输出路径以上传到 WIKI
    lua_file_path = os.path.join(PROJECT_ROOT, "data", f"{file_name}.lua")
    upload_wiki_data(page_title, lua_file_path)


# ----------------- 提供给外部调用的三个模式接口 -----------------

def export_growth_bomb_weapon_data():
    process_growth_data("爆破武器", "GrowthWeapon_Bomb", "模块:弦能增幅网络3/BombWeaponData")
