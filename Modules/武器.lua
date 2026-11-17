local p = {}

local stringUtil = require("模块:StringUtil")
local acandy = require("模块:ACandy")
local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

local skinData = mw.loadData("模块:武器/SkinData")
local skinMobileData = mw.loadData("模块:武器/SkinMobileData")

local a, Raw = acandy.a, acandy.Raw
local div, li, ul = a.div, a.li, a.ul

-- 模块输出的 HTML 会被清洗，裸 <a> 会被剥成纯文本，需借 #tag 生成
local function build_link(frame, label, attrs)
	attrs = attrs or {}
	attrs[1] = "a"
	attrs[2] = label
	return Raw(frame:callParserFunction("#tag", attrs))
end

-- 默认（初始）外观：始终排在切换器首位
local DEFAULT_SKIN_LABEL = "初始"

-- 武器外观稀有度分组：展示顺序与分组名称（高稀有度优先）
local WEAPON_QUALITY_ORDER = { 8, 5, 4, 3, 2 }
-- 瞄准镜样式只覆盖传说 / 完美 / 卓越
local SCOPE_QUALITY_ORDER = { 5, 4, 3 }
local WEAPON_QUALITY_NAME = {
	[8] = "臻藏",
	[5] = "传说",
	[4] = "完美",
	[3] = "卓越",
	[2] = "精致",
}

-- 同稀有度内按 ID 升序，保证每次渲染顺序稳定
local function sort_by_id(skinA, skinB)
	return (skinA.id or 9999) < (skinB.id or 9999)
end

-- 按稀有度归档皮肤：只保留 qualityOrder 内的稀有度，同组按 ID 升序
local function group_skins_by_quality(skinTable, qualityOrder)
	local skinsByQuality = {}
	for _, quality in ipairs(qualityOrder) do
		skinsByQuality[quality] = {}
	end

	for skinName, skin in pairs(skinTable) do
		local bucket = skinsByQuality[skin.quality]
		if bucket then
			bucket[#bucket + 1] = {
				name = skinName,
				id = skin.id or 9999,
			}
		end
	end

	for _, quality in ipairs(qualityOrder) do
		if #skinsByQuality[quality] > 1 then
			table.sort(skinsByQuality[quality], sort_by_id)
		end
	end

	return skinsByQuality
end

