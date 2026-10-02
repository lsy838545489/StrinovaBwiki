# modules_mobile/generate_vehicle_skin.py
import os
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT

def export_vehicle_skin_data():
    print("开始处理载具外观(VehicleSkin)数据喵...")

    custom_keys = {
        "id": "id",
        "name": "name",
        "quality": "quality",
        "spdesc": "spdesc",
        "desc": "desc"
    }

    item_data = load_json_file("VehicleSkin")

    output_data = []
    get_mapping = {}
    for item in item_data:
        for row in item['Rows'].values():
            ID = row['Id']

            gain_param2 = row.get("GainParam2", {})
            raw_get_str = gain_param2.get("LocalizedString", "")
            gain_param2_value = [raw_get_str] if raw_get_str else []
            get_mapping[ID] = gain_param2_value

            Desc_string = row['Desc'].get('LocalizedString', '').replace('\n\n', '<br>')

            extracted_data = {
                "id": ID,
                "name": row['Name'].get('LocalizedString', ''),
                "quality": row['Quality'],
                "spdesc": row['SpDesc'].get('LocalizedString', ''),
                "desc": Desc_string
            }
            custom_data = {custom_keys[key]: value for key, value in extracted_data.items()}

            output_data.append(custom_data)

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("VehicleSkin", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 VehicleSkin_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            item_id = item.get("id")
            if item_id in get_mapping:
                added_get_data[item_id] = get_mapping[item_id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data_mobile")
            _save_lua_only(data_dir, "VehicleSkin_Get_Added", added_get_data)
            print(f"✨ [VehicleSkin] 已将 {len(added_get_data)} 条新增数据的获得方式单独输出至 data_mobile/VehicleSkin_Get_Added.lua 喵！")

        print("载具外观(VehicleSkin)数据处理完成喵！")
