# modules/generate_role_skin.py
import os

# 从 utils 模块导入需要的变量和函数
from utils.common import (
    PROJECT_ROOT,
    _save_lua_only,
    id_to_Role_name,
    load_json_file,
    save_and_diff_data,
)


def export_role_skin_data():
    print("开始处理角色时装数据...")

    RoleSkin_data = load_json_file("RoleSkin")

    if not RoleSkin_data:
        print("未获取到 RoleSkin 数据，跳过处理喵。")
        return

    output_data = {}
    get_mapping = {}

    # 预留临时映射，统一 key 类型为 str，避免 int/str 类型不匹配喵
    skin_extra_info = {}

    for item in RoleSkin_data:
        for row in item["Rows"].values():
            ID = str(row["RoleSkinId"])  # ✅ 统一转为 str 类型 key
            role_id = row["RoleId"]
            skin_name = row["NameCn"]["LocalizedString"].replace("—", "-")

            if role_id != 901:
                gain_param2 = row.get("GainParam2", {})
                gain_param2_value = gain_param2.get("LocalizedString", "")

                # 将获取方式转换为数组形式
                get_methods = [gain_param2_value] if gain_param2_value else []
                get_mapping[ID] = get_methods

                # 记录品质与获取途径，供后面生成 added_get_data 时计算价格
                Quality_name = row["Quality"]
                skin_extra_info[ID] = {
                    "quality": Quality_name,
                    "gain_param2_value": gain_param2_value,
                }

                # 将角色ID替换为对应的角色名称
                role_name = id_to_Role_name.get(role_id, role_id)

                # 1. 获取基础短描述 (Description)
                skin_short_desc = (
                    row.get("Description", {})
                    .get("LocalizedString", "")
                    .replace("\n", "<br />")
                    .replace('"', "'")
                )

                # 2. 获取长描述/特有描述 (TskinDescription)
                tskin_raw = row.get("TskinDescription", {}).get(
                    "LocalizedString", ""
                )
                skin_desc = (
                    tskin_raw.replace("\n\n", "<br />")
                    .replace("\n", "<br />")
                    .replace('"', "'")
                    if tskin_raw
                    else ""
                )

                # 拼接逻辑：存在长描述时拼接在短描述下方，否则只使用短描述
                skin_desc_combined = (
                    f"{skin_short_desc}<br /><br />{skin_desc}"
                    if skin_desc
                    else skin_short_desc
                )

                # 基础数据
                skin_data = {
                    "id": row["RoleSkinId"],  # 保留原始类型（int或str均可）
                    "quality": Quality_name,
                    "desc": skin_desc_combined,
                }

                # 特殊规则：如果品质为 5 且名字带 '-'，移除简介
                if Quality_name == 5 and "-" in skin_name:
                    skin_data.pop("desc", None)

                if role_name not in output_data:
                    output_data[role_name] = {}
                output_data[role_name][skin_name] = skin_data

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("RoleSkin", output_data)

    # 4. 针对嵌套字典正确提取增量 ID 的获得方式及价格逻辑
    if added_data:
        added_get_data = {}
        if isinstance(added_data, dict):
            for role_name, skins in added_data.items():
                if isinstance(skins, dict):
                    for skin_name, skin_info in skins.items():
                        if isinstance(skin_info, dict):
                            Skin_id = skin_info.get("id")

                            if Skin_id is None:
                                continue

                            # 统一转成 string 去查询临时表喵
                            str_id = str(Skin_id)

                            try:
                                lua_id_key = int(Skin_id)
                            except (ValueError, TypeError):
                                lua_id_key = Skin_id

                            # 获取对应的临时品质及获取途径信息
                            extra = skin_extra_info.get(str_id, {})
                            q_val = extra.get("quality")
                            g_val = extra.get("gain_param2_value")

                            # 计算巴布洛晶核与基弦的数值
                            bablo_crystals = ""
                            base_strings = ""

                            # ✅ 逻辑判断：若 Quality 为 2/3/4 且无特定 gain_param2_value 途径时赋值
                            if q_val == 2 and not g_val:
                                bablo_crystals = 150
                                base_strings = 150
                            elif q_val == 3 and not g_val:
                                bablo_crystals = 480
                                base_strings = 480
                            elif q_val == 4 and not g_val:
                                bablo_crystals = 1280
                                base_strings = 1280

                            # 组装完整的增量导出项
                            added_get_data[lua_id_key] = {
                                "get": get_mapping.get(str_id, []),
                                "BabloCrystals": bablo_crystals,
                                "Basestrings": base_strings,
                                "remark": "",
                            }

            if added_get_data:
                data_dir = os.path.join(PROJECT_ROOT, "data")
                _save_lua_only(data_dir, "RoleSkin_Get_Added", added_get_data)
                print(
                    f"✨ 已成功导出 {len(added_get_data)} 条新增数据！"
                )
    print("角色时装数据处理完成喵！\n")