-- 通用视图层：固定「初始」项 + 稀有度下拉组（武器外观 / 瞄准镜样式共用）
-- opts: skinsByQuality, qualityOrder, panePrefix, dropIdPrefix,
--       defaultContent, defaultLabel?, renderSkin(skinInfo)
local function build_quality_dropdown_tabs(frame, opts)
	local skinsByQuality = opts.skinsByQuality
	local qualityOrder = opts.qualityOrder
	local panePrefix = opts.panePrefix
	local defaultPaneId = panePrefix .. "_default"

	local navItems, tabPanes = {}, {}

	-- 1. 固定首项：初始，并默认选中
	navItems[#navItems + 1] = li { class = "klbq-skin-group__item active",
		['data-quality'] = 0,
		build_link(frame, opts.defaultLabel or DEFAULT_SKIN_LABEL, {
			href = "#" .. defaultPaneId,
			['data-toggle'] = "tab",
		}),
	}
	tabPanes[#tabPanes + 1] = div { class = "tab-pane active", id = defaultPaneId,
		opts.defaultContent,
	}

	-- 2. 存在稀有度分组时，在固定项与下拉组之间插入分割线
	for _, quality in ipairs(qualityOrder) do
		if #skinsByQuality[quality] > 0 then
			navItems[#navItems + 1] = li { class = "klbq-skin-group__divider" }
			break
		end
	end

	-- 3. 按稀有度生成下拉分组
	local paneIndex = 0
	for _, quality in ipairs(qualityOrder) do
		local skins = skinsByQuality[quality]
		if #skins > 0 then
			local dropdownItems = {}
			local groupName = WEAPON_QUALITY_NAME[quality] or (quality .. "星")
			local dropId = opts.dropIdPrefix .. quality

			for _, skinInfo in ipairs(skins) do
				paneIndex = paneIndex + 1
				local paneId = panePrefix .. "_" .. paneIndex

				dropdownItems[#dropdownItems + 1] = li {
					build_link(frame, skinInfo.name, {
						href = "#" .. paneId,
						['data-toggle'] = "tab",
					}),
				}
				tabPanes[#tabPanes + 1] = div { class = "tab-pane", id = paneId,
					opts.renderSkin(skinInfo),
				}
			end

			navItems[#navItems + 1] = li { class = "klbq-skin-group__item dropdown",
				['data-quality'] = quality,
				build_link(frame, groupName .. " ▾", {
					href = "#",
					id = dropId,
					class = "dropdown-toggle",
					['data-toggle'] = "dropdown",
					['role'] = "button",
					['aria-haspopup'] = "true",
					['aria-expanded'] = "false",
				}),
				ul { class = "dropdown-menu", ['role'] = "menu", ['aria-labelledby'] = dropId,
					dropdownItems,
				},
			}
		end
	end

	return div { class = "klbq-skin-group klbq-weapon-skin-group",
		ul { class = "klbq-skin-group__nav",
			navItems,
		},
		div { class = "tab-content",
			tabPanes,
		},
	}
end

-- 合并皮肤数据
local function merge_skin_data(target, source, sourceName)
	for weaponName, skins in pairs(source or {}) do
		if not target[weaponName] then
			target[weaponName] = {}
		end
		for skinName, skin in pairs(skins) do
			local copy = {}
			for k, v in pairs(skin) do
				copy[k] = v
			end
			copy._source = sourceName or "pc"
			target[weaponName][skinName] = copy
		end
	end
end

local function non_empty(str)
	return str and str ~= ""
end

local function str_fallback(str, fallbackStr)
	return (str and str ~= "") and str or fallbackStr
end

local skinList = {}
merge_skin_data(skinList, skinData, "pc")
merge_skin_data(skinList, skinMobileData, "mobile")


p["武器外观"] = function (frame)
	local args = frame.args
	local weaponName = strinova.get_page_title(args)
	local weaponSkinData = skinList[weaponName]
	if not weaponSkinData then return "未找到武器数据" end

	return build_quality_dropdown_tabs(frame, {
		skinsByQuality = group_skins_by_quality(weaponSkinData, WEAPON_QUALITY_ORDER),
		qualityOrder = WEAPON_QUALITY_ORDER,
		panePrefix = "weapon_skin_pane",
		dropIdPrefix = "weapon_skin_drop_",
		-- 初始外观固定引用 <武器名>外观-初始.jpg，上传该文件即自动生效
		defaultContent = "[[文件:" .. weaponName .. "外观-初始.jpg|x500px|center|link=|class=radius5]]",
		renderSkin = function (skinInfo)
			return "[[文件:" .. weaponName .. "外观-" .. skinInfo.name .. ".jpg|x500px|center|link=|class=radius5]]"
		end,
	})
end


p["武器瞄准镜样式"] = function (frame)
	local args = frame.args
	local weaponName = strinova.get_page_title(args)
	local weaponSkinData = skinData[weaponName]
	if not weaponSkinData then return "未找到武器数据" end

	return build_quality_dropdown_tabs(frame, {
		skinsByQuality = group_skins_by_quality(weaponSkinData, SCOPE_QUALITY_ORDER),
		qualityOrder = SCOPE_QUALITY_ORDER,
		panePrefix = "weapon_scope_pane",
		dropIdPrefix = "weapon_scope_drop_",
		defaultContent = "[[文件:瞄准镜样式 " .. weaponName .. ".png|500px|center|link=|class=radius5]]",
		renderSkin = function (skinInfo)
			return "[[文件:瞄准镜样式 " .. weaponName .. skinInfo.name .. ".png|500px|center|link=|class=radius5]]"
		end,
	})
end


local function flatten_skin_data(data)
	local flatData = {}
	for weaponName, skins in pairs(data) do
		for skinName, skin in pairs(skins) do
			table.insert(flatData, {
				_source = skin._source,
				id = skin.id,
				weaponName = weaponName,
				skinName = skinName,
				quality = skin.quality or 0,
				desc = skin.desc,
			})
		end
	end

	-- 排序：优先按品质降序，其次按ID排序
	table.sort(flatData, function(a, b)
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end
		return (a.id or 0) < (b.id or 0)
	end)

	return flatData
end

local function render_skin_image(skin)
	local rarityPopupSet = { [3] = true, [4] = true, [5] = true, [8] = true }
	local prefix = skin._source == "mobile" and "武器外观图鉴移动端_" or "武器外观图鉴_"
	local file = prefix .. (skin.id or "") .. ".png"
	local weapon = skin.weaponName or ""
	local skinName = skin.skinName or ""

	if rarityPopupSet[skin.quality] then
		return '<span class="popup"><span style="display: table-cell;"><div style="position:relative;">[[File:'
			.. file .. '|200px|link=]]'
			.. '</div></span><span style="display:none;">[[file:'
			.. weapon .. '外观-' .. skinName .. '.jpg|400px]]</span></span>'
	end

	return '[[文件:' .. file .. '|200px|link=]]'
end

local function render_acquire_method(ways)
	if type(ways) ~= "table" then return "" end
	local parts = {}
	for _, part in ipairs(ways) do
		if non_empty(part) then
			parts[#parts + 1] = '<span class="badge bg-primary">' .. part .. '</span>'
		end
	end
	return table.concat(parts, "<br>")
end

----武器外观筛选页
p["武器外观筛选"] = function (frame)
	local flatData = flatten_skin_data(skinList)
	local result = {}

	for _, skin in ipairs(flatData) do
		-- 完全从 模块:获得方式/WeaponSkin 获取四个指定字段
		local waysInfo = get_ways_module.getWays("WeaponSkin", skin.id)
		local waysTable = type(waysInfo) == "table" and waysInfo or {}

		-- 1. 获得方式（get）
		local ways = type(waysTable.get) == "table" and waysTable.get or {}
		local validWays = {}
		for _, v in ipairs(ways) do
			if non_empty(v) then
				validWays[#validWays + 1] = v
			end
		end
		local acquireStr = table.concat(validWays, ",")

		-- 2. 巴布洛晶核（BabloCrystals）
		local babloCrystals = tostring(waysTable.BabloCrystals or "")

		-- 3. 基弦（Basestrings）
		local basestrings = tostring(waysTable.Basestrings or "")

		-- 4. 备注（remark）
		local remarkText = waysTable.remark or ""

		local cardHtml = frame:expandTemplate{
                title = "Gallerygrid/WeaponSkin",
                args = {
                    ["武器"] = skin.weaponName,
                    ["稀有度"] = skin.quality,
                    ["外观名称"] = skin.skinName,
                    ["外观图片"] = render_skin_image(skin), 
                    ["稀有度标签"] = strinova.rarity_tag(frame, skin.quality),
                    ["获得方式数据"] = acquireStr,
                    ["巴布洛晶核数据"] = str_fallback(babloCrystals, "无"),
                    ["基弦数据"] = str_fallback(basestrings, "无"),
                    ["巴布洛晶核"] = non_empty(babloCrystals) and (babloCrystals .. "[[文件:图标-小巴布洛晶核.png|15px|link=]]") or "",
                    ["基弦"] = non_empty(basestrings) and (basestrings .. "[[文件:图标-小基弦.png|15px|link=]]") or "",
                    ["获得方式"] = render_acquire_method(ways),
                    ["简介"] = skin.desc or "",
                    ["备注"] = remarkText,
                }
            }
            table.insert(result, cardHtml)
    end
    
    return '<div class="gallerygrid">' .. table.concat(result) .. '</div>'
end


----意识重构武器外观表
p["意识重构外观筛选"] = function (frame)
	local skinGet = frame.args[1]
	if not non_empty(skinGet) then return "" end

	local matchedIds = get_ways_module.getIdsByWay("WeaponSkin", skinGet)
	if #matchedIds == 0 then return "" end

	local matchedSet = {}
	for _, id in ipairs(matchedIds) do
		matchedSet[tonumber(id)] = true
	end

	local formatter = stringUtil.Formatter [=[
|-
| {外观}
| {稀有度标签}
| {简介}
]=]

	local flatData = flatten_skin_data(skinList)
	local result = {}

	for _, skin in ipairs(flatData) do
		if matchedSet[tonumber(skin.id)] then
			table.insert(result, formatter({
				['外观'] = render_skin_image(skin)..'<br>[[' .. skin.weaponName .. ']]：' .. skin.skinName,
				['稀有度标签'] = strinova.rarity_tag(frame, skin.quality),
				['简介'] = skin.desc or "",
			}))
		end
	end

	return table.concat(result)
end

return p