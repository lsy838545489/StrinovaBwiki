import json
import sys
import os

# 设置项目根目录
PROJECT_ROOT = r'Z:\BwikiScript'  # 使用原始字符串以防止转义字符问题
os.chdir(PROJECT_ROOT)  # 更改当前工作目录为项目根目录

# 导入所需模块
sys.path.append(PROJECT_ROOT)
from common_mobile import id_to_Quality_name, load_json_file

id_to_role_name = {
    101: "米雪儿·李",
    105: "奥黛丽·格罗夫",
    107: "玛德蕾娜·利里",
    112: "绯莎",
    124: "心夏",
    128: "拉薇",
    131: "伊薇特",
    137: "香奈美",
    146: "星绘"
}

custom_keys = {
    "Name": "Name",
    "Quality": "Quality",
    "Activities": "Activities",
    "File": "File",
    "Desc": "Desc_string"
}

Gift_data =  load_json_file("Item")
Favorability_data =  load_json_file("RoleFavorabilityGiftPresent")

# 处理 Favorability 数据
Favorability_id_to_info = {}
for Favorability_id, Favorability_info in Favorability_data[0]["Rows"].items():
    Favorability_id_to_info[int(Favorability_id)] = {
        "RoleId": Favorability_info["RoleId"],
        "Gift": Favorability_info["Gift"],
        "LikeLevel": Favorability_info["LikeLevel"],
        "Favorability": Favorability_info["Favorability"]
    }

output_data = {}

# 处理 Gift 数据
for item in Gift_data:
    for row in item['Rows'].values():
        gift_id = row.get('Id', 0)
        Quality_name = row.get('Quality', '')
        # 仅处理 30001-30999 范围并且 Quality_name != 1
        if 30001 <= gift_id <= 30999 and Quality_name != 1:
            Quality_id = id_to_Quality_name.get(Quality_name, Quality_name)

            Activitie = True if 30036 <= gift_id <= 30100 else False

            asset_path_name = row.get('IconItem', {}).get('AssetPathName', '') or ''
            tail_number = ''
            if asset_path_name:
                tail_number = asset_path_name.split('_')[-1].split('.')[0]

            extracted_data = {
                "Name": row.get('Name', {}).get('LocalizedString', ''),
                "Quality": Quality_id,
                "Activities": Activitie,
                "File": f"礼物图标_{tail_number}.png" if tail_number else "",
                "Desc": row.get('Desc', {}).get('LocalizedString', ''),
                "GiftID": gift_id
            }

            # 按照 custom_keys 创建自定义数据（并保留 GiftID）
            custom_data = {}
            for src_key, out_key in custom_keys.items():
                if src_key in extracted_data:
                    custom_data[out_key] = extracted_data[src_key]
            custom_data["GiftID"] = gift_id

            # 查找 Favorability 数据
            favorability = {}
            like_level = {}
            for favorability_info in Favorability_id_to_info.values():
                if favorability_info["Gift"] == gift_id:
                    role_name = id_to_role_name.get(favorability_info["RoleId"], None)
                    if role_name:
                        favorability[role_name] = favorability_info["Favorability"]
                        like_level[role_name] = favorability_info["LikeLevel"]

            # 只将有有效角色数据的礼物添加到输出数据
            if favorability or like_level:
                if favorability:
                    custom_data["Favorability"] = favorability
                if like_level:
                    custom_data["LikeLevel"] = like_level
                output_data[gift_id] = custom_data

# ---------- 写 Lua 文件部分（修正并改进） ----------
def _escape_lua_string(s: str) -> str:
    # 简单转义双引号和反斜杠
    return s.replace('\\', '\\\\').replace('"', '\\"')

def py_to_lua(v, indent=0):
    sp = '    ' * indent
    if isinstance(v, bool):
        return 'true' if v else 'false'
    elif isinstance(v, (int, float)):
        return str(v)
    elif isinstance(v, str):
        return '"' + _escape_lua_string(v) + '"'
    elif isinstance(v, dict):
        parts = []
        if not v:
            return '{}'
        parts.append('{\n')
        for k, val in v.items():
            # keys: 如果是有效的 Lua 标识符则不加中括号，否则使用 ["key"]
            if isinstance(k, str) and k.isidentifier():
                key_repr = k
            else:
                key_repr = f'["{_escape_lua_string(str(k))}"]'
            parts.append('    ' + ('    ' * indent) + f'{key_repr} = {py_to_lua(val, indent+1)},\n')
        parts.append(sp + '}')
        return ''.join(parts)
    elif isinstance(v, (list, tuple)):
        parts = ['{\n']
        for item in v:
            parts.append('    ' + ('    ' * indent) + py_to_lua(item, indent+1) + ',\n')
        parts.append(sp + '}')
        return ''.join(parts)
    else:
        # fallback：转换为字符串
        return '"' + _escape_lua_string(str(v)) + '"'

out_dir = os.path.join(PROJECT_ROOT, 'MobileBatch', 'NewData')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, '角色礼物.lua')

with open(out_path, 'w', encoding='utf-8') as file:
    file.write('return {\n')
    # 按 gift_id 排序输出（可选）
    for gift_id, data in sorted(output_data.items()):
        file.write(f'    [{gift_id}] = ')
        file.write(py_to_lua(data, indent=1))
        file.write(',\n')
    file.write('}\n')

print(f'已写入 {out_path}，共 {len(output_data)} 条记录。')
