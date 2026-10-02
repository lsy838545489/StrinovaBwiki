# modules_mobile/generate_badge.py
import os
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT

def export_badge_data():
    print("开始处理徽章(Badge)数据喵...")

    custom_keys = {
        "ID": "id",
        "Name": "name",
        "Quality": "quality",
        "Desc_string": "desc",
    }

    Badge_data = load_json_file("Badge")
    if not Badge_data:
        return

    output_data = []
    # 存储临时获得方式字典：[id] = gain_param2_value
    get_mapping = {}

    for item in Badge_data:
        for row in item["Rows"].values():
            ID = row["Id"]

            # 1. 提取获得方式数据
            gain_param2 = row.get("GainParam2", {})
            raw_get_str = gain_param2.get("LocalizedString", "")
            gain_param2_value = [raw_get_str] if raw_get_str else []

            # 记录到临时映射集中，方便后续提取增量部分
            get_mapping[ID] = gain_param2_value

            Desc_string = row["Desc"].get("LocalizedString", "").replace("\n", "")

            extracted_data = {
                "ID": ID,
                "Name": row["Name"].get("LocalizedString", ""),
                "Quality": row["Quality"],
                "Desc_string": Desc_string,
            }
            custom_data = {
                custom_keys[key]: value for key, value in extracted_data.items()
            }

            output_data.append(custom_data)

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("Badge", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 Badge_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            Badge_id = item.get("id")
            if Badge_id in get_mapping:
                added_get_data[Badge_id] = get_mapping[Badge_id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data_mobile")
            _save_lua_only(data_dir, "Badge_Get_Added", added_get_data)
            print(f"✨ [Badge] 已将 {len(added_get_data)} 条新增数据的获得方式单独输出至 data_mobile/Badge_Get_Added.lua 喵！")

    print("徽章(Badge)数据处理完成喵！")
