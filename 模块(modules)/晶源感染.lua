local p = {}

local format = string.format
local stringUtil = require("Module:StringUtil")
local tableWithFallback = require('Module:TableUtil').table_with_fallback
local get = require("Module:Get")
local strinova = require("模块:卡拉彼丘")
local qualityToColor = strinova.qualityToColor

local pcCardData = mw.loadData("模块:晶源感染/CardData")
local mobileCardData = mw.loadData("模块:晶源感染/CardDataMobile")
local turnCardData = mw.loadData("模块:晶源感染/TurnCardData")

local function boolean_to_str(key, trueStr, falseStr)
	if key and key == true then return trueStr end
	return falseStr
end

local function build_style(file, name, quality, category, teamType, role, maxLevel, default, extension, desc, rlease)
	return "文件:"..file..
		"::"..name..
		"::"..quality..
		"::"..category..
		"::"..teamType..
		"::"..maxLevel..
		"::"..role..
		"::"..default..
		"::"..extension..
		"::".."\n"..desc..
		"::"..rlease
end

local function build_style_mobile(file, name, teamType, category, maxLevel, desc, role, quality)
	return "文件:"..file..
		"::"..name..
		"::"..teamType..
		"::"..category..
		"::"..maxLevel..
		"::".."\n"..desc..
		"::"..role..
		"::"..quality
end

-- t本身不含值，而是通过元方法提供值。例如mw.loadData返回的表
local function concat_proxied_table(t, sep)
	local buf = {}
	for i, v in ipairs(t) do
		buf[i] = v
	end
	return table.concat(buf, sep)
end

local function level_description(descLevel1, descLevel2, descLevel3, descLevel4, descLevel5)
    -- 1. 收集所有非空(nil 或 "")的描述到列表中
    -- Case 0: 没有有效描述，返回空字符串
    -- Case A: 只有一个描述，返回加粗文本 '''%s'''
    -- Case B: 有多个描述，返回有序列表 # '''%s'''
    local descriptions = {}
    local raw_args = {descLevel1, descLevel2, descLevel3, descLevel4, descLevel5}
    
    for _, desc in ipairs(raw_args) do
        if desc and desc ~= "" then
            table.insert(descriptions, desc)
        end
    end

    local count = #descriptions

    if count == 0 then
        return ""
    end

    if count == 1 then
        return string.format("'''%s'''", descriptions[1])
    end

    local resultParts = {}
    for _, desc in ipairs(descriptions) do
        table.insert(resultParts, string.format("# '''%s'''", desc))
    end
    return table.concat(resultParts, "\n")
end

local function icon_style(cardID, cardName, cardQuality)
	local html = mw.html.create()
	local borderColor = qualityToColor[cardQuality]
	local iconHTML = html
		:tag('span'):addClass('item-icon'):cssText("flex-direction: column;")
		:tag('span'):addClass('item-icon__img'):cssText("background: rgba(232, 232, 232, 1);border-color:"..borderColor):wikitext("[[文件:生化卡牌_"..
			cardID..".png|100px|class=radius10|link=]]"):done()
		:tag('span'):addClass('item-icon__text'):wikitext(cardName):done()
		:done()
	return tostring(iconHTML)
end

p["卡牌筛选"] = function (frame)
	local pcReleaseDate = mw.loadData("模块:晶源感染/CardReleaseDate")
	local args = {
		id = 'CardSelectGallery',
		template = 'ZombieCard',
		widths = '190px',
	}

	for _, items in pairs(pcCardData) do
		local file = format('生化卡牌_%s.png', items.cardid)
		local desc = level_description(items.descLevel1, items.descLevel2, items.descLevel3, items.descLevel4, items.descLevel5)
		local default = boolean_to_str(items.default, "默认", "非默认")
		local extension = boolean_to_str(items.extension, "付费", "免费")
		local role = items.unlockRoles and concat_proxied_table(items.unlockRoles, "、") or ""
		local rlease = pcReleaseDate[items.name] or ""
		local entry = build_style(file, items.name, items.quality, items.category, items.teamType, role, items.maxLevel, default, extension, desc, rlease)
		table.insert(args, entry)
	end

	return frame:expandTemplate { title = 'gallerygrid', args = args }
end


p["移动端卡牌筛选"] = function (frame)
	local args = {
		id = 'CardSelectGallery',
		template = 'ZombieCardMobile',
		widths = '190px',
	}

	for _, items in pairs(mobileCardData) do
		local file = format('生化卡牌_%s.png', items.cardid)
		local descLevel = level_description(items.descLevel1, items.descLevel2, items.descLevel3, items.descLevel4, items.descLevel5)
		local unlockRoles = items.unlockRoles and concat_proxied_table(items.unlockRoles, "、") or ""
		local borderColor = qualityToColor[items.quality]
		local entry = build_style_mobile(file, items.name, items.teamType, items.category, items.maxLevel, descLevel, unlockRoles, items.quality)
		table.insert(args, entry)
	end

	return frame:expandTemplate { title = 'gallerygrid', args = args }
end


p["轮换卡组"] = function (frame)
	local teamType = frame.args[1]
	local list = {}
	table.insert(list, '{| class="klbqtable"')
	table.insert(list, '|-')
	for groupName, groupInfo in pairs(turnCardData) do
		if teamType == groupInfo.teamType then
			table.insert(list, "! '''<big>"..groupName.."'''</big>")
			table.insert(list, '|-')
			table.insert(list, '| '..groupInfo.desc)
			table.insert(list, '|-')
			table.insert(list, '|')
			local cards = groupInfo.cardGroup
			local cardHtmls = {}
			for _, cardKey in ipairs(cards) do
				local cardInfo = pcCardData[cardKey]
				local cardHTML = icon_style(cardInfo.cardid, cardInfo.name, cardInfo.quality)
				table.insert(cardHtmls, cardHTML)
			end
			table.insert(list, table.concat(cardHtmls, "\n"))
		end
	table.insert(list, '|-')
	end

	table.insert(list, '|}')
	return table.concat(list, '\n')
end

return p