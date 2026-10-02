# modules/generate_role_skill.py
from utils.common import id_to_Role_name, load_json_file, save_data_file, format_lua_table, upload_wiki_data

def export_role_skill_data():
    print("开始处理角色技能数据...")
    custom_keys = {
        "SkillActive": "主动技能",
        "SkillPassive": "被动技能",
        "SkillUltimate": "终极技能",
        "SkillActivetwo": "战术技能",
        "SkillWake": "技能觉醒"
    }

    # 从 JSON 文件中加载角色数据
    Role_Skill_data = load_json_file("Role")
    skill_data = load_json_file("skill")

    # 创建从技能ID到本地化名称和介绍信息的映射
    skill_id_to_info = {}
    for skill_id, skill_info in skill_data[0]["Rows"].items():
        skill_id_to_info[int(skill_id)] = {
            "Name": skill_info["Name"]["LocalizedString"],
            "Intro": skill_info.get("Intro", {}).get("LocalizedString", ""),
        }

    output_data = {}

    # 处理每一行角色数据
    for item in Role_Skill_data:
        for row in item['Rows'].values():
            role_name = id_to_Role_name.get(row.get('RoleId', 0), row.get('RoleId', ''))

            # 提取需要的部分数据
            extracted_data = {
                "SkillActive": row['SkillActive'],
                "SkillPassive": row['SkillPassive'],
                "SkillUltimate": row['SkillUltimate'],
                "SkillActivetwo": row['SkillActivetwo'],
                "SkillWake": row['SkillWake']
            }

            # 将技能 ID 转换为技能名称和介绍信息，并添加ActiveCond数据
            custom_data = {}
            for key, value in custom_keys.items():
                skill_ids = extracted_data.get(key, [])
                skill_details = [{
                    "name": skill_id_to_info[skill_id]["Name"],
                    "desc": skill_id_to_info[skill_id]["Intro"],
                } for skill_id in skill_ids if skill_id in skill_id_to_info]
                custom_data[value] = skill_details

            output_data[role_name] = custom_data

    save_data_file("RoleSkill", output_data, fileType='json')
    save_data_file("RoleSkill", format_lua_table(output_data), fileType='lua')
    upload_wiki_data( '模块:角色/SkillData', '.\\data\\RoleSkill.lua' )
