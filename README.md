# Strinova B Wiki 数据与脚本仓库

本仓库用于集中管理和维护 Strinova B Wiki 相关的本地数据导出脚本、数据整理工具以及多地区游戏源数据。

## 📂 分支结构导航（重要）

本仓库采用多分支架构，不同类型的内容存放在独立的分支中，请根据需要切换查看：

| 分支名称 | 用途说明 | 主要包含内容 |
| :--- | :--- | :--- |
| **`main`** | **仓库说明与导航（当前分支）** | README、协作规范、数据字典、Issue模板 |
| **`ExportScripts`** | 本地数据导出脚本 | 用于从游戏客户端提取原始数据的 Python/Node 脚本 |
| **`GameOrganizeData`** | 游戏数据整理脚本/中间产物 | 将源数据清洗、格式化、转换为 Wiki 可用格式的脚本 |
| **`GameSourceData/CN`** | 国服（CN）游戏源数据 | 国服解包 JSON/CSV/Lua 等原始数据 |
| **`GameSourceData/CN_TYF`** | 国服体验服（TYF）源数据 | 体验服解包数据 |
| **`GameSourceData/International`** | 国际服源数据 | 国际服解包数据 |
| **`GameSourceData/Mobile`** | 移动端源数据 | 移动端解包数据 |

## 🔄 数据流转与工作流

1. **导出**：运行 `ExportScripts` 分支中的脚本，获取 `GameSourceData/*` 原始数据。
2. **整理**：使用 `GameOrganizeData` 分支的工具，将原始数据清洗为 Wiki 侧可用的格式。
3. **录入**：将整理后的数据提交到 B Wiki 侧（注：WIKI 侧的模板与模块可能存放于其他仓库或分支，如 `wiki/templates-modules`，此处需根据实际情况补充）。

## 🛠️ 如何使用

- **如果你是想获取游戏源数据**：请直接切换对应地区的分支（如 `GameSourceData/CN`）下载或克隆。
- **如果你是想参与数据导出**：请切换至 `ExportScripts` 分支查看具体的使用说明。
- **如果你是想参与数据整理**：请查看 `GameOrganizeData` 分支。

## 🤝 贡献指南

- 提交 Issue 时，请注明涉及的具体分支和地区。
- 提交 Pull Request 时，请确保目标分支正确。
- **注意**：请勿在 `main` 分支直接提交代码或数据，`main` 仅保留文档更新。

## ⚠️ 数据来源与免责声明

- 本仓库所有游戏源数据均来自游戏客户端解包，版权归游戏开发商/发行商所有。
- 数据仅供 Strinova B Wiki 建设与玩家交流使用，严禁用于商业用途。

## 🔗 相关链接

- [Strinova B Wiki 主页](链接地址)
- [其他相关仓库](链接地址)
