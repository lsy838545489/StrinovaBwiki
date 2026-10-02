# modules/generate_weapon_skin.py
import os
# 从 utils 模块导入需要的变量和函数
from utils.common import (
    PROJECT_ROOT,
    _save_lua_only,
    Weapon_en_name_to_cn_name,
    load_json_file,
    save_and_diff_data,
)

def export_weapon_skin_data():
    print("开始处理武器外观数据...")

    WeaponSkin_data = load_json_file("Weapon")

    if not WeaponSkin_data:
            print("未获取到 WeaponSkin 数据，跳过处理喵。")
            return

    output_data = {}
    get_mapping = {}

    # 预留临时映射，方便后续提取增量数据时查询品质和获取途径
    skin_extra_info = {}

    for item in WeaponSkin_data:
        for row in item['Rows'].values():
            Quality_name = row["Quality"]
            if Quality_name != 0 and Quality_name != 1:
                ID = row['Id']
                weapon_name = row['BlueprintDir']
                if weapon_name in Weapon_en_name_to_cn_name:
                    weapon_id = Weapon_en_name_to_cn_name[weapon_name]
                else:
                    continue

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

                skin_localized_string = row['Tips'].get('LocalizedString', '').replace('\n', '<br />').replace('"', "'")
                SkinName_source = row['Name'].get('LocalizedString', '').replace('—', '-')
                if weapon_id == "警探" and SkinName_source == "警探-Bilibili":
                    SkinName_source = "Bilibili"
                elif weapon_id == "警探" and SkinName_source == "警探-斗鱼":
                    SkinName_source = "斗鱼"
                elif weapon_id == "警探" and SkinName_source == "警探-虎牙":
                    SkinName_source = "虎牙"

                if Quality_name == 5 and "-" in SkinName_source:
                    continue

                skin_data = {
                    "id": ID,
                    "quality": Quality_name,
                    "desc": skin_localized_string,
                    }

                if weapon_id not in output_data:
                    output_data[weapon_id] = {}
                output_data[weapon_id][SkinName_source] = skin_data

    # 3. 对比并保存主数据表（全量与增量），获取返回的增量数据列表
    added_data = save_and_diff_data("WeaponSkin", output_data)

    # 4. 针对嵌套字典正确提取增量 ID 的获得方式及价格逻辑
    if added_data:
        added_get_data = {}
        if isinstance(added_data, dict):
            for weapon_id, skins in added_data.items():
                if isinstance(skins, dict):
                    for SkinName_source, skin_info in skins.items():
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
                                bablo_crystals = 980
                                base_strings = 980

                            # 组装完整的增量导出项（直接使用英文键名）
                            added_get_data[lua_id_key] = {
                                "get": get_mapping.get(Skin_id, []),
                                "BabloCrystals": bablo_crystals,
                                "Basestrings": base_strings,
                                "remark": "",
                            }

            if added_get_data:
                data_dir = os.path.join(PROJECT_ROOT, "data")
                _save_lua_only(data_dir, "WeaponSkin_Get_Added", added_get_data)
                print(
                    f"✨ 已成功导出 {len(added_get_data)} 条新增数据！"
                )
    print("武器外观数据处理完成喵！\n")
