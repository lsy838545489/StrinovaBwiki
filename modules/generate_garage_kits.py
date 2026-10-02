# modules/generate_garage_kits.py
import os
from utils.common import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT


def export_garage_kits_data():
    print("开始处理休息室手办(GarageKits)数据喵...")

    # 自定义键映射
    custom_keys = {
        "ID": "id",
        "Name": "name",
        "Quality": "quality",
        "Desc": "desc"
    }

    source_data = load_json_file("Item")
    if not source_data:
        return

    output_data = []
    get_mapping = {}

    # 处理 Emote_data 中的每一项
    for item in source_data:
        for row in item['Rows'].values():
            ID = row["Id"]

            if ID < 70000 or ID > 79999:
                continue

            get_mapping[ID] = ""

            Desc_string = row['Desc'].get(
                'LocalizedString', '').replace('\n', '')

            extracted_data = {
                "ID": ID,
                "Name": row['Name'].get('LocalizedString', ''),
                "Quality": row['Quality'],
                "Desc": Desc_string
            }

            # 将提取的数据映射到自定义键
            custom_data = {
                custom_keys[key]: value for key, value in extracted_data.items()}
            output_data.append(custom_data)

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("GarageKits", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 GarageKits_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            id = item.get("id")
            if id in get_mapping:
                added_get_data[id] = get_mapping[id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data")
            _save_lua_only(data_dir, "GarageKits_Get_Added", added_get_data)
            print(f"✨ [GarageKits] 已将 {len(added_get_data)} 条新增数据的获得方式单独输出至 data/GarageKits_Get_Added.lua 喵！")

    print("休息室手办(GarageKits)数据处理完成喵！")
