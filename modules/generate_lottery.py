# modules/generate_lottery.py
import os
# 从 utils 模块导入需要的变量和函数
from utils.common import id_to_Quality_name, id_to_Role_name, id_to_Weapon_name, load_json_file, export_data_file


def export_lottery_data():
    print("开始处理意识重构数据...")
    # 抽奖名称和质量ID的映射
    id_to_Lottery_name = {
        21001: "逆影蔷薇",
        21005: "猎虎裁恶",
        21006: "失落的伊卡洛斯",
        21007: "末路荣光",
        21008: "千秋岁引",
        21009: "深海幻境",
        21010: "苍雷潜龙",
        21011: "轻舞成双",
        21013: "机动天使",
        21014: "百万主播",
        21017: "世纪歌姬",
        21018: "千面之月",
        21019: "日珥战姬",
        21020: "阿卡西之眼",
        21022: "弦辉骑士",
        21023: "启程之礼",
        21024: "启程之礼",
        21025: "溯光圣祈",
        21026: "焰翎魔女",
        21027: "三途雾徊",
        21028: "绮星梦使",
        21029: "沐春灼华",
        21030: "危险游戏",
        21031: "花游舞夜",
    }

    weapon_to_role_name = {
        "警探": "米雪儿",
        "卫冕": "奥黛丽",
        "独舞": "芙拉薇娅",
        "齿锋": "绯莎",
        "逆焰": "明",
        "影袭": "拉薇",
        "彩绘": "玛德蕾娜",
        "审判官": "信",
        "幻霜": "伊薇特",
        "隼": "梅瑞狄斯",
        "北极星": "星绘",
        "谢幕曲": "香奈美",
        "空境": "心夏",
        "枫鸣": "千代",
        "破晓": "令",
        "自由意志": "白墨",
        "鸣火": "艾卡",
        "欺诈师": "加拉蒂亚",
        "绽放": "珐格兰丝",
        "绝对执行": "忧雾",
        "校准仪": "蕾欧娜",
        "夜镰": "玛拉",
        "潮音": "汐"
    }

    # 自定义键
    custom_keys = {
        "cat": "cat",
        "name": "name",
        "src": "src",
        "type": "type"
    }

    # 加载输入的JSON文件
    Lottery_data = load_json_file("LotteryDrop")
    WeaponSkin_data = load_json_file("Weapon")
    RoleSkin_data = load_json_file("RoleSkin")
    Decal_data = load_json_file("Decal")
    IdCard_data = load_json_file("IdCard")
    RoleVoice_data = load_json_file("RoleVoice")
    Emote_data = load_json_file("Emote")

    # 初始化一个空字典来保存转换后的数据
    output_data = {}

    # 构建武器皮肤字典
    WeaponSkin_dict = {}
    for key, value in WeaponSkin_data[0]["Rows"].items():
        try:
            weapon_id = value["BlueprintDir"]
            if weapon_id not in id_to_Weapon_name:
                continue

            weapon_name = id_to_Weapon_name[weapon_id]
            weapon_role = weapon_to_role_name.get(
                weapon_name, f"非角色专属武器({weapon_name})")
            weapon_skin_name = value["Name"]["LocalizedString"]

            WeaponSkin_dict[value["Id"]] = {
                "Weapon": weapon_name,
                "Role": weapon_role,
                "Name": weapon_skin_name
            }
        except (KeyError, TypeError):
            continue

    # 构建角色皮肤字典
    RoleSkin_dict = {}
    for key, value in RoleSkin_data[0]["Rows"].items():
        try:
            if "NameShort" not in value or "LocalizedString" not in value["NameShort"]:
                continue

            role_id = value["RoleId"]
            if role_id not in id_to_Role_name:
                continue

            role_name = id_to_Role_name[role_id]
            role_skin_name = value["NameShort"]["LocalizedString"]

            RoleSkin_dict[value["RoleSkinId"]] = {
                "Role": role_name,
                "NameShort": role_skin_name
            }
        except (KeyError, TypeError):
            continue

    # 构建其他字典（喷漆、基板等）
    Decal_dict = {}
    for key, value in Decal_data[0]["Rows"].items():
        try:
            Decal_dict[value["Id"]] = value["Name"]["LocalizedString"]
        except (KeyError, TypeError):
            continue

    IdCard_dict = {}
    for key, value in IdCard_data[0]["Rows"].items():
        try:
            IdCard_dict[value["Id"]] = {
                "Name": value["Name"]["LocalizedString"],
                "File": value.get("File", f"基板_{value['Id']}.png")
            }
        except (KeyError, TypeError):
            continue

    RoleVoice_dict = {}
    for key, value in RoleVoice_data[0]["Rows"].items():
        try:
            if "VoiceName" not in value or "LocalizedString" not in value["VoiceName"]:
                continue

            role_id = value["RoleId"]
            role_name = id_to_Role_name.get(role_id, str(role_id))
            voice_name = value["VoiceName"]["LocalizedString"]

            RoleVoice_dict[value["RoleVoiceId"]] = {
                "Role": role_name,
                "Name": voice_name
            }
        except (KeyError, TypeError):
            continue

    Emote_dict = {}
    for key, value in Emote_data[0]["Rows"].items():
        try:
            Emote_dict[value["Id"]] = value["Name"]["LocalizedString"]
        except (KeyError, TypeError):
            continue

    # 处理抽奖数据
    for item in Lottery_data:
        for row in item['Rows'].values():
            try:
                lottery_id = row['GroupId']
                if lottery_id not in id_to_Lottery_name:
                    continue

                lottery_name = id_to_Lottery_name[lottery_id]
                Items_ID = row['Items'][0]['ItemId']
                quality_id = row['Quality']
                quality_name = id_to_Quality_name.get(
                    quality_id, str(quality_id))

                # 根据物品ID范围处理不同类型
                if 10100001 <= Items_ID <= 19999999:
                    WeaponSkin_info = WeaponSkin_dict.get(Items_ID)
                    if not WeaponSkin_info:
                        continue
                    localized_cat = f'{WeaponSkin_info["Weapon"]}·{WeaponSkin_info["Role"]}'
                    localized_name = WeaponSkin_info["Name"]
                    filetype = f'武器外观图鉴_{Items_ID}.png'

                elif 20101001 <= Items_ID <= 20999999:
                    RoleSkin_info = RoleSkin_dict.get(Items_ID)
                    if not RoleSkin_info:
                        continue
                    localized_cat = f'{RoleSkin_info["Role"]}·外观'
                    localized_name = RoleSkin_info["NameShort"]
                    filetype = f'角色时装图鉴_{Items_ID}.png'

                elif 22101001 <= Items_ID <= 22999999:
                    RoleVoice_info = RoleVoice_dict.get(Items_ID)
                    if not RoleVoice_info:
                        continue
                    localized_cat = f'{RoleVoice_info["Role"]}·语音'
                    localized_name = RoleVoice_info["Name"].replace(
                        '。', '').replace('！', '')
                    filetype = f'图标-{RoleVoice_info["Role"]}语音.png'

                elif 30000001 <= Items_ID <= 30999999:
                    localized_name = Decal_dict.get(Items_ID)
                    if not localized_name:
                        continue
                    localized_cat = "喷漆"
                    filetype = f'喷漆_{Items_ID}.png'

                elif 31000001 <= Items_ID <= 31999999:
                    IdCard_info = IdCard_dict.get(Items_ID)
                    if not IdCard_info:
                        continue
                    localized_cat = "芯片基板"
                    localized_name = IdCard_info["Name"]
                    filetype = IdCard_info["File"]

                elif 60000001 <= Items_ID <= 60999999:
                    Emote_info = Emote_dict.get(Items_ID)
                    if not Emote_info:
                        continue
                    Emote_parts = Emote_info.split('-')
                    if len(Emote_parts) >= 2:
                        Emote_role = Emote_parts[0]
                        Emote_name = '-'.join(Emote_parts[1:])
                    else:
                        Emote_role = "通用"
                        Emote_name = Emote_info
                    localized_cat = "表情"
                    localized_name = f'{Emote_role}·{Emote_name}'
                    filetype = f'表情_{Items_ID}.png'

                else:
                    continue

                # 构建提取的数据
                extracted_data = {
                    "cat": localized_cat,
                    "name": localized_name,
                    "src": filetype,
                    "Items": Items_ID,
                    "Quality": quality_name,
                }

                # 如果是高品质物品，添加类型信息
                if quality_id == 5:
                    if 10100001 <= Items_ID <= 19999999:
                        extracted_data["type"] = "武器"
                    elif 20101001 <= Items_ID <= 20999999:
                        extracted_data["type"] = "时装"

                # 构建最终输出数据
                custom_data = {custom_keys[key]: value for key, value in extracted_data.items()
                    if key in custom_keys}
                if "type" in extracted_data:
                    custom_data["type"] = extracted_data["type"]

                # 添加到输出字典
                if lottery_name not in output_data:
                    output_data[lottery_name] = {}
                if quality_name not in output_data[lottery_name]:
                    output_data[lottery_name][quality_name] = []

                output_data[lottery_name][quality_name].append(custom_data)

            except Exception as e:
                print(f"处理抽奖条目时出错: {e}")
                continue

    if "启程之礼" in output_data:
        seen_items = set()
        merged_data = {}

        for quality, items in output_data["启程之礼"].items():
            if quality not in merged_data:
                merged_data[quality] = []

            for item in items:
                item_id = item["src"]
                if item_id not in seen_items:
                    seen_items.add(item_id)
                    merged_data[quality].append(item)

        output_data["启程之礼"] = merged_data

    export_data_file('Lottery', output_data, fileType='json')
    print("意识重构数据处理完成喵！\n")
