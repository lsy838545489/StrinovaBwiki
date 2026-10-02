import os
import re
from utils.common_mobile import load_json_file, save_and_diff_data, _save_lua_only, DATA_ROOT


def clean_desc(desc_raw: str) -> str:
    """清理描述文本中的换行符等特殊字符喵"""
    if not desc_raw:
        return ""
    # 将连续换行或单个换行统一转换为 <br>
    return re.sub(r'(\r?\n)+', '<br>', desc_raw.strip())


def process_added_get_data(added_data, get_mapping, prefix_name):
    """处理增量获取方式数据的通用逻辑喵"""
    if not added_data:
        return

    added_get_data = {
        item["id"]: get_mapping[item["id"]]
        for item in added_data
        if item.get("id") in get_mapping
    }

    if added_get_data:
        data_dir = os.path.join(DATA_ROOT, "data_mobile")
        file_name = f"HeadSculpture_{prefix_name}_Get_Added"
        _save_lua_only(data_dir, file_name, added_get_data)
        print(f"✨ [{prefix_name}] 已将 {len(added_get_data)} 条新增数据单独输出至 data_mobile/{file_name}.lua 喵！")


def export_head_sculpture_data():
    print("开始处理名片与头像框数据喵...")

    item_data = load_json_file("HeadSculpture")

    output_data_avatar = []
    output_data_frame = []
    get_mapping = {}

    for item in item_data:
        for row in item.get('Rows', {}).values():
            type_value = row.get('Type', '')
            item_id = row.get('ItemId')

            # 提取获取途径
            gain_param2 = row.get('GainParam2', {})
            raw_get_str = gain_param2.get('LocalizedString', '')
            get_mapping[item_id] = [raw_get_str] if raw_get_str else []

            # 提取资源后缀
            asset_path_name = row.get('IconItem', {}).get('AssetPathName', '')
            tail_number = asset_path_name.split('_')[-1].split('.')[0] if asset_path_name else ""

            # 处理描述信息
            desc_string = clean_desc(row.get('Desc', {}).get('LocalizedString', ''))
            item_name = row.get('Name', {}).get('LocalizedString', '')
            quality = row.get('Quality', 0)

            if type_value == "EHeadSculptureType::Head":
                output_data_avatar.append({
                    "id": item_id,
                    "name": item_name,
                    "quality": quality,
                    "file": f"移动端基板_{tail_number}.png",
                    "desc": desc_string
                })

            elif type_value == "EHeadSculptureType::Frame":
                output_data_frame.append({
                    "id": item_id,
                    "name": item_name,
                    "quality": quality,
                    "desc": desc_string
                })

    # 1. 保存与对比 Avatar 数据
    added_data_avatar = save_and_diff_data("HeadSculpture_avatar", output_data_avatar)
    process_added_get_data(added_data_avatar, get_mapping, "avatar")

    # 2. 保存与对比 Frame 数据
    added_data_frame = save_and_diff_data("HeadSculpture_frame", output_data_frame)
    process_added_get_data(added_data_frame, get_mapping, "frame")

    print("名片与头像框数据处理完成喵！\n")


if __name__ == "__main__":
    export_head_sculpture_data()
