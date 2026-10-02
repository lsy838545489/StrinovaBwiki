# modules_mobile/generate_role_proficiency.py
import os
import json
from collections import OrderedDict

from utils.common_mobile import load_json_file, id_to_Role_name, DATA_ROOT

TYPE_MAP = {1: "通用", 2: "进阶"}   # 可按需补充或改写
INPUT_NAME = "RoleProficiencyTask"


def wiki_escape(s):
    """对写入 MediaWiki 单元格的文本做基本转义：竖线| -> &#124;，换行 -> <br>"""
    if s is None:
        return ""
    s = str(s)
    s = s.replace('|', '&#124;')
    s = s.replace('\r', '')
    s = s.replace('\n', '<br>')
    return s


def format_prizes(prizes_list):
    """把 prizes 列表格式化为单个字符串，每个奖励一行，例如：ItemId:50 ×200"""
    if not prizes_list:
        return ""
    parts = []
    for p in prizes_list:
        if not isinstance(p, dict):
            continue
        item_id = p.get("itemId", "")
        item_amount = p.get("itemAmount", "")
        parts.append(f"ItemId:{item_id} ×{item_amount}")
    return "<br>".join(parts)


def export_role_proficiency_data():
    print("开始处理角色熟练度任务(RoleProficiencyTask)数据喵...")

    out_dir = os.path.join(DATA_ROOT, "data")
    os.makedirs(out_dir, exist_ok=True)
    out_json = os.path.join(out_dir, "RoleProficiencyTask.json")
    out_wiki = os.path.join(out_dir, "RoleProficiencyTask.txt")

    # 读取数据，兼容几种导出包装格式
    data = load_json_file(INPUT_NAME)

    rows_iter = []
    if isinstance(data, dict):
        if "Rows" in data and isinstance(data["Rows"], dict):
            rows_iter = data["Rows"].values()
        else:
            for item in data.values():
                if isinstance(item, dict) and "Rows" in item and isinstance(item["Rows"], dict):
                    rows_iter.extend(item["Rows"].values())
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict) and "Rows" in item and isinstance(item["Rows"], dict):
                rows_iter.extend(item["Rows"].values())

    output = {}   # role_name -> list of tasks

    for row in rows_iter:
        if not isinstance(row, dict):
            continue
        try:
            # Desc 提取（兼容多种结构）
            desc = None
            desc_field = row.get("Desc")
            if isinstance(desc_field, dict):
                desc = desc_field.get("LocalizedString") or desc_field.get("SourceString") or desc_field.get("Value")
            elif isinstance(desc_field, str):
                desc = desc_field
            if not desc or str(desc).strip().lower() == "null":
                continue

            role_id = row.get("RoleId", "")
            role_name = id_to_Role_name.get(role_id, role_id if role_id != "" else "UnknownRole")
            task_type = TYPE_MAP.get(row.get("ProficiencyTask"), row.get("ProficiencyTask", ""))

            # 提取 prizes（ItemId 与 ItemAmount）
            prizes_raw = row.get("Prize")
            prizes = []
            if isinstance(prizes_raw, list):
                for p in prizes_raw:
                    if not isinstance(p, dict):
                        continue
                    item_id = p.get("ItemId")
                    item_amount = p.get("ItemAmount")
                    if item_id is not None or item_amount is not None:
                        prizes.append({"itemId": item_id if item_id is not None else "", "itemAmount": item_amount if item_amount is not None else 0})

            # 注意：这里有意舍弃 id 字段（不写入 wiki 表）
            task = {
                "type": task_type,
                "desc": desc,
            }
            if prizes:
                task["prizes"] = prizes

            output.setdefault(str(role_name), []).append(task)
        except Exception as e:
            print(f"⚠️ 跳过一个异常任务行：{e!r}")
            continue

    if not output:
        print("未提取到任何熟练度任务数据，跳过导出。")
        return

    # 保存 JSON
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=4)
    print(f"角色熟练度任务 JSON 已保存至 data/RoleProficiencyTask.json 喵！")

    # 写出 WIKI 表格（按角色分小节），合并同一类型的单元格（使用 rowspan）
    with open(out_wiki, "w", encoding="utf-8") as f:
        for role_name, tasks in output.items():
            f.write(f"== {wiki_escape(role_name)} ==\n")
            f.write('{| class="klbqtable"\n')
            f.write("! 任务类型\n! 描述\n! 奖励\n")

            # 将任务按 type 分组，保持 type 首次出现顺序
            groups = OrderedDict()
            for t in tasks:
                key = str(t.get("type", ""))
                groups.setdefault(key, []).append(t)

            # 对每个分组写入表格：首行包含带 rowspan 的类型单元格，其余行仅写 描述 与 奖励
            for type_value, group_tasks in groups.items():
                rowspan = len(group_tasks)
                for i, t in enumerate(group_tasks):
                    desc_cell = wiki_escape(t.get("desc", ""))
                    prizes_cell = wiki_escape(format_prizes(t.get("prizes", [])))
                    f.write("|-\n")
                    if i == 0:
                        if rowspan > 1:
                            f.write(f'| rowspan="{rowspan}"|{wiki_escape(type_value)}\n| {desc_cell}\n| {prizes_cell}\n')
                        else:
                            f.write(f'| {wiki_escape(type_value)}\n| {desc_cell}\n| {prizes_cell}\n')
                    else:
                        f.write(f'| {desc_cell}\n| {prizes_cell}\n')
            f.write("|}\n\n")

    print("角色熟练度任务(RoleProficiencyTask)数据处理完成喵！")


if __name__ == "__main__":
    export_role_proficiency_data()
