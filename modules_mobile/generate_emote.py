# modules_mobile/generate_emote.py
import os
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, DATA_ROOT


def export_emote_data():
    print("开始处理表情(Emote)数据喵...")

    id_to_Role_name = {
        20101001: "米雪儿·李",
        20105001: "奥黛丽·格罗夫",
        20107001: "玛德蕾娜·利里",
        20108001: "信",
        20109001: "令",
        20110001: "白墨",
        20112001: "绯莎",
        20115001: "芙拉薇娅",
        20119001: "艾卡",
        20120001: "珐格兰丝",
        20121001: "忧雾",
        20122001: "玛拉",
        20123001: "蕾欧娜",
        20124001: "心夏",
        20125001: "千代",
        20128001: "拉薇",
        20130001: "汐",
        20131001: "伊薇特",
        20132001: "明",
        20133001: "梅瑞狄斯",
        20137001: "香奈美",
        20146001: "星绘",
        20205001: "加拉蒂亚·利里",
        20101201: "米雪儿·李",
        20128201: "拉薇",
        20131201: "伊薇特",
        20124201: "心夏",
        20105201: "奥黛丽·格罗夫",
        20107201: "玛德蕾娜·利里",
        20112201: "绯莎",
        20133201: "梅瑞狄斯",
        20137201: "香奈美",
        20146201: "星绘",
    }

    # 自定义键映射
    custom_keys = {
        "ID": "id",
        "Name": "name",
        "Role": "role",
        "Quality": "quality",
        "File": "file",
        "Desc": "desc"
    }

    Emote_data = load_json_file("Emote")
    if not Emote_data:
        return

    output_data = []
    get_mapping = {}

    # 处理 Emote_data 中的每一项
    for item in Emote_data:
        for row in item['Rows'].values():
            ID = row["Id"]

            gain_param2 = row.get('GainParam2', {})
            raw_get_str = gain_param2.get(
                'LocalizedString', '')
            gain_param2_value = [raw_get_str] if raw_get_str else []
            get_mapping[ID] = gain_param2_value

            asset_path_name = row['IconItem'].get('AssetPathName', '')
            tail_number = asset_path_name.split('.')[-1].split('_')[-1]

            Desc_string = row['Desc'].get(
                'LocalizedString', '').replace('\n', '')

            Role_id = id_to_Role_name.get(
                row.get('RoleSkinId', 0), row.get('RoleSkinId', ''))

            extracted_data = {
                "ID": ID,
                "Name": row['Name'].get('LocalizedString', ''),
                "Role": Role_id,
                "Quality": row['Quality'],
                "File": f"表情移动端_{tail_number}.png",
                "Desc": Desc_string
            }

            # 将提取的数据映射到自定义键
            custom_data = {
                custom_keys[key]: value for key, value in extracted_data.items()}
            output_data.append(custom_data)

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("Emote", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 Emote_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            Emote_id = item.get("id")
            if Emote_id in get_mapping:
                added_get_data[Emote_id] = get_mapping[Emote_id]

        if added_get_data:
            data_dir = os.path.join(DATA_ROOT, "data_mobile")
            _save_lua_only(data_dir, "Emote_Get_Added", added_get_data)
            print(f"✨ [Emote] 已将 {len(added_get_data)} 条新增数据的获得方式单独输出至 data_mobile/Emote_Get_Added.lua 喵！")

    print("表情(Emote)数据处理完成喵！")
