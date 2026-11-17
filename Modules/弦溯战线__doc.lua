本模块负责《卡拉彼丘》「弦溯战线」搜打撤模式的图鉴展示：

* [[战斗模式/弦溯战线/物品图鉴|物品图鉴]] —— 159 件可搜刮物
* [[战斗模式/弦溯战线/配件图鉴|配件图鉴]] —— 127 件枪械配件

模块只负责「取数 + 拼卡片参数」，'''不产出任何 HTML / CSS / 脚本'''：卡片结构与样式在模板里，筛选与排序的交互由 [[Widget:CardSelectGallery]] 承担。字段口径、参数约定与维护须知见本页。

== 调用方式 ==
{| class="wikitable"
! 写法 !! 说明
|-
| <nowiki>{{#invoke:弦溯战线|图鉴}}</nowiki> || 物品图鉴
|-
| <nowiki>{{#invoke:弦溯战线|配件图鉴}}</nowiki> || 配件图鉴
|-
| <nowiki>隐藏计数=1</nowiki> || 不输出顶部「共 N 件物品」计数行
|-
| <nowiki>调试=1</nowiki> || 数据加载失败时把失败原因一并输出
|}

== 数据来源 ==
{| class="wikitable"
! 页面 !! 内容 !! 条数 !! 生成脚本
|-
| 模块:弦溯战线/物品Data || 可搜刮物 || 159 || <code>ExportScripts/<wbr>modules/<wbr>generate_sec_items.py</code>
|-
| 模块:弦溯战线/配件Data || 枪械配件 || 127 || <code>ExportScripts/<wbr>modules/<wbr>generate_sec_attachments.py</code>
|}

数据子页面由仓库里的导出脚本生成后推送，'''不要手工编辑'''；要改字段口径请改脚本再重跑导出并推送。

== 依赖 ==
* [[模板:Gallerygrid]] —— 通用画廊容器
* [[模板:Gallerygrid/弦溯战线物品]] / [[模板:Gallerygrid/弦溯战线配件]] —— 卡片结构与样式
* [[模板:弦溯战线物品筛选栏]] / [[模板:弦溯战线配件筛选栏]] —— 筛选面板
* [[模板:弦溯战线筛选栏样式]] —— 两个筛选栏共用的面板 CSS
* [[Widget:CardSelectGallery]] —— 筛选与排序的交互实现（共用组件，改动会影响全站使用它的页面）

== 品质编号 ==
本模式的品质编号与主游戏'''不同'''，不能复用 <code>模块:卡拉彼丘.qualityNumToName</code>：

{| class="wikitable"
! 编号 !! 1 !! 2 !! 3 !! 4 !! 5 !! 6 !! 8
|-
! 弦溯战线 !! 优秀 !! 精致 !! 卓越 !! 完美 !! 臻藏 !! 传说 !! （无名）
|-
! 主游戏 !! 初始 !! 精致 !! 卓越 !! 完美 !! 传说 !! 臻藏 !! 臻藏
|}

== 卡片参数约定 ==
[[模板:Gallerygrid]] 把每张卡片的参数按 <code>::</code> 分段传入：'''第 1 段进 <code>filename</code>，其后第 N 段进模板的 <code><nowiki>{{{N-1}}}</code></nowiki>'''。

'''注意：参数位是按位置对应的，任何一段都不能删除或改变顺序。''' 例如第 2 段（品质徽章）虽然当前不显示，也必须保留空占位，否则后面 24 个参数会整体错位（名称变成品质、价值变成名称……）。

=== 物品卡（26 段）===
<span id="items-params"></span>
{| class="wikitable"
! 段 !! 模板参数 !! 内容 !! 展示位置
|-
| 1 || <code>filename</code> || 图片文件 || 图
|-
| 2 || <code><nowiki>{{{1}}}</nowiki></code> || 品质徽章 || '''留空占位'''（边框色已能区分品质，徽章不显示）
|-
| 3 || <code><nowiki>{{{2}}}</nowiki></code> || 名称 || 标题
|-
| 4 || <code><nowiki>{{{3}}}</nowiki></code> || 价值文本 || 右上
|-
| 5 || <code><nowiki>{{{4}}}</nowiki></code> || 描述（完整，换行转 <code>&lt;br&gt;</code>）|| 描述块
|-
| 6 || <code><nowiki>{{{5}}}</nowiki></code> || 品质数字 || <code>data-param2</code>（筛选）
|-
| 7 || <code><nowiki>{{{6}}}</nowiki></code> || 三级分类 || 标签行
|-
| 8 || <code><nowiki>{{{7}}}</nowiki></code> || 占格 || 数值行
|-
| 9 || <code><nowiki>{{{8}}}</nowiki></code> || 重量文本 || 数值行
|-
| 10 || <code><nowiki>{{{9}}}</nowiki></code> || 贵重标记 || 标签行 + <code>data-param3</code>（筛选）
|-
| 11 || <code><nowiki>{{{10}}}</nowiki></code> || 一级分类 || <code>data-param1</code>（筛选）
|-
| 12 || <code><nowiki>{{{11}}}</nowiki></code> || sortId || <code>data-sort-default</code>
|-
| 13 || <code><nowiki>{{{12}}}</nowiki></code> || 价值数字 || <code>data-sort-value</code>
|-
| 14 || <code><nowiki>{{{13}}}</nowiki></code> || 出现率 || <code>data-sort-rate</code>
|-
| 15 || <code><nowiki>{{{14}}}</nowiki></code> || 重量数字 || <code>data-sort-weight</code>
|-
| 16 || <code><nowiki>{{{15}}}</nowiki></code> || 搜刮耗时 || <code>data-sort-time</code>
|-
| 17 || <code><nowiki>{{{16}}}</nowiki></code> || 物品 ID || <code>data-sort-id</code>（同值时的稳定兜底）
|-
| 18 || <code><nowiki>{{{17}}}</nowiki></code> || 搜刮耗时文本 || 数值行
|-
| 19 || <code><nowiki>{{{18}}}</nowiki></code> || 系统售价文本 || 数值行
|-
| 20 || <code><nowiki>{{{19}}}</nowiki></code> || 堆叠文本（上限为 1 时留空）|| 数值行
|-
| 21 || <code><nowiki>{{{20}}}</nowiki></code> || 出现率百分比文本 || 出现率行
|-
| 22 || <code><nowiki>{{{21}}}</nowiki></code> || 常见容器名 || 出现率行
|-
| 23 || <code><nowiki>{{{22}}}</nowiki></code> || 其它材料标签（顿号连接）|| 标签行
|-
| 24 || <code><nowiki>{{{23}}}</nowiki></code> || 用途（顿号连接）|| 标签行
|-
| 25 || <code><nowiki>{{{24}}}</nowiki></code> || 流通标记（仅少见情况才填）|| 标签行
|-
| 26 || <code><nowiki>{{{25}}}</nowiki></code> || 消耗品效果文本 || 数值行
|}

=== 配件卡（21 段）===
<span id="att-params"></span>
{| class="wikitable"
! 段 !! 模板参数 !! 内容 !! 展示位置
|-
| 1 || <code>filename</code> || 图片文件 || 图
|-
| 2 || <code><nowiki>{{{1}}}</nowiki></code> || 品质徽章 || '''留空占位'''（同上）
|-
| 3 || <code><nowiki>{{{2}}}</nowiki></code> || 名称 || 标题
|-
| 4 || <code><nowiki>{{{3}}}</nowiki></code> || 价值文本 || 右上
|-
| 5 || <code><nowiki>{{{4}}}</nowiki></code> || 描述（完整）|| 描述块
|-
| 6 || <code><nowiki>{{{5}}}</nowiki></code> || 品质数字 || <code>data-param2</code>（筛选）
|-
| 7 || <code><nowiki>{{{6}}}</nowiki></code> || 装配槽位（枪口 / 枪管 / 瞄具 …）|| 标签行 + <code>data-param1</code>（筛选）
|-
| 8 || <code><nowiki>{{{7}}}</nowiki></code> || 适用枪种 + 弹种 || 适用块
|-
| 9 || <code><nowiki>{{{8}}}</nowiki></code> || 细分效果（逐参数一行）|| 实际效果块
|-
| 10 || <code><nowiki>{{{9}}}</nowiki></code> || 弹匣扩容 || 扩容块
|-
| 11 || <code><nowiki>{{{10}}}</nowiki></code> || 占格 || 数值行
|-
| 12 || <code><nowiki>{{{11}}}</nowiki></code> || 重量文本 || 数值行
|-
| 13 || <code><nowiki>{{{12}}}</nowiki></code> || 售价文本 || 数值行
|-
| 14 || <code><nowiki>{{{13}}}</nowiki></code> || 搜刮耗时文本 || 数值行
|-
| 15 || <code><nowiki>{{{14}}}</nowiki></code> || 来源 || 标签行（'''不进数值行'''，否则与标签行重复）
|-
| 16 || <code><nowiki>{{{15}}}</nowiki></code> || 流通 / 废弃标记 || 标签行
|-
| 17 || <code><nowiki>{{{16}}}</nowiki></code> || sortId || <code>data-sort-default</code>
|-
| 18 || <code><nowiki>{{{17}}}</nowiki></code> || 价值数字 || <code>data-sort-value</code>
|-
| 19 || <code><nowiki>{{{18}}}</nowiki></code> || 重量数字 || <code>data-sort-weight</code>
|-
| 20 || <code><nowiki>{{{19}}}</nowiki></code> || 搜刮耗时 || <code>data-sort-time</code>
|-
| 21 || <code><nowiki>{{{20}}}</nowiki></code> || 配件 ID || <code>data-sort-id</code>
|}

=== 排序 ===
排序按钮定义在筛选栏模板里，键名与卡片上的 <code>data-sort-*</code> 对应：

{| class="wikitable"
! 维度 !! 键名 !! 物品页 !! 配件页
|-
| 默认序 || （无）|| 有 || 有
|-
| 价值 || <code>value</code> || 有 || 有
|-
| 出现率 || <code>rate</code> || 有 || 无
|-
| 重量 || <code>weight</code> || 有 || 有
|-
| 搜刮耗时 || <code>time</code> || 有 || 有
|}

同一维度'''三段式循环'''：首次点击 = 降序（大→小）→ 二次 = 升序（小→大）→ 三次 = 取消排序。当前方向由按钮上的箭头指示（▼ 降序 / ▲ 升序）。

== 维护须知 ==
以下是本模块相关页面踩过的坑，改动前请留意：

# '''模板参数末尾的 <code>|</code> 不能丢'''。<code><nowiki>{{筛选面板/筛选项|1|值|}}</nowiki></code> 末尾那个空参数是必需的：<code><nowiki>{{{3}}}</nowiki></code> 是'''无缺省值'''的参数引用，只写 2 段时它在解析层级变化后不展开，按钮上会直接输出字面量 <code><nowiki>{{{3}}}</nowiki></code>。
# '''wikitable 的每个数据行都要显式写 <code>|-</code> 分隔'''。本站的表格解析器'''不会'''把连续的 <code>|</code> 行自动当成新行，会把它们合并进同一行 —— 表现为表格挤成一条横排、列宽全部错乱。表头行后面也必须跟一个 <code>|-</code>。
# '''导出脚本会自动跳过名称含「废弃」的条目'''（见 utils.common.is_deprecated_name）。配件表原本 135 条，其中 8 条废弃已剔除，现为 127 条。
# '''<code>=</code> 不能出现在匿名模板参数里'''。<code><nowiki>{{筛选面板/行|排序|<li class="a">…</li>}}</nowiki></code> 会被解析成命名参数，导致整行消失；必须写成 <code><nowiki>2=…</nowiki></code>。
# '''Lua 标识符不能含中文'''。<code>opts.分类</code>、<code>{分类 = …}</code> 都非法，必须 <code>opts["分类"]</code>。
# '''长字符串里不要出现 <code>[[…]]</code>'''。<code><nowiki>[[…]]</nowiki></code> 内部含 <code><nowiki>[[File:…]]</nowiki></code> 会提前闭合，改用 <code><nowiki>[==[ … ]==]</nowiki></code>。
# '''<code>mw.loadData</code> 返回的是只读代理表'''，<code>#</code>、<code>ipairs</code>、<code>table.concat</code> 都不认它（<code>#</code> 恒为 0），需先转成普通表。
# '''本站 <code><nowiki>{{#css:}}</nowiki></code> 不生效</code>，样式要写进 <code><nowiki>{{#tag:bstyle|…}}</nowiki></code>。
# '''主空间不能执行 <code>&lt;script&gt;</code>'''，交互只能用 CSS 状态（如 <code>:target</code>）。
# '''改完模板要 purge 页面'''，否则看到的仍是旧渲染。
# '''类名里的双下划线会被转义成 <code>&amp;#95;_</code>'''（浏览器能解码回来，CSS 仍生效，但为省事建议一律用单连字符）。

<includeonly>[[分类:模块]]</includeonly><noinclude>[[分类:模块文档]]</noinclude>
