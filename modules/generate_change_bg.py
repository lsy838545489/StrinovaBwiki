# modules/generate_change_bg.py
import os
from utils.common import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT


def export_change_background_data():
    print("开始处理房间背景(ChangeBackground)数据喵...")
    custom_keys = {
        "ID": "id",
        "Name": "name",
        "Quality": "quality",
        "Desc": "desc",
    }

    ChangeBackground_data = load_json_file("Item")
    if not ChangeBackground_data:
        return

    output_data = []
    get_mapping = {}
    for item in ChangeBackground_data:
        for row in item["Rows"].values():
            ID = row["Id"]
            if not (93000 < ID < 93999):
                continue

            gain_param2 = row.get("GainParam2", {})
            raw_get_str = gain_param2.get("LocalizedString", "")
            gain_param2_value = [raw_get_str] if raw_get_str else []
            get_mapping[ID] = gain_param2_value

            item_localized_string = (
                row["Desc"].get("LocalizedString", "").replace("\n", "<br />")
            )

            extracted_data = {
                "ID": ID,
                "Name": row["Name"].get("LocalizedString", ""),
                "Quality": row["Quality"],
                "Desc": item_localized_string,
            }

            # 将提取的数据映射到自定义键
            custom_data = {
                custom_keys[key]: value for key, value in extracted_data.items()
            }
            output_data.append(custom_data)

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("ChangeBg", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 ChangeBg_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            ChangeBg_id = item.get("id")
            if ChangeBg_id in get_mapping:
                added_get_data[ChangeBg_id] = get_mapping[ChangeBg_id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data")
            _save_lua_only(data_dir, "ChangeBg_Get_Added", added_get_data)
            print(f"✨ [ChangeBg] 已将 {len(added_get_data)} 条新增数据的获得方式单独输出至 data/ChangeBg_Get_Added.lua 喵！")
    print("房间背景(ChangeBackground)数据处理完成喵！")
