local p = {}

local format = string.format

local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

local data = mw.loadData("模块:角色表情/Data")
local mobileData = mw.loadData("模块:角色表情/MobileData")

-- 如果有'-'，进行分割返回第二部分，否则直接返回原字符串
local function splitKey(key)
    if not key:find("-") then
        return key
    end
    local parts = {}
    for part in key:gmatch("[^-]+") do
        parts[#parts + 1] = part
    end
    return parts[2] or key
end

-- 合并表
local function mergeTables(t1, t2)
    local result = {}

    if t1 then
        for _, v in ipairs(t1) do
            table.insert(result, v)
        end
    end

    if t2 then
        for _, v in ipairs(t2) do
            table.insert(result, v)
        end
    end

    return result
end

local allItems = mergeTables(data, mobileData)

-- 安全获取途径函数（解决 default 返回值导致 OR 失效的问题）
local function get_emote_Ways(itemId)
    local ways = get_ways_module.getWays("Emote", itemId)
    -- 如果端游途径查无结果，则尝试查找手游途径
    if not ways or ways[1] == "暂无获取途径" then
        local mobileWays = get_ways_module.getWays("EmoteMobile", itemId)
        if mobileWays and mobileWays[1] ~= "暂无获取途径" then
            return mobileWays
        end
    end
    return ways
end

------角色页角色表情
p["角色表情"] = function (frame)
	local emoteRole = strinova.get_page_title(frame)
	local resultList = {}

	for _, item in pairs(allItems) do
		if emoteRole == item.role then
			local emoteGet = get_emote_Ways(item.id)
			local emoteHTML = item.file.."|'''<big>"..splitKey(item.name)
				.."</big>'''<br><small>"..item.desc.."</small><br>'''获得方式：'''"..strinova.array_to_ul(emoteGet)
			resultList[#resultList+1] = emoteHTML
		end
	end

	local result = table.concat(resultList, "\n")
	return result..'\n'
end


------表情包页面
p["表情包"] = function (frame)
	local emoteRole = frame.args[1]
	local resultList = {}

	for _, item in pairs(allItems) do
		if emoteRole == item.role then
			local emoteGet = get_emote_Ways(item.id)
			local emoteHTML = item.file.."|'''<big>"..splitKey(item.name)
				.."</big>'''<br><small>"..item.desc.."</small><br>'''获得方式：'''<br>"..strinova.array_to_ul(emoteGet)
			resultList[#resultList+1] = emoteHTML
		end
	end

	local result = table.concat(resultList, "\n")
	return frame:preprocess('<gallery mode="packed">\n'..result..'\n</gallery>')
end


------意识重构页角色表情
p["意识重构角色表情"] = function (frame)
	local get = frame.args[1]
	local targetIds = get_ways_module.getIdsByWay("Emote", get)

	if #targetIds == 0 then
		return "暂无符合该获得途径的表情"
	end
	
	local idSet = {}
	for _, id in ipairs(targetIds) do
		idSet[id] = true
	end

	local resultList = {}

	for _, items in pairs(data) do
		if idSet[items.id] then 
			local file = format("表情_%d.png", items.id)
			local emoteHTML = file..
				"|'''<big>"..items.role.."表情："..splitKey(items.name).."</big>'''"
				..strinova.rarity_tag(frame, items.quality)
				
			resultList[#resultList+1] = emoteHTML
		end
	end

	if #resultList == 0 then
		return "暂无符合该获得途径的表情"
	end
	
	local result = table.concat(resultList, "\n")
	return frame:preprocess('<gallery mode="packed">\n'..result..'\n</gallery>')
end

return p