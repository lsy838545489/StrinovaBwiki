local p = {}

local acandy = require("模块:ACandy")
local a, Raw = acandy.a, acandy.Raw
local div, span = a.div, a.span
local tr, th, td = a.tr, a.th, a.td
local format = string.format

local bombData = mw.loadData("模块:弦能增幅网络3/BombData")
local escortData = mw.loadData("模块:弦能增幅网络3/EscortData")
local hotZoneData = mw.loadData("模块:弦能增幅网络3/HotZoneData")
local skillData = mw.loadData("模块:角色/SkillData")
local bombWeaponData = mw.loadData("模块:弦能增幅网络3/BombWeaponData")

----行样式
local function rowStyle(text, cost, changeKey, rowClass)
	local row_html =
		div { class = "upgrade-row radius5 "..rowClass, ['data-toggle'] = "collapse", ['data-parent'] = "#mc_accordion-"..changeKey, ['data-target'] = "#mc_collapse-"..changeKey,
			div { class = "upgrade-text", text },
			div { class = "upgrade-cost", cost..'[[文件:图标-能量点.png|15px|link=]]' },
		}
	return tostring(row_html)
end

----组样式
local function groupStyle(groupName, groupIcon, partsname, value)
	local IconClass = {
		["主动技能"] = 2,
		["被动技能"] = 2,
		["护甲"] = 3,
		["弦化"] = 3,
	}
	local groupIconClass = IconClass[groupName] or "1"
	local group_html =
		div { class = "upgrade-group",
			div { class = "upgrade-top",
				span { class = "upgrade-icon upgrade-icon"..groupIconClass,
					span { class = "upgrade-icon-inner", groupIcon },
				},
				span { class = "upgrade-name", partsname }
			},
			div { class = "upgrade-options radius5", Raw(value) },
		}

	return group_html
end


function p.main(frame)
	local args = frame.args
	local roleName = frame.args['name']
	local mode = frame.args['mode']
	local groupName = frame.args['groupName']
	
	local groupIconFiles = {
		["护甲"] = "[[文件:Growth3Icon_100002.png|link=]]",
		["续航"] = "[[文件:Growth3Icon_100003.png|link=]]",
		["输出"] = "[[文件:Growth3Icon_100004.png|link=]]",
		["暴击"] = "[[文件:Growth3Icon_100005.png|link=]]",
		["机能"] = "[[文件:Growth3Icon_100006.png|link=]]",
		["核心"] = "[[文件:Growth3Icon_100007.png|link=]]",
		["操控"] = "[[文件:Growth3Icon_100008.png|link=]]",
		["精准"] = "[[文件:Growth3Icon_100009.png|link=]]",
		["弦化"] = "[[文件:Growth3Icon_100012.png|link=]]",
		["主动技能"] = "[[文件:"..roleName.."技能1.png|link=]]",
		["被动技能"] = "[[文件:"..roleName.."技能2.png|link=]]",
	}
	
	local roleData = ""
	local keyTemplate = ""
	if mode == "极限推进模式" then
		roleData = escortData[roleName]
		keyTemplate = "极限推进模式%sGroup%dChange"
	elseif mode == "弦区争夺模式" then
		roleData = hotZoneData[roleName]
		keyTemplate = "弦区争夺模式%sGroup%dChange"
	else
		roleData = bombData[roleName]
		keyTemplate = "爆破模式%sGroup%dChange"
	end

	local partsData = roleData[groupName]
	assert(partsData, "类型错误: "..(groupName or "未知"))
	local partsName = partsData['name']
	
	local groupIcon, rowClass = "",  ""
	if groupName == "弦化" or groupName == "护甲" then
		groupIcon = groupIconFiles[partsName]
		rowClass = "upgrade-row-defense"
	elseif groupName == "主动技能" or groupName == "被动技能" then
		groupIcon = groupIconFiles[groupName]
		rowClass = "upgrade-row-skill"
	else
		groupIcon = groupIconFiles[partsName]
		rowClass = "upgrade-row-weapon"
	end

	-- 获取所有的Desc和Need
	local partsTexts = partsData['desc']
	local partsCosts = partsData['need']

	-- 动态生成分组内容
	local groupedRows = {}
	for i, desc in ipairs(partsTexts) do
		local desc = partsTexts[i]
		local cost = partsCosts[i]
		if desc and desc ~= "" then
			if partsCosts[i] == nil then
			cost = partsCosts[i-1]
			end
			local changeIndex = i
			local currentChangeKey = format(keyTemplate, groupName, i)
			local changeValue = args[currentChangeKey] or ""

			local rowHTML = rowStyle(desc, cost, currentChangeKey, rowClass)
			local collapseHTML = ('<div class="panel-collapse collapse growthcollapse" id="mc_collapse-%s" style="padding: 5px;">%s</div>')
				:format(currentChangeKey, changeValue)

			table.insert(groupedRows, rowHTML..collapseHTML)
		end
	end

	-- 构建最终输出（使用原始type参数）
	local rows = table.concat(groupedRows, '\n')  -- 添加换行增强可读性
	local bomb_html = groupStyle(groupName, groupIcon, partsName, rows)
	return bomb_html
end


