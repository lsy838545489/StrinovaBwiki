--[[
模块:平衡数据

「卡片筛选」视图的渲染入口。

设计要点：
  * 30 张角色卡**固定不动**，筛选只切换卡片内的数值（由 Widget:BalanceFilter 完成）。
  * 服务端只做两件事：① 输出卡片骨架 + 筛选/排序按钮；② 用 meta.default 那份**默认切片**
    把首屏数值填好（避免 JS 加载前先闪一片 --）。
  * 全量四维数据（1760 切片）不在 Lua 里，而是放在 MediaWiki:平衡数据-<模式>.json，
    由 widget 按需加载。原因：浏览器拿不到 Lua 表，且数据量超过 post-expand 上限。

数据模块：
  模块:平衡数据/Default  首屏默认切片（很小，服务端直读）
]]

local acandy = require('模块:ACandy')
local a, Raw = acandy.a, acandy.Raw

local p = {}

-- 与官网表格列一一对应；顺序即 JSON 分片里数值数组的顺序
-- arg 用于拼卡片模板的中文参数名（防守/进攻 + arg）
local METRICS = {
	{ key = 'winRate',    arg = '胜率',   title = '胜率',     pct = true },
	{ key = 'selectRate', arg = '选取率', title = '选取率',   pct = true },
	{ key = 'kd',         arg = 'KD',     title = 'K/D',      pct = false },
	{ key = 'damageAve',  arg = '均伤',   title = '回合均伤', pct = false },
	{ key = 'score',      arg = '表现分', title = '表现分',   pct = false },
}

-- 分片页后缀：与 generate_balance_data.py 的 SHARD_SUFFIX 必须一致
local SHARD_SUFFIX = { ['5'] = '排位', ['2'] = '一般' }

-- 分片页标题前缀：分片为 MediaWiki:平衡数据-<后缀>-<赛季>.json
local SHARD_PREFIX = 'MediaWiki:平衡数据'

local DIM_LABEL = { season = '赛季', mode = '模式', map = '地图', rank = '段位', side = '阵营' }

-- 阵营选项：s1=进攻方、s2=防守方。与分片里 side1/side2 的键一致。
-- 默认进攻方（按需求）。
local SIDES = {
	{ code = 's1', name = '进攻方' },
	{ code = 's2', name = '防守方' },
}
local DEFAULT_SIDE = 's1'

-- ================= 工具 =================

local function fmt(value, pct)
	if value == nil or value == 0 then
		return '--'
	end
	local n = tonumber(value)
	if not n then
		return '--'
	end
	if pct then
		return string.format('%.2f%%', n)
	end
	return tostring(n)
end

