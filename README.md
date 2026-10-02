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
├── main/                      ← 仓库本体（唯一的 .git 对象库），检出 main 分支
├── ExportScripts/             ← ExportScripts             分支（worktree）
├── GameOrganizeData/          ← GameOrganizeData          分支（worktree）
├── GameSourceDataCN/          ← GameSourceData/CN         分支（worktree）
├── GameSourceDataCN_TYF/      ← GameSourceData/CN_TYF     分支（worktree）
├── GameSourceDataInternational/ ← GameSourceData/International 分支（worktree）
└── GameSourceDataMobile/      ← GameSourceData/Mobile     分支（worktree）
```

### ⚠️ 本工作区使用 git worktree 共享对象库

**7 个文件夹并不是 7 个独立克隆**，而是「1 个仓库 + 6 个工作树」：

- **`main/` 是仓库本体**，只有它含真正的 `.git` 目录（对象库、refs、远端配置都在这里）
- 其余 6 个目录的 `.git` 是**一个文本文件**，内容形如 `gitdir: .../main/.git/worktrees/<目录名>`，指向本体中的元数据
- 因此 7 个目录**共用同一份对象库**。此前 7 个独立克隆各存一份约 400 MB 的历史，实测对象冗余率达 79%；改为 worktree 后合计只保留一份，省下约 1.6 GB

#### 三条操作规则（重要）

1. **不要删除或替换这 6 个目录里的 `.git` 文件**，否则该目录不再是仓库。需要移除某个工作树时，用 `git -C main worktree remove <目录>`。
2. **不要直接删除工作树目录**，会残留孤儿元数据。万一手工删了，用 `git -C main worktree prune` 清理。
3. **同一个分支不能同时在两个目录检出**（git 会拒绝）。本工作区是「一目录一分支」，天然满足。另外 `git gc` / `git repack` 现在作用于**整个共用对象库**，7 个目录会同时受影响。

查看当前工作树列表：

```bash
git -C main worktree list
```

### 从零搭出这套结构

```powershell
$url = 'https://github.com/lsy838545489/StrinovaBwiki.git'

# 1) 先克隆仓库本体（单分支即可，其余分支的对象在下一步 fetch）
git clone -b main --single-branch $url main

# 2) 分支名 -> 文件夹名，规则见上表
$worktrees = [ordered]@{
  'ExportScripts'                 = 'ExportScripts'
  'GameOrganizeData'              = 'GameOrganizeData'
  'GameSourceData/CN'             = 'GameSourceDataCN'
  'GameSourceData/CN_TYF'         = 'GameSourceDataCN_TYF'
  'GameSourceData/International'  = 'GameSourceDataInternational'
  'GameSourceData/Mobile'         = 'GameSourceDataMobile'
}
foreach ($kv in $worktrees.GetEnumerator()) {
  git -C main fetch origin "$($kv.Key):$($kv.Key)"
  git -C main worktree add (Join-Path (Get-Location) $kv.Value) $kv.Key
}
```

> **为什么要用 worktree**：本仓库 4 个数据分支各自的历史都接近 400 MB，且彼此高度重叠。独立克隆会让每份历史在磁盘上重复；worktree 让 7 个目录共享同一个对象库，下载与磁盘占用都只保留一份。
>
> 注意 `fetch <refspec>` 建出的本地分支**没有 upstream 跟踪**，工作树可以正常读写，但推送时需要显式指定远端与分支，例如 `git -C <目录> push origin <分支>:<分支>`；想省事可以补一次 `git -C <目录> branch --set-upstream-to=origin/<分支> <分支>`。
>
> 如果你只想要某一个分支的数据，也可以单独 `git clone -b <分支> --single-branch <url> <文件夹名>`。脚本只依赖「同级目录 + 上表的文件夹名」，不关心它是不是 worktree。

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
