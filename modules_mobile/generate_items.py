# modules_mobile/generate_items.py
import os
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, PROJECT_ROOT

def export_items_data():
    print("开始处理常规道具(Items)数据喵...")
    custom_keys = {
        "id": "id",
        "name": "name",
        "quality": "quality",
        "file": "file",
        "desc": "desc"
    }

    item_data = load_json_file("Item")
    if not item_data:
            return

    exclude_ranges = [
        (30001, 30999),
        (50001, 55999),
        (60001, 69999),
        (80001, 89999),
        (90001, 91000),
        (93001, 93999),
        # 可继续添加其他范围...
    ]
    exclude_ids = {
        18001,
        19001,
        19101,
        19201,
        19202,
        19301
    }

    output_data = []
    get_mapping = {}
    for item in item_data:
        for row in item['Rows'].values():
            ID = row['Id']

            if any(lower <= ID <= upper for (lower, upper) in exclude_ranges) or ID in exclude_ids:
                continue

            asset_path_name = row['IconItem'].get('AssetPathName', '')
            tail_number = asset_path_name.split('_')[-1].split('.')[0]

            gain_param2 = row.get("GainParam2", {})
            raw_get_str = gain_param2.get("LocalizedString", "")
            gain_param2_value = [raw_get_str] if raw_get_str else []

            # 记录到临时映射集中，方便后续提取增量部分
            get_mapping[ID] = gain_param2_value

            Desc_string = row['Desc'].get('LocalizedString', '').replace('\n', '<br>')

            extracted_data = {
                "id": ID,
                "name": row['Name'].get('LocalizedString', ''),
                "quality": row['Quality'],
                "file": f"道具图标移动端_{tail_number}.png",
                "desc": Desc_string
            }
            custom_data = {custom_keys[key]: value for key, value in extracted_data.items()}

            output_data.append(custom_data)

    # ===== 在保存前按 id 从小到大排序（稳健处理 id 为字符串或数字的情况） =====
    def _id_key(entry):
        v = entry.get('id', 0)
        try:
            return int(v)
        except Exception:
            try:
                return int(str(v).strip())
            except Exception:
                return 0

    output_data.sort(key=_id_key)
    # ======================================================================

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("Items", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 Items_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            item_id = item.get("id")
            if item_id in get_mapping:
                added_get_data[item_id] = get_mapping[item_id]

        if added_get_data:
            data_dir = os.path.join(PROJECT_ROOT, "data_mobile")
            _save_lua_only(data_dir, "Items_Get_Added", added_get_data)
            print(f"✨ [Items] 已将 {len(added_get_data)} 条新增数据的获得方式单独输出至 data_mobile/Items_Get_Added.lua 喵！")

        print("常规道具(Items)数据处理完成喵！")
