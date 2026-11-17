local p = {}
local acandy = require("模块:ACandy")
local a = acandy.a
local strinova = require("模块:卡拉彼丘")

local data = mw.loadData("模块:角色礼物/Data")

local char = ""
function compare(g1, g2)
	if g1.quality ~= g2.quality or char == "" then
		return g1.quality > g2.quality
	end
	return g1.favorability[char] > g2.favorability[char]
end

function sort_data()
	temp = {}
	for k, v in pairs(data) do
		table.insert(temp, v)
	end
	table.sort(temp, compare)
	return temp
end

--定义一个辅助函数，根据 favorability 值设置背景颜色
local function createfavorabilityCell(value)
	if value == 180 then
		return a.td { style = "background-color: rgba(255, 140, 105, 0.6);text-align: center;", value }
	else
		return a.td { style = "text-align: center", value }
	end
end

-- 角色页面礼物好感
p["角色礼物好感"] = function (frame)
	local gifttype = frame.args["活动礼物"]
	local name = frame.args[1] or strinova.get_page_title(frame)
	local resultList = {}
	char = name
	data = sort_data()
	for value, rolename in ipairs(data) do
		if gifttype == nil then
			if rolename.activities == false then
				local rolegiftsHTML = p.tablestyle(name, rolename.file, rolename.name, rolename.desc, rolename
				.quality, rolename.favorability, frame)
				table.insert(resultList, rolegiftsHTML)
			end
		else
			if rolename.activities == true then
				local rolegiftsHTML = p.tablestyle(name, rolename.file, rolename.name, rolename.desc, rolename
				.quality, rolename.favorability, frame)
				table.insert(resultList, rolegiftsHTML)
			end
		end
	end
	local result = table.concat(resultList)
	return result
end

function p.tablestyle(name, File, Name, Desc_string, Quality, favorability, frame)
	local rolegiftsHTML = tostring(a.tr {
		a.td { style = "text-align: center;",
			"[[文件:", File, "|70px|link=]]",
			a.br,
			a.b(Name),
		},
		a.td { class = "visible-md visible-sm visible-lg", Desc_string },
		a.td { style = "text-align: center;",
			acandy.Raw( strinova.rarity_tag(frame, Quality) ),
		},
		createfavorabilityCell(favorability[name]),
	})
	return rolegiftsHTML
end

--誓约页面礼物好感表
p["礼物好感表"] = function (frame)
	local gifttype = frame.args["活动礼物"]
	local resultList = {}
	local data = sort_data()

	for value, rolegifts in ipairs(data) do
		if gifttype == nil then
			if rolegifts.activities == false then
				local rolegiftsHTML = p.tablestyle2(name, rolegifts.file, rolegifts.name, rolegifts.desc,
					rolegifts.quality, rolegifts.favorability, frame)
				table.insert(resultList, rolegiftsHTML)
			end
		else
			if rolegifts.activities == true then
				local rolegiftsHTML = p.tablestyle2(name, rolegifts.file, rolegifts.name, rolegifts.desc,
					rolegifts.quality, rolegifts.favorability, frame)
				table.insert(resultList, rolegiftsHTML)
			end
		end
	end

	local result = table.concat(resultList)
	return result
end

function p.tablestyle2(name, File, Name, Desc_string, Quality, favorability, frame)
	local rolegiftsHTML = tostring(a.tr {
		a.td { style = "text-align: center;",
			"[[文件:", File, "|70px|link=]]",
			a.br,
			a.b(Name),
		},
		a.td { class = "visible-md visible-sm visible-lg", Desc_string },
		a.td { style = "text-align: center;",
			acandy.Raw( strinova.rarity_tag(frame, Quality) ),
		},
		createfavorabilityCell(favorability["米雪儿·李"]),
		createfavorabilityCell(favorability["奥黛丽·格罗夫"]),
		createfavorabilityCell(favorability["星绘"]),
		createfavorabilityCell(favorability["拉薇"]),
		createfavorabilityCell(favorability["心夏"]),
		createfavorabilityCell(favorability["玛德蕾娜·利里"]),
		createfavorabilityCell(favorability["伊薇特"]),
		createfavorabilityCell(favorability["香奈美"]),
		createfavorabilityCell(favorability["绯莎"]),
	})
	return rolegiftsHTML
end

return p