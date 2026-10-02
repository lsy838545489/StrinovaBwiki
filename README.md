# Strinova BWiki 数据与脚本仓库

本仓库用于集中管理和维护 Strinova BWiki 相关的本地数据导出脚本、数据整理工具以及多地区游戏源数据。

## 📂 分支结构导航（重要）

本仓库采用多分支架构，不同类型的内容存放在相互独立的分支中，请根据需要切换查看。

**⚠️ 分支名与文件夹名并不字面相同**：本仓库在 Windows 环境下以「一个分支一个文件夹」的方式并列使用，而 Windows 文件名不允许包含 `/`，因此形如 `GameSourceData/CN` 的分支在落地为文件夹时会去掉 `/`、前后两段直接连写。转换规则与完整对照表如下。

### 分支 ↔ 文件夹对照表

| 分支名称 | 本地文件夹名 | 用途说明 | 主要包含内容 |
| :--- | :--- | :--- | :--- |
| **`main`** | `main` | **仓库说明与 WIKI 内容** | WIKI 模板、WIKI 模块、README |
| **`ExportScripts`** | `ExportScripts` | 源数据清洗脚本 | 用于将从游戏客户端提取原始数据清洗成 WIKI 侧可用结构的 Python 脚本 |
| **`GameOrganizeData`** | `GameOrganizeData` | 游戏整理数据 | 将源数据清洗、格式化后的整理数据 |
| **`GameSourceData/CN`** | `GameSourceDataCN` | 国服（CN）游戏源数据 | 国服解包 JSON/CSV/Lua 等原始数据 |
| **`GameSourceData/CN_TYF`** | `GameSourceDataCN_TYF` | 国服体验服（TYF）源数据 | 体验服解包数据 |
| **`GameSourceData/International`** | `GameSourceDataInternational` | 国际服源数据 | 国际服解包数据 |
| **`GameSourceData/Mobile`** | `GameSourceDataMobile` | 移动端源数据 | 移动端解包数据 |

### 文件夹命名规则

- **不含 `/` 的分支**：文件夹名与分支名完全一致，例如分支 `ExportScripts` → 文件夹 `ExportScripts`。
- **含 `/` 的分支**：去掉 `/`，前后两段直接连写，例如分支 `GameSourceData/CN_TYF` → 文件夹 `GameSourceDataCN_TYF`。

### 推荐目录结构

各分支需要并列存放在同一层，脚本会按「同级目录」查找彼此：

```
StrinovaBwiki/                 ← 工作区根目录（本身不是 git 仓库，无需 git init）
├── main/                      ← main                      分支
├── ExportScripts/             ← ExportScripts             分支
├── GameOrganizeData/          ← GameOrganizeData          分支
├── GameSourceDataCN/          ← GameSourceData/CN         分支
├── GameSourceDataCN_TYF/      ← GameSourceData/CN_TYF     分支
├── GameSourceDataInternational/ ← GameSourceData/International 分支
└── GameSourceDataMobile/      ← GameSourceData/Mobile     分支
```

一次性拉取全部 7 个分支（PowerShell，在空目录中执行）：

```powershell
$url = 'https://github.com/lsy838545489/StrinovaBwiki.git'
# 分支名 -> 文件夹名，规则见上表
$branches = [ordered]@{
  'main'                          = 'main'
  'ExportScripts'                 = 'ExportScripts'
  'GameOrganizeData'              = 'GameOrganizeData'
  'GameSourceData/CN'             = 'GameSourceDataCN'
  'GameSourceData/CN_TYF'         = 'GameSourceDataCN_TYF'
  'GameSourceData/International'  = 'GameSourceDataInternational'
  'GameSourceData/Mobile'         = 'GameSourceDataMobile'
}
foreach ($kv in $branches.GetEnumerator()) {
  git clone -b $kv.Key --single-branch $url $kv.Value
}
```

> `--single-branch` 很重要：本仓库各数据分支体量很大且历史互相包含，按单分支克隆可以显著减少下载量。

## 🔄 数据流转与工作流

1. **清洗**：`ExportScripts` 中的脚本用于清洗各 `GameSourceData*` 文件夹中的原始数据。
2. **整理**：`GameOrganizeData` 存放清洗为 WIKI 侧可用格式后的整理数据。
3. **WIKI**：`main` 存放 WIKI 侧的模板与模块，可通过 `wiki_sync.py` 与线上 WIKI 增量同步。

## 🛠️ 如何使用

- **如果你是想获取游戏源数据**：请直接克隆对应地区的分支（如 `GameSourceData/CN` → 文件夹 `GameSourceDataCN`）。
- **如果你是想参与数据清洗**：请切换至 `ExportScripts` 分支。
- **如果你是想查看整理的数据**：请查看 `GameOrganizeData` 分支。
- **如果你是想维护 WIKI 模板与模块**：请切换至 `main` 分支。该分支的 README 为各分支内容的总说明。

## ⚠️ 数据来源与免责声明

- 本仓库所有游戏源数据均来自游戏客户端解包，版权归游戏开发商/发行商所有。
- 数据仅供 Strinova BWiki 建设与玩家交流使用，严禁用于商业用途。

## 🔗 相关链接

- [Strinova BWiki 主页](https://wiki.biligame.com/klbq/%E9%A6%96%E9%A1%B5)
