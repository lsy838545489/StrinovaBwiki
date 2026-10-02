# modules/generate_zombie_talent.py
import re
from pathlib import Path
from utils.common import load_json_file, PROJECT_ROOT

def export_zombie_talent_data():
    print("开始处理天赋数据...")
    # 稀有度映射表
    custom_keys = {
        "id": "id",
        "name": "name",
        "teamType": "teamType",
        "file": "file",
        "desc": "desc"
    }

    # 阵营映射表
    value_to_TeamType_name = {
        "ECyAttributeBuffTeamType::Zombie": "晶源体",
        "ECyAttributeBuffTeamType::Human": "超弦体"
    }

    # 加载天赋源数据
    Talent_data = load_json_file("GameplayAttributeBuff")

    def convert_numbers(arr):
        if not isinstance(arr, (list, tuple)):
            arr = [arr]

        result = []
        for item in arr:
            # 尝试转换为字符串处理
            s = str(item).strip()

            # 不是数字格式（包含字母等）则保持原样
            try:
                num = float(s)
            except ValueError:
                result.append(item)
                continue

            # 判断是否是整数值（小数部分为 0）
            if num.is_integer():
                result.append(int(num))
            else:
                result.append(num)

        return result

    def fill_desc(template: str, params: list):
        """
        将模板文本中的 {0},{1},... 用 params 填入。
        params 为列表，0-based 输入。
        """
        if not template:
            return template

        def repl(match):
            idx = int(match.group(1))
            return str(params[idx]) if idx < len(params) else ""

        return re.sub(r"\{\s*(\d+)\s*\}", repl, template)

    output_data = []
    name_counter = {}  # 记录每个原始名称已出现的次数

    for item in Talent_data:
        for row in item['Rows'].values():
            ID = int(row['BuffId'])
            original_name = row['BuffName']['LocalizedString']

            # 处理重复名称：根据已出现次数添加对应数量的 '+'
            cnt = name_counter.get(original_name, 0)
            if cnt > 0:
                talent_name = original_name + '+' * cnt
            else:
                talent_name = original_name
            name_counter[original_name] = cnt + 1

            # 阵营与稀有度
            TeamType_value = value_to_TeamType_name.get(row.get('TeamType'), row.get('TeamType'))

            asset_path_name = row['IconItem'].get('AssetPathName', '')
            tail_number = asset_path_name.split('_')[-1].split('.')[0]

            # 原始描述文本（带 {0} {1}）
            desc_template = row['BuffDesc'].get('LocalizedString', '')
            params = row["BuffNum"]
            params = convert_numbers(params)
            filled = fill_desc(desc_template, params)

            extracted_data = {
                "id": ID,
                "name": talent_name,
                "teamType": TeamType_value,
                "file": f"道具图标_{tail_number}.png",
                "desc": filled,
            }
            custom_data = {custom_keys[key]: value for key, value in extracted_data.items()}
            output_data.append(custom_data)

    # ==================== 生成 MediaWiki 表格 ====================
    wiki_lines = []
    wiki_lines.append('{| class="klbqtable"')
    wiki_lines.append('|-')
    wiki_lines.append('! 名称')
    wiki_lines.append('! 阵营')
    wiki_lines.append('! 描述')
    wiki_lines.append('! 可用期数')

    for data in output_data:
        # 第一列：file + <br> + name
        col1 = f"[[文件:{data['file']}|80px]]<br><big>'''{data['name']}'''</big>"
        col2 = data['teamType']
        col3 = data['desc']

        wiki_lines.append('|-')
        wiki_lines.append(f'| class="text-center"|{col1}')
        wiki_lines.append(f'| {col2}')
        wiki_lines.append(f'| {col3}')
        wiki_lines.append(f'|')

    wiki_lines.append('|}')

    wiki_content = '\n'.join(wiki_lines)

    # 保存为 txt 文件
    data_dir = Path(PROJECT_ROOT) / "data"
    data_dir.mkdir(parents=True, exist_ok=True)

    output_path = data_dir / "zombie_talent_wiki_table.txt"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(wiki_content)

    print(f"MediaWiki 表格已导出至: {output_path}")
    print("天赋数据处理并分拆导出完成！")
