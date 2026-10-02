# Strinova BWiki 数据与脚本仓库

本仓库用于集中管理和维护 Strinova BWiki 相关的本地数据导出脚本、数据整理工具以及多地区游戏源数据。

## 📂 分支结构导航（重要）

本仓库采用多分支架构，不同类型的内容存放在独立的分支中，请根据需要切换查看：

| 分支名称 | 用途说明 | 主要包含内容 |
| :--- | :--- | :--- |
| **`main`** | **仓库说明与WIKI内容（当前分支）** | WIKI模板、WIKI模块、README |
| **`ExportScripts`** | 本地数据导出脚本 | 用于从游戏客户端提取原始数据的 Python/Node 脚本 |
| **`GameOrganizeData`** | 游戏整理数据 | 将源数据清洗、格式化后的整理数据 |
| **`GameSourceData/CN`** | 国服（CN）游戏源数据 | 国服解包 JSON/CSV/Lua 等原始数据 |
| **`GameSourceData/CN_TYF`** | 国服体验服（TYF）源数据 | 体验服解包数据 |
| **`GameSourceData/International`** | 国际服源数据 | 国际服解包数据 |
| **`GameSourceData/Mobile`** | 移动端源数据 | 移动端解包数据 |

## 🔄 数据流转与工作流

1. **整理**：运行 `ExportScripts` 分支中的脚本，获取 `GameSourceData/*` 原始数据。
2. **导出**： `GameOrganizeData` 是将原始数据清洗为 Wiki 侧可用格式后的数据。
3. **WIKI**：`main` 存放着 WIKI 侧的模板与模块。

## 🛠️ 如何使用

- **如果你是想获取游戏源数据**：请直接切换对应地区的分支（如 `GameSourceData/CN`）下载或克隆。
- **如果你是想参与数据导出**：请切换至 `ExportScripts` 分支查看具体的使用说明。
- **如果你是想查看整理的数据**：请查看 `GameOrganizeData` 分支。

## ⚠️ 数据来源与免责声明

- 本仓库所有游戏源数据均来自游戏客户端解包，版权归游戏开发商/发行商所有。
- 数据仅供 Strinova BWiki 建设与玩家交流使用，严禁用于商业用途。

## 🔗 相关链接

- [Strinova BWiki 主页](https://wiki.biligame.com/klbq/%E9%A6%96%E9%A1%B5)
