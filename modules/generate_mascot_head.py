# modules/generate_mascot_head.py
import os
from utils.common import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT


def export_mascot_head_data():
    print("开始处理头套（Mascot Head）数据喵...")

    custom_keys = {
        "id": "id",
        "name": "name",
        "quality": "quality",
        "desc": "desc"
    }

    MascotHead_data = load_json_file("RoleMascotHeads")
    if not MascotHead_data:
        return

    output_data = []
    get_mapping = {}
    for item in MascotHead_data:
        for row in item['Rows'].values():
            ID = row['Id']

            gain_param2 = row.get('GainParam2', {})
            raw_get_str = gain_param2.get('LocalizedString', '')
            gain_param2_value = [raw_get_str] if raw_get_str else []
            get_mapping[ID] = gain_param2_value

            Quality_name = row['Quality']

            Desc_string = row['Desc'].get('LocalizedString', '').replace(
                '\n', '').replace('【头套】', '')

            extracted_data = {
                "id": ID,
                "name": row['Name'].get('LocalizedString', ''),
                "quality": Quality_name,
                "desc": Desc_string
            }
            custom_data = {
                custom_keys[key]: value for key, value in extracted_data.items()}

            output_data.append(custom_data)

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("MascotHead", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 MascotHead_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            id = item.get("id")
            if id in get_mapping:
                added_get_data[id] = get_mapping[id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data")
            _save_lua_only(data_dir, "MascotHead_Get_Added", added_get_data)
            print(f"✨ [MascotHead] 已将 {len(added_get_data)} 条新增数据单独输出至 data/MascotHead_Get_Added.lua 喵！")
    print("头套（MascotHead）数据处理完成喵！")
