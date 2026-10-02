# main_mobile.py
from modules_mobile.generate_items import export_items_data
from modules_mobile.generate_chat_bubbles import export_chat_bubbles_data
from modules_mobile.generate_emote import export_emote_data
from modules_mobile.generate_decal import export_decal_data
from modules_mobile.generate_badge import export_badge_data
from modules_mobile.generate_vehicle_skin import export_vehicle_skin_data
from modules_mobile.generate_hud_skin import export_hud_skin_data
from modules_mobile.generate_head_sculpture import export_head_sculpture_data
import sys
import os

# 确保能正确引入模块
PROJECT_ROOT = r"Z:\Gitee\StrinovaBwikiScript"
sys.path.append(PROJECT_ROOT)


def main_menu():
    actions = {
        "1": export_badge_data,
        "2": export_chat_bubbles_data,
        "3": export_decal_data,
        "4": export_emote_data,
        "5": export_items_data,
        "6": export_vehicle_skin_data,
        "7": export_hud_skin_data,
        "8": export_head_sculpture_data,
    }
    while True:
        print("\n" + "=" * 40)
        print("  WIKI 数据整理与自动化上传工具  ")
        print("=" * 40)
        print("1. 生成徽章数据 (Badge)")
        print("2. 生成聊天气泡数据 (ChatBubbles)")
        print("3. 生成喷漆数据 (Decal)")
        print("4. 生成表情数据 (Emote)")
        print("5. 生成道具数据 (Items)")
        print("6. 生成载具外观数据 (VehicleSkin)")
        print("7. 生成按键外观数据 (HudSkin)")
        print("8. 生成头像和头像框数据 (HeadSculpture)")

        print("0. 退出程序")
        print("=" * 40)

        choice = input("请输入对应的数字执行任务喵: ").strip()

        if choice == "0":
            print("再见喵！")
            break

        action = actions.get(choice)

        if action:
            action()
        else:
            print("输入无效，请重新输入喵！")


if __name__ == "__main__":
    main_menu()
