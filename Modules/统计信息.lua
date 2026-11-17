local p = {}

local strinova = require("模块:卡拉彼丘")
local qualityName = strinova.qualityNumToName

local format = string.format

-- 判断皮肤名称中是否含有"-"
local function check_has_hyphen(skinName)
    if type(skinName) ~= "string" then
        return false
    end
    local hasHyphen = string.find(skinName, "-", 1, true) ~= nil
    return hasHyphen
end

-- 工具函数：数据扁平化
local function flatten_skin_data(data, entityKey, nameKey)
    local flatData = {}
    for entityName, skins in pairs(data) do
        for skinName, skinInfo in pairs(skins or {}) do
            if type(skinInfo) == "table" then
    			local quality = qualityName[skinInfo.quality] or skinInfo.quality
    				if quality ~= "初始"
    				and not (quality == "传说" and check_has_hyphen(skinName)) then
                		local entry = {
                    	[nameKey]   = skinName,
                    	["稀有度"]  = quality
                	}
                	entry[entityKey] = entityName
                	flatData[#flatData+1] = entry
    				end
        	end
        end
	end
    return flatData
end

-- 工具函数：统计多个字段值出现次数
local function count_by_fields(data, fields)
    local result = {}
    for _, entry in ipairs(data) do
        for _, field in ipairs(fields) do
            local value = entry[field]
            result[field] = result[field] or {}
            result[field][value] = (result[field][value] or 0) + 1
        end
    end
    return result
end

-- 工具函数：格式化统计结果
local function format_count_result(title, countTable)
    local keys = {}
    for k in pairs(countTable) do
        table.insert(keys, k)
    end
    table.sort(keys)

    local lines = { "按'''"..title.."'''划分：" }
    for _, key in ipairs(keys) do
        local count = countTable[key]
        table.insert(lines,
            format('<span class="badge bg-primary" style="margin: 2px;">%s %d个</span>', key, count))
    end
    return table.concat(lines, "\n")
end

-- 通用统计函数
local function make_statistics(title, data, countFields)
    local count = #data
    local parts = {
        format("目前共有 %d 个%s，其中：", count, title),
        "<ul>",
    }
    -- 一次性统计所有字段
    local stats = count_by_fields(data, (function()
        local tmp = {}
        for _, f in ipairs(countFields) do
            table.insert(tmp, f.key)
        end
        return tmp
    end)())

    for _, f in ipairs(countFields) do
        table.insert(parts,
            "<li>"..format_count_result(f.title, stats[f.key]).."</li>")
    end

    table.insert(parts, "</ul>")
    return table.concat(parts, "\n")
end

-- 时装统计
p["时装统计"] = function(frame)
    local data = mw.loadData("模块:角色/SkinData")
    local flatData = flatten_skin_data(data, "角色", "时装名称")
    return make_statistics("时装", flatData, {
        {title = "品质", key = "稀有度"},
        {title = "角色", key = "角色"},
    })
end

-- 外观统计
p["外观统计"] = function(frame)
	local data = mw.loadData("模块:武器/SkinData")
    local flatData = flatten_skin_data(data, "武器", "外观名称")
    return make_statistics("外观", flatData, {
        {title = "品质", key = "稀有度"},
        {title = "武器", key = "武器"},
    })
end

local function non_Empty(str)
	if str and str == true then return "付费" end
	return "免费"
end

-- 卡牌统计
p["卡牌统计"] = function(frame)
    local cardData = mw.loadData("模块:生化卡牌/Data")
    local flatData = {}

    for _, card in pairs(cardData) do
        if type(card) == "table" then
        	local quality = qualityName[card["quality"]]
            flatData[#flatData+1] = {
                ["稀有度"] = quality or "（空）",
                ["类型"]   = card["category"] or "（空）",
                ["阵营"]   = card["teamType"] or "（空）",
                ["获取方式"] = non_Empty(card["extension"]) or "（空）",
            }
        end
    end

    return make_statistics("卡牌", flatData, {
        {title = "稀有度", key = "稀有度"},
        {title = "类型",   key = "类型"},
        {title = "阵营",   key = "阵营"},
        {title = "获取方式", key = "获取方式"},
    })
end

-- 卡牌统计
p["移动端卡牌统计"] = function(frame)
    local cardData = mw.loadData("模块:生化卡牌/MobileData")
    local flatData = {}

    for _, card in pairs(cardData) do
        if type(card) == "table" then
        	local quality = qualityName[card["quality"]]
            flatData[#flatData+1] = {
                ["稀有度"] = quality or "（空）",
                ["类型"]   = card["category"] or "（空）",
                ["阵营"]   = card["teamType"] or "（空）",
            }
        end
    end

    return make_statistics("卡牌", flatData, {
        {title = "稀有度", key = "稀有度"},
        {title = "类型",   key = "类型"},
        {title = "阵营",   key = "阵营"},
    })
end

function p.name_space(frame)
    local namespace = tonumber(frame.args[1]) or 0
    
    local pages = mw.site.stats.pagesInNamespace(namespace)

    return pages
end

return p