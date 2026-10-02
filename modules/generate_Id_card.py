# modules/generate_Id_card.py
import os
from utils.common import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT


def export_id_card_data():
    print("开始处理名片与边框数据喵...")
    custom_keys_avatar = {
        "ID": "id",
        "Name": "name",
        "Quality": "quality",
        "File": "file",
        "Img": "img",
        "Get": "get",
        "Desc": "desc"
    }

    custom_keys_frame = {
        "ID": "id",
        "Name": "name",
        "Quality": "quality",
        "File": "file",
        "Get": "get",
        "Desc": "desc"
    }

    IdCard_data = load_json_file("IdCard")
    if not IdCard_data:
        return
    output_data_avatar = []
    output_data_frame = []
    get_mapping = {}

    # 处理每个条目
    for item in IdCard_data:
        for row in item.get('Rows', {}).values():
            ID = row['Id']
            type_value = row.get('Type', '')

            gain_param2 = row.get('GainParam2', {})
            raw_get_str = gain_param2.get('LocalizedString', '')
            gain_param2_value = [raw_get_str] if raw_get_str else []
            get_mapping[ID] = gain_param2_value

            Icon_name = row.get('IconItem', {}).get('AssetPathName', '')
            tail_number1_1 = Icon_name.split('/')[-1].split('_')[-2]
            tail_number1_2 = Icon_name.split('/')[-1].split('_')[-1]

            Desc_string = row.get('Desc', {}).get(
                'LocalizedString', '').replace('\n', '')

            if type_value == "EPMCardResourceType::Avatar":
                Icon_Display_name = row.get(
                    'IconDisplayItem', {}).get('AssetPathName', '')
                tail_number2 = Icon_Display_name.split(
                    '_')[-1].split('.')[0] if Icon_Display_name else ''

                # 包含 Img 字段的 Avatar 类型数据
                extracted_data = {
                    "ID": ID,
                    "Name": row.get('Name', {}).get('LocalizedString', ''),
                    "Quality": row['Quality'],
                    "File": f"基板_{tail_number1_1}_{tail_number1_2}.png",
                    "Img": f"基板_{tail_number2}.png",  # 包含 Img 字段
                    "Desc": Desc_string
                }
                custom_data = {
                    custom_keys_avatar[key]: value for key, value in extracted_data.items()}
                output_data_avatar.append(custom_data)

            elif type_value == "EPMCardResourceType::Frame":
                extracted_data = {
                    "ID": ID,
                    "Name": row.get('Name', {}).get('LocalizedString', ''),
                    "Quality": row['Quality'],
                    "File": f"封装_{tail_number1_1}_{tail_number1_2}.png",
                    "Desc": Desc_string
                }
                custom_data = {
                    custom_keys_frame[key]: value for key, value in extracted_data.items()}
                output_data_frame.append(custom_data)


    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data_avatar = save_and_diff_data("IdCard", output_data_avatar)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 IdCard_Get_Added.lua
    if added_data_avatar:
        added_get_data = {}
        for item in added_data_avatar:
            id = item.get("id")
            if id in get_mapping:
                added_get_data[id] = get_mapping[id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data")
            _save_lua_only(data_dir, "IdCard_Get_Added", added_get_data)
            print(f"✨ [IdCard] 已将 {len(added_get_data)} 条新增数据单独输出至 data/IdCard_Get_Added.lua 喵！")

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data_frame = save_and_diff_data("Frame", output_data_frame)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 Frame_Get_Added.lua
    if added_data_frame:
        added_get_data = {}
        for item in added_data_frame:
            id = item.get("id")
            if id in get_mapping:
                    added_get_data[id] = get_mapping[id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data")
            _save_lua_only(data_dir, "Frame_Get_Added", added_get_data)
            print(f"✨ [Frame] 已将 {len(added_get_data)} 条新增数据单独输出至 data/Frame_Get_Added.lua 喵！")
    print("名片与边框数据处理完成喵！\n")
