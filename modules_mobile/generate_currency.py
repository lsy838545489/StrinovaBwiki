# modules_mobile/generate_currency.py
import os
import json
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, DATA_ROOT

def export_currency_data():
    print("开始处理常规货币(Currency)数据喵...")
    custom_keys = {
        "id": "id",
        "name": "name",
        "quality": "quality",
        "file": "file",
        "desc": "desc"
    }

    currency_data = load_json_file("Currency")
    if not currency_data:
        return

    # ===== 载入 PC 端源数据的 (Id, Name) 集合，用于剔除两端共有的道具 =====
    # 数据源为 PC 侧的 GameSourceDataCN（与 modules/generate_items.py 的源数据一致）
    # 判定规则：Id 与 Name 同时相同才算两端共有，才忽略
    pc_currency_keys = set()
    pc_currency_path = os.path.join(DATA_ROOT, os.pardir, "GameSourceDataCN", "PaperMan", "CSV", "Currency.json")
    if not os.path.exists(pc_currency_path):
        print(f"⚠️ 未找到 PC 端源数据 {pc_currency_path}，跳过两端比对（将导出移动端全部数据）")
    else:
        with open(pc_currency_path, "r", encoding="utf-8") as f:
            pc_currency_data = json.load(f)
        for pc_currency in pc_currency_data:
            for pc_row in pc_currency.get("Rows", {}).values():
                pc_id = pc_row.get("Id")
                pc_name = pc_row.get("Name", {}).get("LocalizedString", "")
                pc_currency_keys.add((pc_id, pc_name))
        print(f"PC 端源数据 Currency.json 共 {len(pc_currency_keys)} 条 (Id, Name) 记录，将据此剔除两端共有道具喵")
    # ==========================================================

    output_data = []
    get_mapping = {}
    skipped_shared = 0
    for item in currency_data:
        for row in item['Rows'].values():
            id = row['Id']
            name = row['Name'].get('LocalizedString', '')

            # 与 PC 端源数据比对：Id 与 Name 同时相同才视为两端共有，直接忽略
            if (id, name) in pc_currency_keys:
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

    if pc_currency_keys:
        print(f"与 PC 端比对完成：已忽略 {skipped_shared} 条两端共有道具，移动端独有 {len(output_data)} 条待导出喵")

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("Currency", output_data)

    # 4. 如果有新增数据，提取对应增量 ID 的获得方式单独保存为 Currency_Get_Added.lua
    if added_data:
        added_get_data = {}
        for item in added_data:
            item_id = item.get("id")
            if item_id in get_mapping:
                added_get_data[item_id] = get_mapping[item_id]

    print("常规货币(Currency)数据处理完成喵！")
