# modules/generate_weapon_skin.py
# 从 utils 模块导入需要的变量和函数
from utils.common import id_to_Weapon_name, load_json_file, export_data_file, format_lua_table

def export_weapon_skin_data():
    print("开始处理武器外观数据...")
    # 自定义键名
    custom_keys = {
        "id": "id",
        "Quality": "稀有度",
        "Get": "获得方式",
        "BabloCrystals": "巴布洛晶核",
        "Basestrings": "基弦",
        "LocalizedString": "简介",
        "Desc": "备注"
    }

    Weapon_data = load_json_file("Weapon")

    output_data = {}
    for item in Weapon_data:
        for row in item['Rows'].values():
            skin_Id = row['Id']
            weapon_name = row['BlueprintDir']
            if weapon_name in id_to_Weapon_name:
                weapon_id = id_to_Weapon_name[weapon_name]
            else:
                continue

            gain_param2 = row.get('GainParam2', {})  # 获取 GainParam2 字典，如果不存在则返回空字典
            gain_param2_key = gain_param2.get('Key', '')  # 获取 Key 键，如果不存在则返回空字符串
            gain_param2_value = gain_param2.get('LocalizedString', '')  # 获取 LocalizedString 键，如果不存在则返回空字符串
            get_methods = []
            if gain_param2_value:
                get_methods = [gain_param2_value]

            # 将稀有度ID替换为对应的稀有度名称
            Quality_name = row['Quality']

            skin_localized_string = row['Tips'].get('LocalizedString', '').replace('\n', '<br />').replace('"', "'")
            SkinName_string = row['Name'].get('LocalizedString', '').replace('—', '-')

            skin_data = {
                custom_keys["id"]: skin_Id,
                custom_keys["Quality"]: Quality_name,
                custom_keys["Get"]: get_methods,
                custom_keys["BabloCrystals"]: "",
                custom_keys["Basestrings"]: "",
                custom_keys["LocalizedString"]: skin_localized_string,
                custom_keys["Desc"]: ""
            }
            # 如果 Quality 等于 2，则设置 "BabloCrystals" 和 "Basestrings" 的值为 480
            if gain_param2_value == "限时商城":
                skin_data[custom_keys["BabloCrystals"]] = 980
                skin_data[custom_keys["Basestrings"]] = ""
            elif gain_param2_value == "特别行动":
                skin_data[custom_keys["BabloCrystals"]] = ""
                skin_data[custom_keys["Basestrings"]] = ""
            else:
                if Quality_name == 2 and gain_param2_value == "":
                    skin_data[custom_keys["BabloCrystals"]] = 150
                    skin_data[custom_keys["Basestrings"]] = 150
                elif Quality_name == 3 and gain_param2_value == "":
                    skin_data[custom_keys["BabloCrystals"]] = 480
                    skin_data[custom_keys["Basestrings"]] = 480
                elif Quality_name == 4 and gain_param2_value == "":
                    skin_data[custom_keys["BabloCrystals"]] = 980
                    skin_data[custom_keys["Basestrings"]] = 980
                else:
                    skin_data[custom_keys["BabloCrystals"]] = ""
                    skin_data[custom_keys["Basestrings"]] = ""

                if Quality_name == 5 and "-" in SkinName_string:
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
            if weapon_id not in output_data:
                output_data[weapon_id] = {}
            output_data[weapon_id][SkinName_string] = skin_data

    export_data_file("weapon_Skin", output_data, fileType='json')
    export_data_file("weapon_Skin", format_lua_table(output_data), fileType='lua')
    print("武器外观数据处理完成喵！\n")
