import os
from utils.common import load_json_file, Weapon_en_name_to_cn_name, PROJECT_ROOT


def _parse_prize_item(prize, bp_id, is_free, dicts):
    """辅助函数：处理单个通行证奖励项并拼接为 Wikitext 模板形式喵！"""
    item_id = prize.get("ItemId")
    item_num = prize.get("ItemAmount", 1)
    free_suffix = "|免费=1" if is_free else ""

    Badge_dict, Decal_dict, IdCard_dict, Emote_dict, items_dict, RoleSkin_dict, WeaponSkin_dict, RoleVoice_dict = dicts

    if item_id == 3:
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=巴布洛晶核|数量={item_num}{free_suffix}}}}}'
    elif item_id == 6:
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=基弦|数量={item_num}{free_suffix}}}}}'
    elif item_id == 11:
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=其它|名称=战令币|数量={item_num}{free_suffix}}}}}'
    elif item_id == 22001:
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=弦列维度礼盒|数量={item_num}{free_suffix}}}}}'
    elif item_id == 40001:
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=记忆序列|数量={item_num}{free_suffix}}}}}'
    elif (10100001 <= item_id <= 19999999) or (32000001 <= item_id <= 32999999):
        localized_name = WeaponSkin_dict.get(item_id, f'Unknown WeaponSkin ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=武器皮肤|武器皮肤={localized_name}{free_suffix}}}}}'
    elif 20101001 <= item_id <= 20999999:
        localized_name = RoleSkin_dict.get(item_id, f'Unknown RoleSkin ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=角色时装|角色时装={localized_name}{free_suffix}}}}}'
    elif 21101001 <= item_id <= 21999999:
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=武器皮肤|武器皮肤={item_id}{free_suffix}}}}}'
    elif 22101001 <= item_id <= 22999999:
        role_info = RoleVoice_dict.get(item_id, {"角色": "Unknown Role", "语音名称": f"Unknown Voice ({item_id})"})
        role_name = role_info.get("角色", "Unknown Role") if isinstance(role_info, dict) else "Unknown Role"
        voice_name = role_info.get("语音名称", f"Unknown Voice ({item_id})") if isinstance(role_info, dict) else str(role_info)
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=角色语音|语音角色={role_name}|语音名称={voice_name}|语音文件={free_suffix}}}}}'
    elif 30000001 <= item_id <= 30999999:
        localized_name = Decal_dict.get(item_id, f'Unknown Decal ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=喷漆|喷漆名称={localized_name}{free_suffix}}}}}'
    elif 31000001 <= item_id <= 31999999:
        localized_name = IdCard_dict.get(item_id, f'Unknown IdCard ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=基板|基板名称={localized_name}{free_suffix}}}}}'
    elif 33000001 <= item_id <= 33999999:
        localized_name = Badge_dict.get(item_id, f'Unknown Badge ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=勋章|勋章名称={localized_name}{free_suffix}}}}}'
    elif 60000001 <= item_id <= 60999999:
        localized_name = Emote_dict.get(item_id, f'Unknown Emote ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=表情|表情名称={localized_name}{free_suffix}}}}}'
    else:
        localized_name = items_dict.get(item_id, f'Unknown Item ({item_id})')
        return f'{{{{特别行动道具|等级={bp_id}级|道具类型=其它|名称={localized_name}|数量={item_num}{free_suffix}}}}}'


def export_battle_pass_task_data():
    """新增加函数：处理并生成赛季挑战任务 Wikitext 表格喵！"""
    print("开始处理赛季挑战任务（BattlePassDareTask）数据喵...")
    BattlePass_data = load_json_file("BattlePassDareTask")

    if not BattlePass_data:
        print("未获取到 BattlePassDareTask 数据，跳过处理喵。")
        return

    output_data = []
    for item in BattlePass_data:
        rows = item.get("Rows", {})
        for row in rows.values():
            desc_obj = row.get("Desc", {})
            task = desc_obj.get("LocalizedString", "").replace("{1}，{2}，{3}，{4}，{5}，", "特定角色")

            prizes = row.get("Prize", [])
            task_amounts = prizes[0].get("ItemAmount", 0) if prizes else 0

            output_data.append({
                "任务": task,
                "获得点数": task_amounts
            })

    # 生成 MediaWiki 表格文本
    lines = [
        '{| class="klbqtable"',
        '! 任务 !! 获得搜查令经验'
    ]
    for item in output_data:
        lines.append("|-")
        lines.append(f"| {item['任务']}\n| {item['获得点数']}")
    lines.append("|}")

    # 保存文件到 data 目录
    data_dir = os.path.join(PROJECT_ROOT, "data")
    os.makedirs(data_dir, exist_ok=True)
    output_path = os.path.join(data_dir, "赛季通行证挑战任务.txt")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"赛季挑战任务数据已成功保存至 data/赛季通行证挑战任务.txt 喵！")


def export_battle_pass_data(target_season=18):
    """主函数：同时处理战令奖励数据与赛季挑战任务数据喵！"""
    print(f"开始处理 Season {target_season} 战斗通行证（Battle Pass）数据喵...")

    # 1. 加载各个关联基础表数据
    BattlePassPrize_data = load_json_file("BattlePassPrize")
    Badge_data = load_json_file("Badge")
    Decal_data = load_json_file("Decal")
    IdCard_data = load_json_file("IdCard")
    Emote_data = load_json_file("Emote")
    items_data = load_json_file("Item")
    RoleSkin_data = load_json_file("RoleSkin")
    WeaponSkin_data = load_json_file("Weapon")
    RoleVoice_data = load_json_file("RoleVoice")

    # 2. 构建 ID 到中文名称的映射字典
    Badge_dict = {value["Id"]: value["Name"]["LocalizedString"] for value in Badge_data[0]["Rows"].values()}
    Decal_dict = {value["Id"]: value["Name"]["LocalizedString"] for value in Decal_data[0]["Rows"].values()}
    IdCard_dict = {value["Id"]: value["Name"].get("LocalizedString") for value in IdCard_data[0]["Rows"].values()}
    Emote_dict = {value["Id"]: value["Name"]["LocalizedString"] for value in Emote_data[0]["Rows"].values()}
    items_dict = {value["Id"]: value["Name"]["LocalizedString"] for value in items_data[0]["Rows"].values()}
    RoleSkin_dict = {value["RoleSkinId"]: value["NameCn"]["LocalizedString"] for value in RoleSkin_data[0]["Rows"].values()}

    WeaponSkin_dict = {}
    for key, value in WeaponSkin_data[0]["Rows"].items():
        weapon_en_name = value.get("BlueprintDir", "")
        skin_cn_name = value.get("Name", {}).get("LocalizedString", "")
        skin_id = int(value.get("Id", key))

        if weapon_en_name in Weapon_en_name_to_cn_name:
            weapon_name = Weapon_en_name_to_cn_name[weapon_en_name]
            WeaponSkin_dict[skin_id] = f"{weapon_name}-{skin_cn_name}"
        else:
            WeaponSkin_dict[skin_id] = skin_cn_name

    RoleVoice_dict = {value["RoleVoiceId"]: value.get("VoiceName", {}).get("LocalizedString") for value in RoleVoice_data[0]["Rows"].values()}

    dicts = (Badge_dict, Decal_dict, IdCard_dict, Emote_dict, items_dict, RoleSkin_dict, WeaponSkin_dict, RoleVoice_dict)

    output = []

    # 3. 提取 BattlePassPrize 数据
    battle_pass_prize = next((entry for entry in BattlePassPrize_data if entry.get("Name") == "BattlePassPrize"), None)

    if battle_pass_prize:
        rows = battle_pass_prize.get("Rows", {})

        for key, value in rows.items():
            if value.get("Season") == target_season:
                bp_id = value["Id"]

                # 处理 Prize1 列表 (免费奖励)
                for prize in value.get("Prize1", []):
                    output.append(_parse_prize_item(prize, bp_id, is_free=True, dicts=dicts))

                # 处理 Prize2 列表 (付费奖励)
                for prize in value.get("Prize2", []):
                    output.append(_parse_prize_item(prize, bp_id, is_free=False, dicts=dicts))

        # 4. 保存战令奖励数据
        data_dir = os.path.join(PROJECT_ROOT, "data")
        os.makedirs(data_dir, exist_ok=True)
        output_file_path = os.path.join(data_dir, "赛季通行证奖励.txt")

        with open(output_file_path, "w", encoding="utf-8") as file:
            file.write("\n".join(output))

        print(f"通行证奖励数据已成功保存至 data/赛季通行证奖励.txt 喵！")
    else:
        print("未找到 BattlePassPrize 相关数据，跳过通行证奖励处理喵。")

    # 5. 同时调用处理赛季挑战任务
    export_battle_pass_task_data()

export_battle_pass_data()
