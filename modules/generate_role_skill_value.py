# modules/generate_role_skill_value.py
import os
import json
from collections import defaultdict

from utils.common import load_json_file, en_to_cn_name, DATA_ROOT

Grenade_string = {
    "Grenade": "手雷",
    "GrenadeFlash": "闪光弹",
    "GrenadeSlowDown": "减速雷",
    "GrenadeSmoke": "烟雾弹",
    "GrenadeWindField": "风场雷",
    "GrenadeTreatment": "治疗雷",
    "GrenadeInterceptor": "拦截者",
    "GrenadeAlarm": "警报器"
}


def find_text_by_name(skill_string_data, target_name):
    """
    在数据列表中查找指定 name 对应的 text 值
    :param skill_string_data: 包含字典的列表，每个字典有 name 和 text 键
    :param target_name: 要查找的 name 值
    :return: 匹配的 text 值，未找到返回空字符串
    """
    for item in skill_string_data:
        if item["name"] == target_name:
            return item["text"]
    return ""


def process_level_attribute_data(LevelAttribute_data, skill_string_data):
    """处理 LevelAttribute 数据并返回整理后的字典
    规则：
    1. 检查属性名的每一部分，只要发现可翻译内容立即使用
    2. 完全找不到翻译时，使用最后一段作为键名
    3. 保留原始属性名作为子键
    """
    processed_data = defaultdict(list)

    for row_name, row_data in LevelAttribute_data[0]["Rows"].items():
        if not row_data.get("Keys"):
            continue

        # 按原始顺序提取不同的 Value 值
        seen_values = set()
        ordered_values = []
        for key in row_data["Keys"]:
            value = key["Value"]
            if value not in seen_values:
                seen_values.add(value)
                ordered_values.append(value)

        row_name_last = row_name.split('.')[-1]
        # 扫描所有部分寻找可翻译内容
        role_key = None
        for part in row_name.split('.'):
            if part in en_to_cn_name:
                role_key = en_to_cn_name[part]
                break

        if row_name_last in Grenade_string:
            row_name_cn = Grenade_string[row_name_last]
        else:
            row_name_cn = find_text_by_name(skill_string_data, row_name)

        if role_key is None:
            role_key = row_name_last

        extracted_data = {
            "name": row_name,
            "name_cn": row_name_cn,
            "value": ordered_values
        }

        processed_data[role_key].append(extracted_data)

    return dict(processed_data)


def export_to_json(data, output_path):
    """导出数据到 JSON 文件"""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)


def export_role_skill_value_data():
    print("开始处理角色技能数值(RoleSkillValue)数据喵...")

    out_dir = os.path.join(DATA_ROOT, "模式技能数值")
    os.makedirs(out_dir, exist_ok=True)

    # 加载数据
    SkillToAttribute_Data = load_json_file("Growth_SkillToAttribute")
    ST_GrowthDefine_Data = load_json_file("ST_GrowthDefine")
    Bomb_Data = load_json_file("CT_LevelAttribute")
    Escort_Data = load_json_file("CT_LevelAttribute_Escort")
    HotZone_Data = load_json_file("CT_LevelAttribute_HotZone")
    Zombie_Data = load_json_file("CT_LevelAttribute_Zombie")
    GunGame_Data = load_json_file("CT_LevelAttribute_GunGame")
    Mine_Data = load_json_file("CT_LevelAttribute_Mine")

    if not SkillToAttribute_Data or not ST_GrowthDefine_Data:
        print("未加载到技能属性或字符串表数据，跳过导出喵。")
        return

    string_table = ST_GrowthDefine_Data[0]["StringTable"]["KeysToEntries"]

    # 构建 属性名 -> 中文文本 的映射清单
    skill_string_data = []
    for item in SkillToAttribute_Data:
        for row in item['Rows'].values():
            for attribute in row['AttributeInfo']:
                text = attribute['text']
                if isinstance(text, list):
                    # 如果 text 是列表，逐个翻译；未找到则保留原文本
                    text_CN = [string_table.get(t, t) for t in text]
                else:
                    # 如果 text 是单个字符串，直接翻译
                    text_CN = string_table.get(text, text)

                skill_string_data.append({
                    "name": attribute['name'],
                    "text": text_CN
                })

    export_to_json(skill_string_data, os.path.join(out_dir, "技能字符串.json"))
    print(f"  技能字符串.json 已导出，共 {len(skill_string_data)} 条喵")

    # 各模式对应的 LevelAttribute 源数据
    mode_sources = {
        '爆破': Bomb_Data,
        '极限推进': Escort_Data,
        '弦区争夺': HotZone_Data,
        '晶能冲突': Mine_Data,
        '晶源感染': Zombie_Data,
        '枪王乱斗': GunGame_Data,
    }

    for mode_name, mode_data in mode_sources.items():
        if not mode_data:
            print(f"  未加载到{mode_name}的 LevelAttribute 数据，跳过喵。")
            continue
        processed = process_level_attribute_data(mode_data, skill_string_data)
        export_to_json(processed, os.path.join(out_dir, f"{mode_name}技能数值.json"))
        print(f"  {mode_name}技能数值.json 已导出，共 {len(processed)} 个角色键喵")

    print("角色技能数值(RoleSkillValue)数据处理完成喵！")


if __name__ == "__main__":
    export_role_skill_value_data()
