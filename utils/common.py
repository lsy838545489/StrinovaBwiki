import sys
import json
import os
import re
import mwclient
import time
import rookiepy
from datetime import datetime

# 设置项目根目录
PROJECT_ROOT = r"Z:\GitHub\StrinovaBwikiScript"  # 使用原始字符串以防止转义字符问题
os.chdir(PROJECT_ROOT)  # 更改当前工作目录为项目根目录

# 导入所需模块
sys.path.append(PROJECT_ROOT)


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
}

# 稀有度ID和稀有度名称的映射
id_to_Quality_name = {
    0: "初始",
    2: "精致",
    3: "卓越",
    4: "完美",
    5: "传说",
    6: "私服",
    8: "臻藏",
}

DEFAULT_FOLDERS = [
    r"Z:\GitHub\CN\PaperMan\CSV\\",
    r"Z:\GitHub\CN\PaperMan\CyTable\StringTable\\",
]


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


def export_data_file(fileName, data, fileType='json'):
    """
    通用导出与备份函数喵！
    :param fileName: 不带扩展名的文件名 (如 "ProfileData")
    :param data: 要保存的数据。如果是 json 类型则传入字典/列表，如果是 lua 类型则传入格式化好的字符串
    :param fileType: 'json' 或 'lua'
    """
    outputDir = os.path.join(PROJECT_ROOT, "data")
    os.makedirs(outputDir, exist_ok=True)

    # 2. 根据类型确定扩展名
    fileExt = ".json" if fileType.lower() == 'json' else ".lua"
    filePath = os.path.join(outputDir, f"{fileName}{fileExt}")

    # 3. 备份逻辑：如果旧文件存在，重命名为带日期的备份
    if os.path.exists(filePath):
        dateStr = datetime.now().strftime("%Y%m%d")
        backupPath = os.path.join(outputDir, f"{fileName}_{dateStr}{fileExt}")

        # 如果当天已经备份过，先移除旧的备份
        if os.path.exists(backupPath):
            os.remove(backupPath)

        os.rename(filePath, backupPath)
        print(f"检测到旧文件，已备份至: {os.path.basename(backupPath)} 喵！")

    # 4. 根据类型执行不同的写入操作
    try:
        with open(filePath, 'w', encoding='utf-8') as f:
            if fileType.lower() == 'json':
                json.dump(data, f, ensure_ascii=False, indent=4)
            else:
                f.write(data)
        print(f"成功保存 {fileType.upper()} 文件: {os.path.basename(filePath)} 喵！")
    except Exception as e:
        print(f"写入文件失败了喵！错误信息: {e}")
