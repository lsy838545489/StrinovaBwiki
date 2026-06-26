# modules/generate_role_skin.py
import os

# 从 utils 模块导入需要的变量和函数
from utils.common import id_to_Role_name, load_json_file, export_data_file, format_lua_table


def export_role_skin_data():
    print("开始处理角色时装数据...")
    # 自定义键名
    custom_keys = {
        "ID": "id",
        "Quality": "稀有度",
        "Get": "获得方式",
        "BabloCrystals": "巴布洛晶核",
        "Basestrings": "基弦",
        "LocalizedString": "简介",
        "Desc": "备注",
    }

    RoleSkin_data = load_json_file("RoleSkin")

    if not RoleSkin_data:
        print("未获取到 RoleSkin 数据，跳过处理喵。")
        return
    # 提取所需字段并保存为 gbk 编码的角色时装.lua 文件
    output_data = {}
    for item in RoleSkin_data:
        for row in item["Rows"].values():
            skin_Id = row["RoleSkinId"]
            role_id = row["RoleId"]
            skin_name = row["NameCn"]["LocalizedString"].replace("—", "-")
            if role_id != 901:
                gain_param2 = row.get(
                    "GainParam2", {}
                )  # 获取 GainParam2 字典，如果不存在则返回空字典
                gain_param2_value = gain_param2.get(
                    "LocalizedString", ""
                )  # 获取 LocalizedString 键，如果不存在则返回空字符串

                # 将获取方式转换为数组形式
                get_methods = []
                if gain_param2_value:
                    get_methods = [gain_param2_value]

                # 将角色ID替换为对应的角色名称
                if role_id in id_to_Role_name:
                    role_name = id_to_Role_name[role_id]
                else:
                    role_name = role_id  # 如果找不到匹配的角色ID，则保留原始值

                # 将稀有度ID替换为对应的稀有度名称
                Quality_name = row["Quality"]

                skin_localized_string = (
                    row["Description"]
                    .get("LocalizedString", "")
                    .replace("\n", "<br />")
                    .replace('"', "'")
                )

                skin_data = {
                    custom_keys["ID"]: skin_Id,
                    custom_keys["Quality"]: Quality_name,
                    custom_keys["Get"]: get_methods,
                    custom_keys["BabloCrystals"]: "",
                    custom_keys["Basestrings"]: "",
                    custom_keys["LocalizedString"]: skin_localized_string,
                    custom_keys["Desc"]: "",
                }
                # 如果 Quality 等于 2，则设置 "BabloCrystals" 和 "Basestrings" 的值为 480
                if Quality_name == 2 and not gain_param2_value:
                    skin_data[custom_keys["BabloCrystals"]] = 150
                    skin_data[custom_keys["Basestrings"]] = 150
                elif Quality_name == 3 and not gain_param2_value:
                    skin_data[custom_keys["BabloCrystals"]] = 480
                    skin_data[custom_keys["Basestrings"]] = 480
                elif Quality_name == 4 and not gain_param2_value:
                    skin_data[custom_keys["BabloCrystals"]] = 1280
                    skin_data[custom_keys["Basestrings"]] = 1280
                else:
                    skin_data[custom_keys["BabloCrystals"]] = ""
                    skin_data[custom_keys["Basestrings"]] = ""

                if Quality_name == 5 and "-" in skin_name:
                    keys_to_remove = [
                        custom_keys["Get"],
                        custom_keys["BabloCrystals"],
                        custom_keys["Basestrings"],
                        custom_keys["LocalizedString"],
                        custom_keys["Desc"]
                    ]
                    for key in keys_to_remove:
                        skin_data.pop(key, None)

                # 将键名替换为自定义键名
                if role_name not in output_data:
                    output_data[role_name] = {}
                output_data[role_name][skin_name] = skin_data

    export_data_file("Role_Skin", output_data, fileType='json')
    export_data_file("Role_Skin", format_lua_table(output_data), fileType='lua')
    print("角色时装数据处理完成喵！\n")
