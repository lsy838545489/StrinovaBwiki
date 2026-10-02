import sys
import json
import os
import re
import mwclient
import time
import rookiepy
import shutil
from datetime import datetime

# ================= 路径配置 =================
# 1. 获取当前脚本（common_mobile.py）所在的绝对路径，即 ExportScripts 目录
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# 2. 项目根目录（即 ExportScripts）
PROJECT_ROOT = SCRIPT_DIR

# 3. 项目最外层根目录（StrinovaBwiki）
WIKI_ROOT = os.path.abspath(os.path.join(PROJECT_ROOT, ".."))

# 4. 数据组织目录（GameOrganizeData）
DATA_ROOT = os.path.join(WIKI_ROOT, "GameOrganizeData")

# 切换到项目根目录
os.chdir(PROJECT_ROOT)
sys.path.append(PROJECT_ROOT)

DEFAULT_FOLDERS = [
    os.path.join(WIKI_ROOT, "GameSourceDataMobile", "PaperMan", "CSV", "Mobile"),
    os.path.join(WIKI_ROOT, "GameSourceDataMobile", "PaperMan", "CSV", "ChannelCfgRedirect", "Mobile"),
    os.path.join(WIKI_ROOT, "GameSourceDataMobile", "PaperMan", "CyTable", "StringTable"),
    os.path.join(WIKI_ROOT, "GameSourceDataMobile", "PaperMan", "CSV"),
]

# 角色ID和角色名的映射
id_to_Role_name = {
    101: "米雪儿·李",
    105: "奥黛丽·格罗夫",
    107: "玛德蕾娜·利里",
    108: "信",
    109: "令",
    110: "白墨",
    112: "绯莎",
    115: "芙拉薇娅",
    119: "艾卡",
    120: "珐格兰丝",
    121: "忧雾",
    122: "玛拉",
    123: "蕾欧娜",
    124: "心夏",
    125: "千代",
    126: "诺诺",
    128: "拉薇",
    130: "汐",
    131: "伊薇特",
    132: "明",
    133: "梅瑞狄斯",
    137: "香奈美",
    146: "星绘",
    205: "加拉蒂亚·利里",
    301: "爆裂魔怪",
    302: "血荆皇女",
    304: "刺镰魔怪",
    305: "冥荆皇女",
    306: "莉莉丝",
}

en_to_cn_name = {
    "Michele": "米雪儿·李",
    "Audery": "奥黛丽·格罗夫",
    "Audrey": "奥黛丽·格罗夫",
    "Maddelena": "玛德蕾娜·利里",
    "Nobunaga": "信",
    "Reiichi": "令",
    "MoBai": "白墨",
    "Mobai": "白墨",
    "Fuchsia": "绯莎",
    "Flavia": "芙拉薇娅",
    "flavia": "芙拉薇娅",
    "Aika": "艾卡",
    "AIKA": "艾卡",
    "Fragrans": "珐格兰丝",
    "Yugiri": "忧雾",
    "Mara": "玛拉",
    "Leona": "蕾欧娜",
    "KokonaShiki": "心夏",
    "Nora": "诺诺",
    "Lawine": "拉薇",
    "Yvette": "伊薇特",
    "Ming": "明",
    "MIng": "明",
    "Meredith": "梅瑞狄斯",
    "Kanami": "香奈美",
    "Huixing": "星绘",
    "Galatea": "加拉蒂亚·利里",
    "Chiyo": "千代",
    "Cielle": "汐",
    "Grenade": "战术道具",
}

# 武器ID和武器名的映射
id_to_Weapon_name = {
    "Katana": "忍锋",
    "KatanaSickle": "战镰",
    "KatanaGreatSword": "大剑",
    "FlamePistol": "焚焰者",
    "MicroUzi": "小蜜蜂",
    "Chiappa": "重焰",
    "DesertEagle": "雪鸮",
    "Grenade": "破片手雷",
    "GrenadeTreatment": "治疗雷",
    "GrenadeWindField": "风场雷",
    "GrenadeSlowDown": "减速雷",
    "GrenadeFlash": "闪光弹",
    "GrenadeSmoke": "烟雾弹",
    "GrenadeInterceptor": "拦截者",
    "GrenadeAlarm": "警报器",
    "GrenadeSnowBall": "雪球",
    "GrenadeShield": "防弹屏障",
    "M4A1": "警探",
    "MG42": "卫冕",
    "Vector": "独舞",
    "SCARH": "齿锋",
    "AKM": "逆焰",
    "XM8": "影袭",
    "G28": "彩绘",
    "G3SG1": "审判官",
    "MP5A5": "幻霜",
    "AUG": "隼",
    "FAMAS": "北极星",
    "M82A1": "谢幕曲",
    "M200": "空境",
    "SVD": "破晓",
    "Super90": "自由意志",
    "AA12": "鸣火",
    "AKM_Galatea": "欺诈师",
    "M4A1_Fragrans": "绽放",
    "AUG_Yugiri": "绝对执行",
    "Ultimax100": "校准仪",
    "MP5A1": "夜镰",
    "HK417": "枫鸣",
    "M1887": "潮音",
    "P90": "雨晦",
}