---只列出「该维度实际有数据」的取值，避免出现永远空的选项
local function usable_options(meta, dim, list)
	local usable = meta.usable and meta.usable[dim]
	local out = {}
	for _, item in ipairs(list or {}) do
		local code = tostring(item.code)
		if not usable or usable[code] then
			out[#out + 1] = item
		end
	end
	if #out == 0 then
		return list or {}
	end
	return out
end

---渲染一行筛选按钮
-- 注意：类名**刻意不用** cardSelectOption —— wiki 共用的 Widget:CardSelectGallery
-- 会全局绑定 .cardSelectOption 并按 data-param* 过滤 .gallerygrid-item，复用会导致
-- 我们的 30 张卡片被隐藏。这里用自己的 klbq-balance-fbtn。
local function filter_row(dim, items, current, extra)
    local buttons = {}
    for _, item in ipairs(items or {}) do
        local code = tostring(item.code)
        local attrs = {
            item.name or code,
            class = 'btn btn-default klbq-balance-fbtn'
                .. (code == tostring(current) and ' selected' or ''),
            ['data-dim'] = dim,
            ['data-val'] = code,
        }
        if extra and extra[code] then
            attrs['data-shard'] = extra[code]
        end
        buttons[#buttons + 1] = a.li(attrs)
    end

	return a.div {
		class = 'gallery-filter__row',
		a.div { class = 'gallery-filter__label', DIM_LABEL[dim] or dim },
		a.ul { class = 'gallery-filter__options', buttons },
	}
end

---渲染排序按钮行
local function sort_row()
	local buttons = {}
	for _, metric in ipairs(METRICS) do
		buttons[#buttons + 1] = a.li {
			class = 'btn btn-default klbq-balance-sortbtn',
			['data-key'] = metric.key,
			a.span { metric.title },
			a.span { class = 'klbq-arrow' },
		}
	end
	return a.div {
		class = 'gallery-filter__row',
		a.div { class = 'gallery-filter__label', '排序' },
		a.ul { class = 'gallery-filter__options', buttons },
		a.span { class = 'klbq-balance-status' },
	}
end

---兼容取值：format_lua_table 会把纯数字字符串键写成数字键，
-- 所以 meta.roles / meta.jobs / slice 都要同时试字符串与数字两种写法
local function pick2(tbl, key)
	if type(tbl) ~= 'table' then
		return nil
	end
	local v = tbl[key]
	if v ~= nil then
		return v
	end
	local n = tonumber(key)
	if n ~= nil then
		return tbl[n]
	end
	return nil
end

---生成角色卡片集（默认切片直接填好数值，避免首屏闪 --）
local function build_cards(frame, meta, slice)
	local cards = {}
	for _, hero_id in ipairs(meta.heroes or {}) do
		local key = tostring(hero_id)
		local name = pick2(meta.roles, key) or key
		local entry = pick2(slice, key)
		local s1 = (entry and entry.s1) or {}
		local s2 = (entry and entry.s2) or {}

		-- 注意：键用显式字符串写法 ['xxx']，不要用中文裸标识符
		-- （Lua 5.1 允许，但 5.5 会报 unexpected symbol，本地用 lupa 验证时会挂）
		local args = {
			['角色码'] = key,
			['角色'] = name,
			['职业'] = pick2(meta.jobs, key) or '',
		}
		for idx, metric in ipairs(METRICS) do
			args['防守' .. metric.arg] = fmt(s1[idx], metric.pct)
			args['进攻' .. metric.arg] = fmt(s2[idx], metric.pct)
		end

		-- 必须包 Raw()：expandTemplate 返回的是已渲染好的 HTML，
		-- 直接作为 ACandy 子节点会被 html_encode 成字面文本（实测 24 张卡全被转义）
		cards[#cards + 1] = Raw(frame:expandTemplate { title = 'Gallerygrid/BalanceCard', args = args })
	end
	return cards
end

-- ================= 入口 =================

function p.gallery(frame)
	local ok, default = pcall(mw.loadData, '模块:平衡数据/Default')
	if not ok or type(default) ~= 'table' then
		return '<div class="klbq-balance-error">平衡数据尚未生成，请联系维护者。</div>'
	end

	local meta = default.meta or {}
	local d = meta.default or {}
	local slice = default.slice or {}

	local season = tostring(d.season or (meta.seasons and meta.seasons[1] and meta.seasons[1].code) or '')
	local mode = tostring(d.mode or '5')
	local map = tostring(d.map or '-255')
	local rank = tostring(d.rank or '-255')

	local panel = a.div {
		class = 'gallery-filter klbq-balance-panel',
		filter_row('season', usable_options(meta, 'season', meta.seasons), season),
		a.hr { class = 'gallery-filter__divider' },
		filter_row('mode', usable_options(meta, 'mode', meta.modes), mode, SHARD_SUFFIX),
		a.hr { class = 'gallery-filter__divider' },
		filter_row('map', usable_options(meta, 'map', meta.maps), map),
		a.hr { class = 'gallery-filter__divider' },
		filter_row('rank', usable_options(meta, 'rank', meta.ranks), rank),
		a.hr { class = 'gallery-filter__divider' },
		filter_row('side', SIDES, DEFAULT_SIDE),
		a.hr { class = 'gallery-filter__divider' },
		sort_row(),
	}

	-- 交给 widget 的分片定位信息：
	--   data-shard-current = 当前分片页标题（服务端算好，JS 不猜）
	--   data-mode-suffix   = "模式:页后缀" 映射，JS 换赛季时用它拼另一个赛季的分片名
	-- 用「; / : 」分隔而不是 JSON：实测 MediaWiki 会把属性值里的 { } 转义成 &#123;，
	-- 塞 JSON 进 data-* 必然解析失败。
	local mode_suffix = {}
	for _, m in ipairs(meta.modes or {}) do
		local mcode = tostring(m.code)
		if SHARD_SUFFIX[mcode] then
			mode_suffix[#mode_suffix + 1] = mcode .. ':' .. SHARD_SUFFIX[mcode]
		end
	end
	local current_suffix = SHARD_SUFFIX[mode]
	local current_shard = current_suffix
		and (SHARD_PREFIX .. '-' .. current_suffix .. '-' .. season .. '.json') or ''

	-- API 地址交给 widget 自己解析（用 JS 侧的 mw.config）：
	-- Scribunto 的 Lua **没有** mw.config，在模块里读 wgServer 会直接 Lua 报错，实测踩过。
	-- 这里只提供路径线索，widget 侧有 location.pathname 兜底。
	local api_path_hint = '/api.php'

	-- 注意：ACandy 只接受「单表」形式（属性与子节点在同一个表里）。
	-- 写成 a.div(attrs, child1, child2) 会把后面的子节点丢掉，实测只剩一个空壳 div。
	local root = a.div {
		id = 'klbq-balance-root',
		['data-season'] = season,
		['data-mode'] = mode,
		['data-map'] = map,
		['data-rank'] = rank,
		['data-side'] = DEFAULT_SIDE,
		['data-api-path'] = api_path_hint,
		['data-shard-current'] = current_shard,
		['data-shard-prefix'] = SHARD_PREFIX,
		['data-mode-suffix'] = table.concat(mode_suffix, ';'),
		panel,
		a.div { class = 'klbq-balance-grid', build_cards(frame, meta, slice) },
	}

	local note = a.div {
		class = 'klbq-balance-def',
		'数值为当前所选阵营（默认进攻方）；绿色为该列在当前筛选下的最高值。'
			.. '数据更新于 ' .. tostring(meta.updateTime or '未知')
			.. '，来源为官网公开接口。',
	}

	-- 必须压掉 ACandy 输出里的换行：多行 HTML 中的空行会被 MediaWiki 当作段落分隔，
	-- 结果 <div> 被提前闭合、里面的 panel 与 24 张卡片全部丢失（实测踩过）。
	local out = (tostring(root) .. tostring(note)):gsub('\n', '')
	return out
end

---向后兼容别名（旧调用 {{#invoke:平衡数据|main}} 仍可用，但输出为卡片视图）
p.main = p.gallery

return p