# modules_mobile/generate_favorability.py
from utils.common_mobile import load_json_file, save_and_diff_data

id_to_role_name = {
    101: "米雪儿·李",
    105: "奥黛丽·格罗夫",
    107: "玛德蕾娜·利里",
    112: "绯莎",
    124: "心夏",
    128: "拉薇",
    131: "伊薇特",
    137: "香奈美",
    146: "星绘"
}

custom_keys = {
    "Name": "Name",
    "Quality": "Quality",
    "Activities": "Activities",
    "File": "File",
    "Desc": "Desc_string"
}


def export_favorability_data():
    print("开始处理角色礼物好感度(Favorability)数据喵...")

    Gift_data = load_json_file("Item")
    Favorability_data = load_json_file("RoleFavorabilityGiftPresent")
    if not Gift_data or not Favorability_data:
        return

    # 礼物ID -> 好感度信息
    Favorability_id_to_info = {}
    for Favorability_id, Favorability_info in Favorability_data[0]["Rows"].items():
        Favorability_id_to_info[int(Favorability_id)] = {
            "RoleId": Favorability_info["RoleId"],
            "Gift": Favorability_info["Gift"],
            "LikeLevel": Favorability_info["LikeLevel"],
            "Favorability": Favorability_info["Favorability"]
        }

    output_data = {}

    # 处理 Gift 数据
    for item in Gift_data:
        for row in item['Rows'].values():
            gift_id = row.get('Id', 0)
            Quality_id = row.get('Quality', '')
            # 仅处理 30001-30999 范围并且 Quality != 1
            # 注：源数据里的 Quality 本身就是整数（0/2/3/4/5），无需再做名称映射
            if 30001 <= gift_id <= 30999 and Quality_id != 1:

                Activitie = True if 30036 <= gift_id <= 30100 else False

                asset_path_name = row.get('IconItem', {}).get('AssetPathName', '') or ''
                tail_number = ''
                if asset_path_name:
                    tail_number = asset_path_name.split('_')[-1].split('.')[0]

                extracted_data = {
                    "Name": row.get('Name', {}).get('LocalizedString', ''),
                    "Quality": Quality_id,
                    "Activities": Activitie,
                    "File": f"礼物图标_{tail_number}.png" if tail_number else "",
                    "Desc": row.get('Desc', {}).get('LocalizedString', ''),
                    "GiftID": gift_id
                }

                # 按照 custom_keys 创建自定义数据（并保留 GiftID）
                custom_data = {}
                for src_key, out_key in custom_keys.items():
                    if src_key in extracted_data:
                        custom_data[out_key] = extracted_data[src_key]
                custom_data["GiftID"] = gift_id

                # 查找 Favorability 数据
                favorability = {}
                like_level = {}
                for favorability_info in Favorability_id_to_info.values():
                    if favorability_info["Gift"] == gift_id:
                        role_name = id_to_role_name.get(favorability_info["RoleId"], None)
                        if role_name:
                            favorability[role_name] = favorability_info["Favorability"]
                            like_level[role_name] = favorability_info["LikeLevel"]

                # 只将有有效角色数据的礼物添加到输出数据
                if favorability or like_level:
                    if favorability:
                        custom_data["Favorability"] = favorability
                    if like_level:
                        custom_data["LikeLevel"] = like_level
                    output_data[gift_id] = custom_data

    # 对比并保存主数据表（全量与增量）
    save_and_diff_data("Favorability", output_data)

    print("角色礼物好感度(Favorability)数据处理完成喵！")


if __name__ == "__main__":
    export_favorability_data()