def wiki_login():
    site = mwclient.Site("wiki.biligame.com", path="/klbq/")
    cookies = rookiepy.firefox(["biligame.com"])
    sessdata = next((c["value"]
                    for c in cookies if c["name"] == "SESSDATA"), None)
    site.login(cookies={"SESSDATA": sessdata})
    site.force_login = True

    try:
        userinfo = site.api("query", meta="userinfo", uiprop="rights")
        if "query" not in userinfo or "userinfo" not in userinfo["query"]:
            raise Exception("无法获取用户信息，Cookie可能已失效")
        print(f"登录成功！用户名: {userinfo['query']['userinfo']['name']}")
    except Exception as e:
        print("登录验证失败:", str(e))
        raise

    return site


def load_json_file(name: str, folders: list = None) -> dict:
    if folders is None:
        folders = DEFAULT_FOLDERS

    for folder in folders:
        file_path = os.path.join(folder, name + ".json")
        try:
            with open(file_path, "r", encoding="utf-8") as file:  # 自动处理BOM
                return json.load(file)
        except FileNotFoundError:
            continue
        except Exception as e:
            print(f"加载 {file_path} 时出错: {str(e)}")
            return {}

    print(f"在所有路径中均未找到 {name}.json")
    return {}


def save_json(data_folder, file_data, file_name):
    os.makedirs(data_folder, exist_ok=True)
    output_file_path = os.path.join(data_folder, f"{file_name}.json")
    with open(output_file_path, "w", encoding="utf-8") as f:
        json.dump(file_data, f, ensure_ascii=False, indent=4)


def upload_wiki_data(page_title, filename):
    site = wiki_login()
    if site.logged_in:
        with open(filename, "r", encoding="utf-8") as f:
            content = f.read()

            # 清除BOM和首尾空白
            content = content.lstrip("\ufeff").strip()

            # 验证Lua基本语法
            if not content.startswith("return"):
                raise ValueError("生成的Lua文件缺少return语句")

            # 执行上传
            page = site.pages[page_title]
            page.save(content, summary="更新数据")
            print(f"{page_title} 更新成功")
    else:
        print("登录失败，请检查 SESSDATA 是否有效")


# Lua 保留关键字集合
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "goto",
    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
    "until", "while"
}