function p.weapon(frame)
	local args = frame.args
	local weaponName = frame.args['name']
	local mode = frame.args['mode']
	local groupName = frame.args['groupName']
	
	local groupIconFiles = {
		["续航"] = "[[文件:Growth3Icon_100003.png|link=]]",
		["输出"] = "[[文件:Growth3Icon_100004.png|link=]]",
		["暴击"] = "[[文件:Growth3Icon_100005.png|link=]]",
		["机能"] = "[[文件:Growth3Icon_100006.png|link=]]",
		["核心"] = "[[文件:Growth3Icon_100007.png|link=]]",
		["操控"] = "[[文件:Growth3Icon_100008.png|link=]]",
		["精准"] = "[[文件:Growth3Icon_100009.png|link=]]",
	}
	
	local weaponData = ""
	local keyTemplate = ""
	if mode == "极限推进模式" then
		weaponData = escortData[weaponName]
		keyTemplate = "极限推进模式%sGroup%dChange"
	elseif mode == "弦区争夺模式" then
		weaponData = hotZoneData[weaponName]
		keyTemplate = "弦区争夺模式%sGroup%dChange"
	else
		weaponData = bombWeaponData[weaponName]
		keyTemplate = "爆破模式%sGroup%dChange"
	end

	local partsData = weaponData[groupName]
	assert(partsData, "类型错误: "..(groupName or "未知"))
	local partsName = partsData['name']
	
	local groupIcon, rowClass = "",  ""
	if groupName == "弦化" or groupName == "护甲" then
		groupIcon = groupIconFiles[partsName]
		rowClass = "upgrade-row-defense"
	elseif groupName == "主动技能" or groupName == "被动技能" then
		groupIcon = groupIconFiles[groupName]
		rowClass = "upgrade-row-skill"
	else
		groupIcon = groupIconFiles[partsName]
		rowClass = "upgrade-row-weapon"
	end

	-- 获取所有的Desc和Need
	local partsTexts = partsData['desc']
	local partsCosts = partsData['need']

	-- 动态生成分组内容
	local groupedRows = {}
	for i, desc in ipairs(partsTexts) do
		local desc = partsTexts[i]
		local cost = partsCosts[i]
		if desc and desc ~= "" then
			if partsCosts[i] == nil then
			cost = partsCosts[i-1]
			end
			local changeIndex = i
			local currentChangeKey = format(keyTemplate, groupName, i)
			local changeValue = args[currentChangeKey] or ""

			local rowHTML = rowStyle(desc, cost, currentChangeKey, rowClass)
			local collapseHTML = ('<div class="panel-collapse collapse growthcollapse" id="mc_collapse-%s" style="padding: 5px;">%s</div>')
				:format(currentChangeKey, changeValue)

			table.insert(groupedRows, rowHTML..collapseHTML)
		end
	end

	-- 构建最终输出（使用原始type参数）
	local rows = table.concat(groupedRows, '\n')  -- 添加换行增强可读性
	local bomb_html = groupStyle(groupName, groupIcon, partsName, rows)
	return bomb_html
end


----技能觉醒图标样式
local function arousal_value_style(blue, yellow, green, value, name, desc)
	local valueHTML =
		div { class = "col-sm-4", style = "margin-bottom: 0.9em",
			a.table {
				tr {
					td { style = "padding: 5px 0;",
						span { class = "label", style = "font-size: 100%;margin: 0 2px;background-color: rgba(124,160,255,.7);", blue },
						span { class = "label", style = "font-size: 100%;margin: 0 2px;background-color: rgba(255,165,0,.7);", yellow },
						span { class = "label", style = "font-size: 100%;margin: 0 2px;background-color: rgba(147,223,90,.7);", green },
					},
				},
				tr {
					th { style = "font-size: 18px;", "觉醒"..value.."：" },
				},
				tr {
					th { style = "font-size: 16px;", name },
				},
				tr {
					td { desc },
				},
			},
		}
	return tostring(valueHTML)
end

----技能觉醒函数
function p.arousal(frame)
	local roleName = frame.args['name']
	local arousalData = bombData[roleName]
	assert(arousalData, "角色名称错误: "..(roleName or "未知"))
	local skillsDesc = skillData[roleName]
	assert(skillsDesc, "角色名称错误: "..(roleName or "未知"))

	local arousalSkill1 = skillsDesc["技能觉醒"][1]
	local arousalSkill2 = skillsDesc["技能觉醒"][2]
	local arousalSkill3 = skillsDesc["技能觉醒"][3]

	local arousal1Need = arousalData["技能觉醒"]["Active1Need"]
	local arousal2Need = arousalData["技能觉醒"]["Active2Need"]
	local arousal3Need = arousalData["技能觉醒"]["Active3Need"]

	local arousal1 = arousal_value_style(arousal1Need[1], arousal1Need[2], arousal1Need[3], 1, arousalSkill1
		["name"],
		arousalSkill1["desc"])
	local arousal2 = arousal_value_style(arousal2Need[1], arousal2Need[2], arousal2Need[3], 2, arousalSkill2
		["name"],
		arousalSkill2["desc"])
	local arousal3 = arousal_value_style(arousal3Need[1], arousal3Need[2], arousal3Need[3], 3, arousalSkill3
		["name"],
		arousalSkill3["desc"])
	return arousal1, arousal2, arousal3
end

return p