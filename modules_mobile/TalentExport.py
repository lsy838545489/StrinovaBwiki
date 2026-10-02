import sys
import os
import json
from pathlib import Path

# ========== 配置区 ==========
PROJECT_ROOT = r'Z:\BwikiScript'
os.chdir(PROJECT_ROOT)
sys.path.append(PROJECT_ROOT)
from common_mobile import load_json_file, save_with_backup
# ===========================

ability_type_id_to_name = {
    1: "输出",
    2: "机能",
    3: "续航",
    4: "生存"
}

def number_to_percent_or_number(val):
    if val is None:
        return None
    if isinstance(val, (int, float)):
        if isinstance(val, float) and not val.is_integer():
            return f"{val * 100:.6f}".rstrip('0').rstrip('.') + "%"
        if isinstance(val, float) and val.is_integer():
            return int(val)
        return val
    return val

def wiki_escape(s):
    """对写入 MediaWiki 表格单元格的文本做基本转义（保留 HTML 标签用于 <ul><li>）"""
    if s is None:
        return ""
    s = str(s)
    # 不转义 < 或 >，以便保留 <ul><li>
    s = s.replace('|', '&#124;')
    s = s.replace('\r', '')
    s = s.replace('\n', '<br>')
    return s

# ========== 读取并构建 grouped（与你原脚本保持一致） ==========
talent_data = load_json_file("Talent")  # 假设返回 list/dict 的导出结构

grouped = {}
for item in talent_data:
    rows = item.get('Rows', {}) if isinstance(item, dict) else {}
    for row in rows.values():
        raw_ability = row.get('AbilityType', None)
        ability_type_name = ability_type_id_to_name.get(raw_ability, str(raw_ability) if raw_ability is not None else "Unknown")

        talent_id = row.get('TalentId')
        if talent_id in (None, "", 0):
            continue
        talent_id_str = str(talent_id)

        name_obj = row.get('Name', {})
        name_local = name_obj.get('LocalizedString') if isinstance(name_obj, dict) else ""
        begin_lv = row.get('BeginLv')

        ability_level = row.get('AbilityLevel')
        detail_obj = row.get('Detail', {})
        detail_local = detail_obj.get('LocalizedString') if isinstance(detail_obj, dict) else ""
        number_raw = row.get('Number')
        number_processed = number_to_percent_or_number(number_raw)
        costnum = row.get('CostNum')

        row_id = row.get('Id')
        if row_id in (None, "", 0):
            row_id = row.get('AbilityLevel', f"{talent_id}_auto")
        row_id_str = str(row_id)

        if ability_type_name not in grouped:
            grouped[ability_type_name] = {}

        if talent_id_str not in grouped[ability_type_name]:
            grouped[ability_type_name][talent_id_str] = {
                "Name": name_local if name_local is not None else "",
                "BeginLv": begin_lv if begin_lv is not None else "",
                "Levels": {}
            }
        else:
            if (grouped[ability_type_name][talent_id_str].get("Name") in (None, "")) and (name_local not in (None, "")):
                grouped[ability_type_name][talent_id_str]["Name"] = name_local
            if grouped[ability_type_name][talent_id_str].get("BeginLv") in (None, "") and begin_lv not in (None, ""):
                grouped[ability_type_name][talent_id_str]["BeginLv"] = begin_lv

        # 存下 level 数据：保留 AbilityLevel、Detail（描述+百分比/数值）和 CostNum
        detail_combined = (detail_local or "") + (str(number_processed) if number_processed not in (None, "") else "")
        grouped[ability_type_name][talent_id_str]["Levels"][row_id_str] = {
            "AbilityLevel": ability_level,
            "Detail": detail_combined,
            "CostNum": costnum if costnum is not None else None
        }

# ========== 保存 JSON（与备份） ==========
out_dir = Path('.', 'MobileBatch', 'NewData')
out_dir.mkdir(parents=True, exist_ok=True)
json_path = out_dir / '天赋.json'
try:
    save_with_backup(str(json_path), grouped)
except Exception:
    with open(json_path, 'w', encoding='utf-8') as jf:
        json.dump(grouped, jf, ensure_ascii=False, indent=2)

