# modules/generate_achievement.py
import os
# 从 utils 导入
from utils.common import id_to_Role_name, load_json_file, upload_wiki_data, format_lua_table, save_data_file


def export_achievement_data():
    print("开始处理成就和印迹数据...")
    # 定义 Type 和 Quality 的映射
    Type_to_id = {
        1: "战斗勋章",
        3: "荣耀成就",
        4: "光辉事迹"
    }

    # 自定义键名映射
    custom_keys = {
        "Id": "id",
        "Name": "name",
        "Level": "level",
        "Type": "type",
        "Quality": "quality",
        "File": "file",
        "Get": "get",
        "Desc": "desc"
    }

    custom_keys_role = {
        "Id": "id",
        "Name": "name",
        "Level": "level",
        "Role": "role",
        "Quality": "quality",
        "File": "file",
        "Get": "get",
        "Desc": "desc"
    }

    Achievement_data = load_json_file("Achievement")
    if not Achievement_data:
        print("未获取到 Achievement 数据，跳过处理喵。")
        return

    output_data = []
    output_data_role = []

    # 处理数据
    for item in Achievement_data:
        for row in item['Rows'].values():
            AchievementID = row['Id']

            Quality_id = row['Quality']

            explain_localized = row['Explain']['LocalizedString'].replace(
                '<Chat-Self>', '').replace('</>', '')
            param2_value = row['Param2'][0]

            Achievement_Get = explain_localized.format(
                param2_value).replace(' ', '')

            if row['Type'] != 5:
                Type_name = row['Type']
                if Type_name in Type_to_id:
                    Type_id = Type_to_id[Type_name]
                else:
                    Type_id = Type_name

                extracted_data = {
                    "Id": AchievementID,
                    "Name": row['Name'].get('LocalizedString', ''),
                    "Level": row['Level'],
                    "Type": Type_id,
                    "Quality": Quality_id,
                    "File": f"勋章_{AchievementID}.png",
                    "Get": Achievement_Get,
                    "Desc": row['Details'].get('LocalizedString', '')
                }
                custom_data = {
                    custom_keys[key]: value for key, value in extracted_data.items()}
                output_data.append(custom_data)

            elif row['Type'] == 5:
                role_name = row['Role']
                if role_name in id_to_Role_name:
                    role_id = id_to_Role_name[role_name]
                else:
                    role_id = "全员"

                extracted_data = {
                    "Id": AchievementID,
                    "Name": row['Name'].get('LocalizedString', ''),
                    "Level": row['Level'],
                    "Role": role_id,
                    "Quality": Quality_id,
                    "File": f"勋章_{AchievementID}.png",
                    "Get": Achievement_Get,
                    "Desc": row['Details'].get('LocalizedString', '')
                }
                custom_data = {
                    custom_keys_role[key]: value for key, value in extracted_data.items()}
                output_data_role.append(custom_data)

    # 保存成就数据到Lua文件
    save_data_file("Achievement", output_data, fileType='json')
    save_data_file("Achievement", format_lua_table(output_data), fileType='lua')
    save_data_file("RoleAchievement", output_data_role, fileType='json')
    save_data_file("RoleAchievement", format_lua_table(output_data_role), fileType='lua')

    upload_wiki_data('模块:成就印迹/AchievementData', '.\\data\\Achievement.lua')
    upload_wiki_data('模块:成就印迹/RoleAchievementData', '.\\data\\RoleAchievement.lua')
    print("成就与印迹数据更新完毕喵！")
