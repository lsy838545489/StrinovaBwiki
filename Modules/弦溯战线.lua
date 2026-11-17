-- 模块:弦溯战线
-- 《卡拉彼丘》「弦溯战线」搜打撤模式 · 物品图鉴 / 配件图鉴
--
-- 完整说明（调用方式、数据来源、字段口径、卡片参数对照表、维护须知）
-- 见 [[模块:弦溯战线/doc]]
--
-- 本模块只做一件事：取数 + 拼卡片参数，交给 gallerygrid 渲染成卡片。
--   · 卡片结构与样式 → [[模板:Gallerygrid/弦溯战线物品]] / [[模板:Gallerygrid/弦溯战线配件]]
--   · 筛选 + 排序     → [[Widget:CardSelectGallery]]
--   模块不产出任何 HTML、CSS 或脚本。
--
-- 用法：
--   {{#invoke:弦溯战线|图鉴}}          物品图鉴
--   {{#invoke:弦溯战线|配件图鉴}}      配件图鉴
--   {{#invoke:弦溯战线|图鉴|隐藏计数=1}}
--
-- 注意：本模式的品质编号与主游戏不同，不能复用 模块:卡拉彼丘.qualityNumToName
--   主游戏：5 = 传说、8 = 臻藏
--   弦溯战线：5 = 臻藏、6 = 传说（见 SECItemQualityRes）

local p = {}

local format = string.format

-- ================= 基础配置 =================

-- 卡片模板（模板:Gallerygrid/弦溯战线物品）
local CARD_TEMPLATE = "弦溯战线物品"
-- 网格容器额外类名：模板内 CSS 用它限定列数，不影响同页其他 gallerygrid
local GRID_CLASS = "sec-gallery"
-- gallerygrid 的卡片参数分隔符（不可与内容冲突，已在导出侧校验）
local ARG_SEP = "::"
-- 物品图标命名约定（图标由 wiki 侧按 id 取用，导出数据不含图标字段）
local ICON_PATTERN = "弦溯战线图标_%d.png"

-- 品质编号 → 名称（弦溯战线口径）
local QUALITY_NAME = {
	[1] = "优秀",
	[2] = "精致",
	[3] = "卓越",
	[4] = "完美",
	[5] = "臻藏",
	[6] = "传说",
}

-- ================= 取数与工具 =================

-- 深拷贝为普通 Lua 表
-- mw.loadData 返回的是只读代理表：`#`、`ipairs`、`table.concat` 都不认它（# 恒为 0），
-- 必须先转成普通表，后续的排序/拼接才能正常工作
local function deep_copy(value, depth)
	depth = depth or 0
	if type(value) ~= "table" or depth > 8 then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = deep_copy(v, depth + 1)
	end
	return out
end

-- 最近一次加载失败的原因，供 调试=1 时排查
local last_load_error = nil
local function load_data(candidates)
	candidates = candidates or { "模块:弦溯战线/物品Data", "模块:SECItem" }
	last_load_error = nil
	local errs = {}
	for _, name in ipairs(candidates) do
		local ok, raw = pcall(mw.loadData, name)
		if ok and type(raw) == "table" then
			local data = deep_copy(raw)
			if #data > 0 then
				return data
			end
			errs[#errs + 1] = name .. ": 表为空"
		else
			errs[#errs + 1] = name .. ": " .. tostring(raw)
		end
	end
	last_load_error = table.concat(errs, "；")
	return {}
end

-- 千分位数字，如 5330812 → 5,330,812
local function thousands(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- 品质标签：按本模式编号先翻成名称，再交给站点的「稀有度标签」模板，
-- 避免 5 被站点的通用表渲染成「传说」
--   注：卡片上已不再显示品质徽章（边框色已能区分品质），此函数暂未调用；
--   若日后要恢复徽章，把下面 cells 里的 "" 换回 quality_badge(frame, .quality) 即可。
local function quality_badge(frame, quality)
	local name = QUALITY_NAME[tonumber(quality) or 0]
	if not name then
		return tostring(quality)
	end
	return frame:expandTemplate { title = "稀有度标签", args = { name } }
end

-- 卡片描述：完整展示，不截断
--   换行统一转 <br>（数据里已转好，这里兜底），竖线转全角以免打断模板参数
local function desc_text(desc)
	if not desc or desc == "" then
		return ""
	end
	local s = desc:gsub("\r\n", "\n"):gsub("\n", "<br>"):gsub("|", "｜")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	return s
end

-- ================= 卡片参数拼装 =================
-- gallerygrid 的约定：第 1 段进 {{{filename}}}，其后第 N 段进 {{{N-1}}}。
-- 下面是 26 段参数，逐段对照表见 [[模块:弦溯战线/doc#items-params]]。
-- 卡片分两行：数值行放数值、标签行放标签（与配件卡保持一致）
--   数值行 sec-card-stats：占格 · 重量 · 售价 · 搜刮耗时 · 堆叠 · 消耗品效果
--   标签行 sec-card-tags：分类 · 贵重 · 其它标签 · 用途 · 流通
-- 排序所需的原始值（sortId / value / rate / weight / searchTime / id）一并写进卡片的
-- data-sort-* 属性，名次由脚本现算，模块不需要预处理
local function card_args(frame, item)
	local valuable = ""
	local other_tags = {}
	if item.tags then
		for _, tag in ipairs(item.tags) do
			if tag == "贵重" then
				valuable = "贵重"
			else
				table.insert(other_tags, tag)
			end
		end
	end

	-- 搜刮耗时：原始值单位是毫秒（170 / 270 / 300 / 400），展示换算成秒
	local search_text = ""
	if item.searchTime and item.searchTime > 0 then
		search_text = format("搜刮 %.2fs", item.searchTime / 1000)
	end

	-- 系统售价（与交易行参考价 value 区分）
	local price_text = ""
	if item.price and item.price > 0 then
		price_text = "售价 " .. thousands(item.price)
	end

	-- 堆叠：上限为 1 时没有信息量，不显示
	local stack_text = ""
	if item.stackable and (item.stackMax or 1) > 1 then
		stack_text = "可叠 " .. tostring(item.stackMax)
	end

	-- 出现率 / 常见容器
	local rate_text, best_text = "", ""
	if item.loot and item.loot.rate and item.loot.rate > 0 then
		local v = item.loot.rate * 100
		rate_text = (v >= 1) and format("%.2f%%", v) or format("%.3f%%", v)
		best_text = item.loot.best or ""
	end

	-- 用途
	local usage_text = ""
	if item.usages then
		local names = {}
		for _, u in ipairs(item.usages) do
			if u.title and u.title ~= "" then
				table.insert(names, u.title)
			end
		end
		usage_text = table.concat(names, "、")
	end

	-- 流通：只标注少见情况，避免 150+ 张卡都挂一个「可交易」
	local flow_text = ""
	if item.npcBuy then
		flow_text = "NPC 在售"
	elseif item.tradable == false then
		flow_text = "不可交易"
	end

	-- 消耗品效果
	local consume_text = ""
	if item.consumable then
		local parts = {}
		local c = item.consumable
		if (c.armorAdd or 0) > 0 then table.insert(parts, "回甲 " .. c.armorAdd) end
		if (c.hpAdd or 0) > 0 then table.insert(parts, "回血 " .. c.hpAdd) end
		if (c.castTime or 0) > 0 then
			table.insert(parts, format("使用 %.1fs", c.castTime / 1000))
		end
		consume_text = table.concat(parts, " ")
	end

	local cells = {
		"File:" .. format(ICON_PATTERN, item.id),
		"", -- 品质徽章：卡片上不显示（边框色已区分品质），此处留空占位以保持参数位不变
		item.name or "",
		"价值 " .. thousands(item.value),
		desc_text(item.desc),
		tostring(tonumber(item.quality) or 0),
		item.typeName3 or "",
		(item.sizeW and item.sizeH and item.sizeW > 0)
			and format("%d×%d", item.sizeW, item.sizeH) or "",
		(item.weight and item.weight > 0)
			and ("重量 " .. thousands(item.weight)) or "",
		valuable,
		item.typeName or "",
		tostring(item.sortId or 0),
		tostring(item.value or 0),
		tostring((item.loot and item.loot.rate) or 0),
		tostring(item.weight or 0),
		tostring(item.searchTime or 0),
		tostring(item.id or 0),
		search_text,
		price_text,
		stack_text,
		rate_text,
		best_text,
		table.concat(other_tags, "、"),
		usage_text,
		flow_text,
		consume_text,
	}

	return table.concat(cells, ARG_SEP)
end

-- ================= 配件图鉴 =================
-- 配件卡片模板（模板:Gallerygrid/弦溯战线配件）
local ATT_CARD_TEMPLATE = "弦溯战线配件"
-- 网格容器额外类名（与物品图鉴分开，互不影响）
local ATT_GRID_CLASS = "sec-att-gallery"

-- 配件卡片参数拼装
-- 同样是第 1 段进 filename、其后第 N 段进 {{{N-1}}}，共 21 段；
-- 逐段对照表见 [[模块:弦溯战线/doc#att-params]]
local function att_card_args(frame, att)
	local compat = att.compat or {}

	-- 适用枪种 + 弹种
	local compat_text = ""
	local weapon_types = compat.weaponTypes or {}
	local ammo_types = compat.ammoTypes or {}
	if #weapon_types > 0 then
		compat_text = "适用 " .. table.concat(weapon_types, "、")
		if #ammo_types > 0 then
			compat_text = compat_text .. "（" .. table.concat(ammo_types, "、") .. "）"
		end
	end

	-- 细分效果：数据里已是「参数名 ±N%」的自解释字符串，逐行展示
	local detail_text = ""
	if att.detail and #att.detail > 0 then
		detail_text = table.concat(att.detail, "<br>")
	end

	-- 弹匣扩容
	local ammo_text = ""
	if att.ammo and #att.ammo > 0 then
		local parts = {}
		for _, a in ipairs(att.ammo) do
			table.insert(parts, a.name .. " +" .. tostring(a.add) .. "发")
		end
		ammo_text = table.concat(parts, "、")
	end

	-- 占格 / 重量 / 售价 / 搜刮耗时
	local size_text = ""
	if att.sizeW and att.sizeH and att.sizeW > 0 then
		size_text = format("%d×%d", att.sizeW, att.sizeH)
	end
	local weight_text = ""
	if att.weight and att.weight > 0 then
		weight_text = "重量 " .. thousands(att.weight)
	end
	local price_text = ""
	if att.price and att.price > 0 then
		price_text = "售价 " .. thousands(att.price)
	end
	local search_text = ""
	if att.searchTime and att.searchTime > 0 then
		search_text = format("搜刮 %.2fs", att.searchTime / 1000)
	end

	-- 流通与废弃：只标注少见情况
	local flow_text = ""
	if att.tradable == false then
		flow_text = "不可交易"
	end
	if att.deprecated then
		flow_text = (flow_text ~= "" and (flow_text .. " / ") or "") .. "已废弃"
	end

	local cells = {
		"File:" .. format(ICON_PATTERN, att.id),
		"", -- 品质徽章：卡片上不显示（边框色已区分品质），此处留空占位以保持参数位不变
		att.name or "",
		"价值 " .. thousands(att.value),
		desc_text(att.desc),
		tostring(tonumber(att.quality) or 0),
		att.typeName3 or "",
		compat_text,
		detail_text,
		ammo_text,
		size_text,
		weight_text,
		price_text,
		search_text,
		att.sources or "",
		flow_text,
		tostring(att.sortId or 0),
		tostring(att.value or 0),
		tostring(att.weight or 0),
		tostring(att.searchTime or 0),
		tostring(att.id or 0),
	}

	return table.concat(cells, ARG_SEP)
end

-- ================= 对外接口 =================

-- 全物品输出
-- 参数：隐藏计数=1 时不输出顶部计数行
p["图鉴"] = function(frame)
	local args = frame.args
	local data = load_data()
	if #data == 0 then
		local tip = "弦溯战线物品数据缺失，请检查 [[模块:弦溯战线/物品Data]]。"
		if args["调试"] == "1" and last_load_error then
			tip = tip .. "（" .. last_load_error .. "）"
		end
		return '<div class="error">' .. tip .. "</div>"
	end

	-- 输出顺序固定为游戏内展示序，这也是页面上的「默认」排序；
	-- 其余维度由 [[Widget:CardSelectGallery]] 按卡片的 data-sort-* 现算
	table.sort(data, function(a, b)
		if (a.sortId or 0) == (b.sortId or 0) then
			return (a.id or 0) < (b.id or 0)
		end
		return (a.sortId or 0) < (b.sortId or 0)
	end)

	local tpl_args = {
		template = CARD_TEMPLATE,
		class = GRID_CLASS,
		gap = "1.25rem 1rem",
	}
	for i, item in ipairs(data) do
		tpl_args[i] = card_args(frame, item)
	end

	local body = frame:expandTemplate { title = "gallerygrid", args = tpl_args }

	if args["隐藏计数"] == "1" then
		return body
	end
	return format("共 '''%d''' 件物品（可按下方条件筛选与排序）\n%s", #data, body)
end

-- 配件图鉴（枪械配件，127 条；废弃条目已在导出侧剔除）
-- 参数：隐藏计数=1 时不输出顶部计数行
p["配件图鉴"] = function(frame)
	local args = frame.args
	local data = load_data({ "模块:弦溯战线/配件Data", "模块:SECAttachment" })
	if #data == 0 then
		local tip = "弦溯战线配件数据缺失，请检查 [[模块:弦溯战线/配件Data]]。"
		if args["调试"] == "1" and last_load_error then
			tip = tip .. "（" .. last_load_error .. "）"
		end
		return '<div class="error">' .. tip .. "</div>"
	end

	-- 顺序 = 游戏内图鉴顺序（sortId 1~135，与物品图鉴同一套默认序逻辑）
	table.sort(data, function(a, b)
		if (a.sortId or 0) == (b.sortId or 0) then
			return (a.id or 0) < (b.id or 0)
		end
		return (a.sortId or 0) < (b.sortId or 0)
	end)

	local tpl_args = {
		template = ATT_CARD_TEMPLATE,
		class = ATT_GRID_CLASS,
		gap = "1.25rem 1rem",
	}
	for i, att in ipairs(data) do
		tpl_args[i] = att_card_args(frame, att)
	end

	local body = frame:expandTemplate { title = "gallerygrid", args = tpl_args }

	if args["隐藏计数"] == "1" then
		return body
	end
	return format("共 '''%d''' 件配件（可按下方条件筛选与排序）\n%s", #data, body)
end

return p
--<noinclude>'''本模块的完整说明（调用方式、字段口径、卡片参数对照表、维护须知）见 [[模块:弦溯战线/doc]]。'''</noinclude>