# modules_mobile/generate_items.py
import os
import json
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, DATA_ROOT

def export_items_data():
    print("开始处理常规道具(Item)数据喵...")
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

    # ===== 载入 PC 端源数据的 Name 集合，用于剔除两端共有的道具 =====
    # 数据源为 PC 侧的 GameSourceDataCN（与 modules/generate_items.py 的源数据一致）
    # 判定规则：只要 Name 相同（比对时忽略全角冒号“：”）即视为两端共有，直接忽略
    pc_item_names = set()
    pc_item_path = os.path.join(DATA_ROOT, os.pardir, "GameSourceDataCN", "PaperMan", "CSV", "Item.json")
    if not os.path.exists(pc_item_path):
        print(f"⚠️ 未找到 PC 端源数据 {pc_item_path}，跳过两端比对（将导出移动端全部数据）")
    else:
        with open(pc_item_path, "r", encoding="utf-8") as f:
            pc_item_data = json.load(f)
        for pc_item in pc_item_data:
            for pc_row in pc_item.get("Rows", {}).values():
                pc_name = pc_row.get("Name", {}).get("LocalizedString", "")
                if pc_name:
                    # 存入比对集合时移除全角冒号
                    clean_pc_name = pc_name.replace("：", "")
                    pc_item_names.add(clean_pc_name)
        print(f"PC 端源数据 Item.json 共 {len(pc_item_names)} 个 Name 记录，将据此剔除两端共有道具喵")
    # ==========================================================

    output_data = []
    get_mapping = {}
    skipped_shared = 0
    for item in item_data:
        for row in item['Rows'].values():
            id = row['Id']
            name = row['Name'].get('LocalizedString', '')
            if "测试" in name:
                continue  # 跳过包含“测试”的道具

            # 与 PC 端源数据比对：比对时忽略全角冒号“：”，相同则视为两端共有直接忽略
            clean_name = name.replace("：", "")
            if clean_name in pc_item_names:
                skipped_shared += 1
                continue

            asset_path_name = row['IconItem'].get('AssetPathName', '')
            tail_number = asset_path_name.split('_')[-1].split('.')[0]

            gain_param2 = row.get("GainParam2", {})
            raw_get_str = gain_param2.get("LocalizedString", "")
            gain_param2_value = [raw_get_str] if raw_get_str else []

            # 记录到临时映射集中，方便后续提取增量部分
            get_mapping[id] = gain_param2_value

            Desc_string = row['Desc'].get('LocalizedString', '').replace('\n', '<br>')

            extracted_data = {
                "id": id,
                "name": name,
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

    if pc_item_names:
        print(f"与 PC 端比对完成：已忽略 {skipped_shared} 条两端共有道具，移动端独有 {len(output_data)} 条待导出喵")

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("Items", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 Items_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            item_id = item.get("id")
            if item_id in get_mapping:
                added_get_data[item_id] = get_mapping[item_id]

    print("常规道具(Item)数据处理完成喵！")
