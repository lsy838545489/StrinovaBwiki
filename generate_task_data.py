import os
from utils.common import load_json_file, PROJECT_ROOT


def export_activity_task_data(data_dir: str, activity_id: int = 10229):
    """
    提取并导出活动任务 (ActivityTask) 数据至 MediaWiki 表格
    :param data_dir: 文本文件输出目录
    :param activity_id: 目标活动的 ID（默认为 10229）
    """
    print(f"开始处理活动任务 (ActivityTask) 数据 (ActivityId: {activity_id}) 喵...")

    activity_task_data = load_json_file("ActivityTask")
    if not activity_task_data:
        print("未加载到 ActivityTask 数据，跳过任务导出。")
        return

    task_keys = {
        "task": "任务",
        "task_amounts": "获得点数"
    }

    output_activity_task = []

    # 1. 数据提取与字段映射
    for item in activity_task_data:
        for row in item.get('Rows', {}).values():
            # 使用传入的 activity_id 参数进行过滤
            if row.get("ActivityId") == activity_id:
                task = row.get('Desc', {}).get('LocalizedString', '')

                # 安全获取奖励点数（防空列表或结构缺失）
                prize_list = row.get('Prize', [])
                task_amounts = prize_list[0]['ItemAmount'] if prize_list else 0

                extracted_data = {
                    "task": task,
                    "task_amounts": task_amounts
                }

                # 使用 task_keys 进行字典键名映射
                custom_data = {task_keys[key]: value for key, value in extracted_data.items()}
                output_activity_task.append(custom_data)

    # 2. 生成 MediaWiki 表格文本
    lines = [
        '{| class="klbqtable"',
        '! 任务\n! 获得点数'
    ]

    for item in output_activity_task:
        lines.append("|-")
        lines.append(f"| {item['任务']}\n| {item['获得点数']}")

    lines.append("|}")

    # 3. 写入文件
    output_path = os.path.join(data_dir, "活动任务.txt")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"活动任务数据已成功保存至 data/活动任务.txt 喵！")


def export_activity_common_milestone_data(data_dir: str, activity_id: int = 10226):
    """
    提取并导出活动里程碑 (ActivityCommonMilestone) 数据至 MediaWiki 表格
    :param data_dir: 文本文件输出目录
    :param activity_id: 目标活动的 ID（默认为 10226）
    """
    print(f"开始处理活动里程碑 (ActivityCommonMilestone) 数据 (ActivityId: {activity_id}) 喵...")

    activity_common_milestone_data = load_json_file("ActivityCommonMilestone")
    if not activity_common_milestone_data:
        print("未加载到 ActivityCommonMilestone 数据，跳过里程碑导出。")
        return

    output_activity_common_milestone = []

    # 1. 数据提取与条件过滤（使用传入的 activity_id 参数，且无 LocalizedString 时跳过）
    for item in activity_common_milestone_data:
        for row in item.get('Rows', {}).values():
            if row.get("ActivityId") == activity_id:
                describe_obj = row.get("Decribe")

                # 检查 row["Decribe"] 是否为字典，且内部包含有效的 ["LocalizedString"]
                if isinstance(describe_obj, dict) and describe_obj.get("LocalizedString"):
                    describe = describe_obj["LocalizedString"]
                    output_activity_common_milestone.append({"describe": describe})

    # 2. 生成 MediaWiki 表格文本
    lines = [
        '{| class="klbqtable"',
        '! 累计积分数量\n! 奖励'
    ]

    for item in output_activity_common_milestone:
        lines.append("|-")
        lines.append(f"| {item['describe']}")
        lines.append(f"| ")

    lines.append("|}")

    # 3. 写入文件
    output_path = os.path.join(data_dir, "活动里程碑.txt")
    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"活动里程碑数据已成功保存至 data/活动里程碑.txt 喵！")


def export_activity_data(activity_id: int = 10229):
    """
    主入口函数：同时调度任务与里程碑导出，支持独立指定各自的 ActivityId
    :param task_activity_id: 传递给任务导出的 ActivityId
    """
    print("====== 开始处理活动相关数据 ======")
    data_dir = os.path.join(PROJECT_ROOT, "data")
    os.makedirs(data_dir, exist_ok=True)

    # 传递可配置的 activity_id 参数
    export_activity_task_data(data_dir, activity_id)
    export_activity_common_milestone_data(data_dir, activity_id)

    print("====== 活动相关数据全量处理完成喵！ ======")


if __name__ == "__main__":
    # 支持单独运行测试（例如传入新的活动 ID）
    export_activity_data(activity_id=10236)