def format_lua_table(input_val, indent_level=0, is_root=True):
    """递归将 Python 数据格式化为多行 Lua 适用的字符串表示喵（支持列表和字典）"""
    indent_str = "\t" * indent_level
    next_indent_str = "\t" * (indent_level + 1)

    def is_valid_lua_identifier(s):
        s_str = str(s)
        if s_str in LUA_KEYWORDS:
            return False
        return bool(re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", s_str))

    result = ""
    if isinstance(input_val, bool):
        result = "true" if input_val else "false"
    elif isinstance(input_val, (int, float)):
        result = str(input_val)
    elif isinstance(input_val, str):
        clean_str = input_val.replace('"', '\\"')
        result = f'"{clean_str}"'
    elif isinstance(input_val, list):
        if not input_val:
            result = "{}"
        else:
            is_simple_list = all(isinstance(x, (int, float, str)) for x in input_val)
            if is_simple_list:
                inner = ", ".join(format_lua_table(x, indent_level, False) for x in input_val)
                result = f"{{ {inner} }}"
            else:
                inner = ",\n".join(
                    f"{next_indent_str}{format_lua_table(x, indent_level + 1, False)}"
                    for x in input_val
                )
                result = f"{{\n{inner},\n{indent_str}}}"
    elif isinstance(input_val, dict):
        if not input_val:
            result = "{}"
        else:
            inner_parts = []
            for k, v in input_val.items():
                if v is None:
                    continue

                val_str = format_lua_table(v, indent_level + 1, False)

                # 修复点：优先判断键是否为数值类型
                if isinstance(k, (int, float)):
                    # 原生数值类型的键，不需要加引号
                    inner_parts.append(f"{next_indent_str}[{k}] = {val_str}")
                elif isinstance(k, str) and k.isdigit():
                    # 纯数字组成的字符串键，自动转为 Lua 的数值索引
                    inner_parts.append(f"{next_indent_str}[{k}] = {val_str}")
                elif is_valid_lua_identifier(k):
                    # 合法的标识符键，直接使用 k = ...
                    inner_parts.append(f"{next_indent_str}{k} = {val_str}")
                else:
                    # 其他字符串类型的键，使用 ['k'] = ...
                    clean_k = str(k).replace("'", "\\'")
                    inner_parts.append(f"{next_indent_str}['{clean_k}'] = {val_str}")

            if not inner_parts:
                result = "{}"
            else:
                inner = ",\n".join(inner_parts)
                result = f"{{\n{inner},\n{indent_str}}}"
    else:
        result = str(input_val)

    if is_root:
        return f"return {result}\n"
    return result


def _save_full_files(output_dir, file_name, data):
    """写出全量 JSON 和 Lua 文件"""
    # 保存全量 JSON（作为下次运行时的旧数据对比参照）
    with open(os.path.join(output_dir, f"{file_name}.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)

    # 保存全量 Lua
    _save_lua_only(output_dir, file_name, data)


def _save_lua_only(output_dir, file_name, data):
    """仅写出 Lua 文件"""
    lua_str = format_lua_table(data)
    with open(os.path.join(output_dir, f"{file_name}.lua"), "w", encoding="utf-8") as f:
        f.write(lua_str)

def save_and_diff_data(file_name, new_data, id_key="id"):
    """
    保存数据并对比增量，增量数据仅导出 Lua 表文件喵！
    """
    data_dir = os.path.join(DATA_ROOT, "data_mobile")
    data_old_dir = os.path.join(DATA_ROOT, "data_old_mobile")

    os.makedirs(data_dir, exist_ok=True)
    os.makedirs(data_old_dir, exist_ok=True)

    json_path = os.path.join(data_dir, f"{file_name}.json")
    lua_path = os.path.join(data_dir, f"{file_name}.lua")
    old_json_path = os.path.join(data_old_dir, f"{file_name}.json")
    old_lua_path = os.path.join(data_old_dir, f"{file_name}.lua")

    old_data = None

    # 1. 读取旧数据：优先从 data_mobile/ 读取并移动备份，若 data_mobile/ 没有则从 data_old_mobile/ 读取兜底
    if os.path.exists(json_path):
        try:
            with open(json_path, "r", encoding="utf-8") as f:
                old_data = json.load(f)
            # 移动覆盖到 data_old_mobile/
            shutil.move(json_path, old_json_path)
            if os.path.exists(lua_path):
                shutil.move(lua_path, old_lua_path)
            print(f"[{file_name}] 旧数据已备份至 data_old_mobile/ 目录喵！")
        except Exception as e:
            print(f"[{file_name}] 备份旧数据时出错: {e}")
    elif os.path.exists(old_json_path):
        try:
            with open(old_json_path, "r", encoding="utf-8") as f:
                old_data = json.load(f)
            print(f"[{file_name}] 从 data_old_mobile/ 读取到了历史数据喵！")
        except Exception as e:
            print(f"[{file_name}] 读取 data_old_mobile 旧数据出错: {e}")

    # 2. 比对数据提取纯新增项
    added_data = extract_added_by_id(old_data, new_data, id_key)

    # 3. 保存全量数据（保存 JSON 作为下次比对基准 + 全量 Lua）
    _save_full_files(data_dir, file_name, new_data)
    print(f"[{file_name}] 全量新数据已保存至 data_mobile/{file_name}.lua 喵！")

    # 4. 如果存在新增数据，仅单独输出 *_Added.lua 文件喵！
    if added_data:
        added_file_name = f"{file_name}_Added"
        _save_lua_only(data_dir, added_file_name, added_data)
        count = len(added_data) if isinstance(added_data, (dict, list)) else "若干"
        print(f"✨ [{file_name}] 检测到 {count} 条纯新增数据，已单独输出至 data_mobile/{added_file_name}.lua 喵！")
    else:
        print(f"[{file_name}] 与旧数据比对无新 ID 增加喵。")

    return added_data


def extract_added_by_id(old_data, new_data, id_key="id"):
    """
    核心比对函数：修正了嵌套实体字典被拆解导致 id 丢弃的问题喵！
    """
    if old_data is None:
        return new_data  # 首次运行全量视为新增

    # 情况 A：数据结构为字典 (Dict，如 [ID] = { ... } 或 角色嵌套结构)
    if isinstance(new_data, dict):
        if not isinstance(old_data, dict):
            return new_data

        added = {}
        # 构建 str(key) -> val 的映射表，消除 int/str 类型差异
        old_key_map = {str(k): v for k, v in old_data.items()}

        for key, val in new_data.items():
            str_key = str(key)
            if str_key not in old_key_map:
                # 情况 1：整项 Key (如新的角色或新的皮肤名) 在旧数据中完全不存在，直接当作新增
                added[key] = val
            elif isinstance(val, dict):
                # 情况 2：Key 存在，但 val 是字典
                # 判断当前 val 是否已经是“实体数据字典”（即内部含有 id_key，如 {"id": 101, ...}）
                if id_key in val:
                    # 实体字典如果 Key 已在旧数据中，说明该皮肤/实体已存在，不需要作为增量导出
                    continue
                else:
                    # 如果不是实体字典（比如是角色名这一层分类容器），则继续向上/下层递归比对
                    old_sub = old_key_map[str_key]
                    if isinstance(old_sub, dict):
                        sub_added = extract_added_by_id(old_sub, val, id_key)
                        if sub_added:
                            added[key] = sub_added
        return added

    # 情况 B：数据结构为列表 (List，如 [ {"id": 101, ...}, ... ])
    elif isinstance(new_data, list):
        if not isinstance(old_data, list):
            return new_data

        old_ids = {
            str(item[id_key])
            for item in old_data
            if isinstance(item, dict) and id_key in item
        }

        added = []
        for item in new_data:
            if isinstance(item, dict) and id_key in item:
                if str(item[id_key]) not in old_ids:
                    added.append(item)
            else:
                if item not in old_data:
                    added.append(item)
        return added

    return None

def backup_existing_file(filePath):
    """
    备份逻辑：只移动指定的目标文件到 data_old 目录喵！
    若 data_old 目录已存在同名文件，将直接进行覆盖喵。
    :param filePath: 要检查的单文件完整路径 (例如 PROJECT_ROOT/data/ProfileData.json)
    :return: bool 是否处理成功
    """
    # 1. 如果文件不存在，说明是第一次生成，无需备份喵
    if not os.path.exists(filePath):
        return True

    # 2. 安全防御：严格限制必须是【普通文件】，防止误把整个 data 目录移走喵！
    if not os.path.isfile(filePath):
        print(f"警告：备份路径 {filePath} 不是单个文件（可能是目录），已拦截操作以防破坏数据喵！")
        return False

    try:
        # 3. 确保脚本根目录下的 data_old_mobile 目录存在
        backupDir = os.path.join(DATA_ROOT, "data_old_mobile")
        os.makedirs(backupDir, exist_ok=True)

        # 4. 只提取当前这一个文件的文件名 (例如 "ProfileData.json")
        fileName = os.path.basename(filePath)
        backupPath = os.path.join(backupDir, fileName)

        # 5. 只移动这单份旧文件到 data_old_mobile 目录喵
        os.replace(filePath, backupPath)
        print(f"检测到旧文件，已单独将 {fileName} 移动并覆盖至 data_old_mobile/{fileName} 喵！")
        return True

    except Exception as e:
        print(f"移动备份文件 {filePath} 到 data_old_mobile 失败了喵！错误信息: {e}")
        return False


def load_ue_string_table(data):
    """
    通用 UE StringTable 解析函数
    支持：
      - 根节点为 list / dict
      - 多个 StringTable 并存
    返回：
      dict: { key: localized_text }
    """
    result = {}

    if not data:
        return result

    # 情况 1：根节点是 list（最常见）
    if isinstance(data, list):
        for item in data:
            if not isinstance(item, dict):
                continue
            if item.get("Type") != "StringTable":
                continue

            table = item.get("StringTable", {})
            entries = table.get("KeysToEntries", {})
            if isinstance(entries, dict):
                result.update(entries)

    # 情况 2：根节点是 dict
    elif isinstance(data, dict):
        # 直接是 StringTable
        if data.get("Type") == "StringTable":
            entries = data.get("StringTable", {}).get("KeysToEntries", {})
            if isinstance(entries, dict):
                result.update(entries)

        # 或嵌套在子字段里
        for v in data.values():
            if isinstance(v, dict) and v.get("Type") == "StringTable":
                entries = v.get("StringTable", {}).get("KeysToEntries", {})
                if isinstance(entries, dict):
                    result.update(entries)

    return result