# ========== 生成 WIKI 表格 ==========
wiki_path = out_dir / '天赋.wiki'
with open(wiki_path, 'w', encoding='utf-8') as wf:
    for ability in sorted(grouped.keys()):
        wf.write(f"== {wiki_escape(ability)} ==\n")
        wf.write('<div style="overflow-x: auto;">\n')
        wf.write('{| class="klbqtable" style="min-width: 60rem;"\n')
        wf.write("! 名称\n! 解锁等级\n! 最大等级\n! 天赋等级详情\n")

        # 将 talents 按键（TalentId）排序并构建每行数据（每行代表一个 Talent）
        talent_rows = []
        for tid in sorted(grouped[ability].keys(), key=lambda x: int(x) if str(x).isdigit() else x):
            t = grouped[ability][tid]
            name_val = t.get('Name', '')
            display_name = f"[[文件:天赋图标_{tid}.png|100px]]<br /><big>'''{name_val}'''</big>"
            begin_lv = t.get('BeginLv', '')
            # 计算最大等级（从 Levels 中的 AbilityLevel 字段取最大）
            levels = t.get('Levels', {})
            lvl_list = []
            max_level_val = None
            for lvl_key, lvl_data in levels.items():
                alv = lvl_data.get('AbilityLevel')
                try:
                    alv_sort = int(alv) if alv is not None else None
                except:
                    alv_sort = alv
                lvl_list.append((alv_sort, lvl_data))
                if isinstance(alv_sort, int):
                    max_level_val = alv_sort if (max_level_val is None or alv_sort > max_level_val) else max_level_val
            # 如果没有 AbilityLevel 字段，尝试用 levels 键数量作为最大等级
            if max_level_val is None:
                try:
                    max_level_val = max([int(k) for k in levels.keys() if str(k).isdigit()]) if levels else ""
                except:
                    max_level_val = len(levels) if levels else ""
            # 构建等级详情的 HTML 无序列表（按等级排序）
            lvl_list_sorted = sorted(lvl_list, key=lambda x: (x[0] is None, x[0]))  # None 放后
            ul_items = []
            for alv_sort, lvl_data in lvl_list_sorted:
                display_level = alv_sort if alv_sort is not None else ""
                detail_text = lvl_data.get('Detail', '') or ""
                costnum = lvl_data.get('CostNum', '')
                # 细节格式：1级：描述 （消耗点数：1）
                if costnum not in (None, "", 0):
                    item = f"{display_level}级：{detail_text} （消耗点数：{costnum}）"
                else:
                    item = f"{display_level}级：{detail_text}"
                ul_items.append(item)
            details_html = "\n" + "\n".join(f"* {wiki_escape(x)}" for x in ul_items) if ul_items else ""

            talent_rows.append({
                "name": display_name,
                "beginLv": begin_lv,
                "maxLv": max_level_val,
                "details_html": details_html
            })

        # 遍历 talent_rows，检测连续相同的 (name, beginLv, maxLv) 并合并 rowspan
        i = 0
        n = len(talent_rows)
        while i < n:
            # 找到 run 长度
            cur = talent_rows[i]
            run_len = 1
            j = i + 1
            while j < n and talent_rows[j]["name"] == cur["name"] and str(talent_rows[j]["beginLv"]) == str(cur["beginLv"]) and str(talent_rows[j]["maxLv"]) == str(cur["maxLv"]):
                run_len += 1
                j += 1

            # 对该 run，依次写入行：首行写入并对前三列使用 rowspan (若 run_len>1)
            for k in range(run_len):
                row = talent_rows[i + k]
                wf.write("|-\n")
                if k == 0:
                    # 首行：写入名称/解锁等级/最大等级（可能带 rowspan）
                    if run_len > 1:
                        wf.write(f'| rowspan="{run_len}"|{row["name"]} || rowspan="{run_len}" | {wiki_escape(row["beginLv"])} || rowspan="{run_len}" | {wiki_escape(row["maxLv"])} || {row["details_html"]}\n')
                    else:
                        wf.write(f'! class="text-center"|{row["name"]}\n| {wiki_escape(row["beginLv"])}\n| {wiki_escape(row["maxLv"])}\n| {row["details_html"]}\n')
                else:
                    # 后续行：前三列被 rowspan 覆盖，所以这一行只写 天赋等级详情 列
                    wf.write(f'| {row["details_html"]}\n')
            i += run_len

        wf.write("|}\n</div>\n\n")

print("导出完成：", str(json_path), str(wiki_path))