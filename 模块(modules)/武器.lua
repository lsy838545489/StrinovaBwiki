local p = {}

local stringUtil = require("模块:StringUtil")
local acandy = require("模块:ACandy")
local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

local skinData = mw.loadData("模块:武器/SkinData")
local skinMobileData = mw.loadData("模块:武器/SkinMobileData")

local a = acandy.a
local div, span, li, ul = a.div, a.span, a.li, a.ul

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

	local skinsByQuality = {
		[8] = {}, [5] = {}, [4] = {}, [3] = {}, [2] = {},
	}
	
	-- 根据品质分类武器皮肤
	for skinName, skin in pairs(weaponSkinData) do
		local quality = skin.quality
		local skinsOfThisQuality = skinsByQuality[quality]
		if skinsOfThisQuality then
			skinsOfThisQuality[#skinsOfThisQuality + 1] = skinName
		end
	end

	local tabLabels, tabBodies = {}, {}
	-- 创建每个品质的标签和内容
	for _, quality in ipairs({ 8, 5, 4, 3, 2 }) do
		local len = #tabLabels
		for i, skinName in ipairs(skinsByQuality[quality]) do
			tabLabels[len + i] = li { class = "bili-list-style",
				span { class = "tab-panel", ['data-quality'] = quality,
					skinName,
				},
			}
			tabBodies[len + i] = div { class = "resp-tab-content",
				"[[文件:", weaponName, "外观-", skinName, ".jpg|x500px|center|link=|class=radius5]]",
			}
		end
	end

	if tabLabels[1] then
		tabLabels[1].class = tabLabels[1].class .. " active"
		tabBodies[1].style = "display:block"
	end

	-- 返回武器外观的HTML
	return div { class = "resp-tabs skin-tabs",
		ul { class = "resp-tabs-list clearfix",
			tabLabels,
		},
		div { class = "resp-tabs-container",
			tabBodies,
		},
	}
end


p["武器瞄准镜样式"] = function (frame)
	local args = frame.args
	local weaponName = strinova.get_page_title(args)
	local weaponSkinData = skinData[weaponName]
	if not weaponSkinData then return "未找到武器数据" end

	local skinsByQuality = {
		[0] = {}, [5] = {}, [4] = {}, [3] = {},
	}

	for skinName, skin in pairs(weaponSkinData) do
		local quality = skin.quality
		local skinsOfThisQuality = skinsByQuality[quality]
		if skinsOfThisQuality then
			skinsOfThisQuality[#skinsOfThisQuality + 1] = skinName
		end
	end

	local tabLabels, tabBodies = {}, {}

	tabLabels[1] = li { class = "bili-list-style active",
		span { class = "tab-panel", ['data-quality'] = "0",
			"初始",
		},
	}
	tabBodies[1] = div { class = "resp-tab-content", style = "display:block",
		"[[File:瞄准镜样式 " .. weaponName .. ".png|500px|center|link=|class=radius5]]",
	}

	local tabIndex = 2

	for _, quality in ipairs({ 5, 4, 3 }) do
		for _, skinName in ipairs(skinsByQuality[quality]) do
			tabLabels[tabIndex] = li { class = "bili-list-style",
				span { class = "tab-panel", ['data-quality'] = quality,
					skinName,
				},
			}
			tabBodies[tabIndex] = div { class = "resp-tab-content",
				"[[File:瞄准镜样式 " .. weaponName .. skinName .. ".png|500px|center|link=|class=radius5]]",
			}
			tabIndex = tabIndex + 1
		end
	end

	return div { class = "resp-tabs skin-tabs",
		ul { class = "resp-tabs-list clearfix",
			tabLabels,
		},
		div { class = "resp-tabs-container",
			tabBodies,
		},
	}
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