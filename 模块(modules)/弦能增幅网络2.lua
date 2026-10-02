local p = {}
local data = mw.loadData("模块:弦能增幅网络2/Data")
local skillData = mw.loadData("模块:弦能增幅网络2/SkillData")
local skillValueData = mw.loadData("模块:弦能增幅网络2/SkillValueData")
local weaponData = mw.loadData("模块:弦能增幅网络2/WeaponData")
local acandy = require("模块:ACandy")
local a, Raw = acandy.a, acandy.Raw
local div, span, tr, th, td = a.div, a.span, a.tr, a.th, a.td

----组样式
local function group_style(iconType, partsName, partsMax, rows)
	local imgClass = "2"
	if partsName == "核心" or partsName == "暴击" or partsName == "续航" or partsName == "机能" then
		imgClass = "1"
	elseif partsName == "护甲" or partsName == "生存" or partsName == "生命值" or partsName == "倒地状态" then
		imgClass = "3"
	end

	local groupHTML =
		div { class = "row",
			div { class = "col-sm-12", style = "margin-bottom: 10px;",
				div { class = "upgrade-group-bomb2",
					div { class = "upgrade-top-bomb2",
						span { class = "upgrade-icon-bomb2 upgrade-icon"..imgClass,
							span { class = "upgrade-icon-inner", iconType },
						},
						span { class = "upgrade-name-bomb2", partsName },
						span { class = "upgrade-Maxvalue", 'MAX '..partsMax },
					},
				},
				div { class = "upgrade-options-bomb2", Raw(rows) },
			},
		}

	return groupHTML
end


----行样式
local function row_style(text, cost, maxValue, changeKey)
	local textValue = maxValue and maxValue > 1 and
		div { class = "upgrade-text", text, span { class = "btn-primary badge", maxValue } } or
		div { class = "upgrade-text", text }

	return tostring(div { class = "upgrade-row", ['data-toggle'] = "collapse", ['data-parent'] = "#mc_accordion-"..changeKey, ['data-target'] = "#mc_collapse-"..changeKey,
		div { class = "left-shade" },
		textValue,
		div { class = "upgrade-cost", cost..'[[文件:图标-能量点.png|15px|link=]]' },
	})
end


----技能觉醒图标样式
local function arousal_value_style(blue, yellow, green, value, name, desc)
	local valueHTML =
		div { class = "col-sm-4", style = "margin-bottom: 5px",
			a.table {
				tr {
					td { style = "padding: 5px 0;",
						span { class = "label", style = "font-size: 100%;margin: 0 2px;background-color: rgba(124,160,255,.7);", blue },
						span { class = "label", style = "font-size: 100%;margin: 0 2px;background-color: rgba(229,192,78,.7);", yellow },
						span { class = "label", style = "font-size: 100%;margin: 0 2px;background-color: rgba(103,199,91,.7);", green },
					},
				},
				tr { th { style = "font-size: 18px;", "觉醒"..value.."：" } },
				tr { th { style = "font-size: 16px;", name } },
				tr { td { desc } },
			},
		}
	return tostring(valueHTML)
end

----主函数
function p.main(frame)
	local roleName = frame.args['name']
	local groupType = frame.args['grouptype']

	local partIcons = {
		["核心"] = "[[文件:T_Dynamic_GrowthIcon_100007.png|link=]]",
		["暴击"] = "[[文件:T_Dynamic_GrowthIcon_100009.png|link=]]",
		["续航"] = "[[文件:T_Dynamic_GrowthIcon_100003.png|link=]]",
		["机能"] = "[[文件:T_Dynamic_GrowthIcon_100008.png|link=]]",
		["护甲"] = "[[文件:T_Dynamic_GrowthIcon_100002.png|link=]]",
		["生存"] = "[[文件:T_Dynamic_GrowthIcon_100012.png|link=]]",
		["生命值"] = "[[文件:T_Dynamic_GrowthIcon_100010.png|link=]]",
		["倒地状态"] = "[[文件:T_Dynamic_GrowthIcon_100011.png|link=]]",
	}

	local skillIcons = {
		["Q"] = "[[文件:"..roleName.."技能1.png|link=]]",
		["Passive"] = "[[文件:"..roleName.."技能2.png|link=]]",
		["X"] = "[[文件:"..roleName.."技能3.png|link=]]",
		["E"] = "[[文件:"..roleName.."技能4.png|link=]]",
	}

	local roleData = data[roleName]
	assert(roleData, "角色名称错误: "..(roleName or "未知"))
	local partsData = roleData[groupType]
	assert(partsData, "类型错误: "..(groupType or "未知"))
	local partsName = partsData['Name']
	local partsMax = partsData['UpgradeNumMax']
	local maxValues = partsData['Max']
	local partsTexts = partsData['Desc']
	local partsCosts = partsData['Need']
	local partsIcon = partIcons[partsName] or skillIcons[groupType]

	-- 分组并处理数据
	local groupedRows = {}
	local index = 1
	local changeIndex = 0
	for _, max in ipairs(maxValues) do
		local groupDesc, groupCost = {}, {}
		for j = 1, max do
			if partsTexts[index] and partsCosts[index] then
				table.insert(groupDesc, partsTexts[index])
				table.insert(groupCost, partsCosts[index])
				index = index + 1
			end
		end

		-- 合并相同的 desc 和 cost
		local groupMap = {}
		for i, desc in ipairs(groupDesc) do
			local cost = groupCost[i]
			local key = desc.."_"..cost
			groupMap[key] = groupMap[key] or { desc = desc, cost = cost, count = 0 }
			groupMap[key].count = groupMap[key].count + 1
		end

		-- 生成每组的 HTML
		local groupHTML = ""
		changeIndex = changeIndex + 1
		local changeKey = "Bomb2"..groupType.."Group"..changeIndex..'Change'
		for _, entry in pairs(groupMap) do
			groupHTML = groupHTML..row_style(entry.desc, entry.cost, entry.count, changeKey)
		end

		table.insert(groupedRows,
			'<div class="col-sm-6" style="padding-left: 2px;padding-right: 2px;margin-bottom: 2px;">'
			..groupHTML
			..'<div class="panel-collapse collapse growthcollapse" id="mc_collapse-'..changeKey..'">'
			..(frame.args["Bomb2"..groupType.."Group"..changeIndex..'Change'] or "")
			..'</div></div>'
		)
	end

	-- 拼接所有组的 HTML
	local rows = table.concat(groupedRows)
	return group_style(partsIcon, partsName, partsMax, rows)
end

----武器数值函数
function p.weapon_value(frame)
	local roleName = frame.args['name']

	local roleWeapon = {
		["米雪儿·李"] = "警探",
		["信"] = "审判官",
		["心夏"] = "空境",
		["伊薇特"] = "幻霜",
		["芙拉薇娅"] = "独舞",
		["忧雾"] = "绝对执行",
		["蕾欧娜"] = "校准仪",
		["明"] = "逆焰",
		["拉薇"] = "影袭",
		["梅瑞狄斯"] = "隼",
		["令"] = "破晓",
		["香奈美"] = "谢幕曲",
		["艾卡"] = "鸣火",
		["珐格兰丝"] = "绽放",
		["奥黛丽·格罗夫"] = "卫冕",
		["玛德蕾娜·利里"] = "彩绘",
		["绯莎"] = "齿锋",
		["星绘"] = "北极星",
		["白墨"] = "自由意志",
		["加拉蒂亚·利里"] = "欺诈师",
	}

	local weaponName = roleWeapon[roleName]
	assert(weaponName, "名称错误: "..(roleName or "未知"))
	local weaponsValue = weaponData[weaponName]

	local function Row(name1, name2)
		return tr {
			th(name1),
			td(weaponsValue[name1]),
			th(name2),
			td(weaponsValue[name2]),
		}
	end

	local weaponHTML = a.table { class = "klbqtable", style = "width: 100%;",
		tr / th { class = "text-center", colspan = 4, style = "background-color: #d9edf7;", '武器数值' },
		Row('射速', '瞄准速度'),
		Row('精准', '操控'),
		Row('弹匣容量', '装填速度'),
		Row('拉栓速度', '弦化伤害'),
	}
	return weaponHTML
end

----角色数值函数
function p.skill_value(frame)
	local roleName = frame.args['name']
	local valueData = skillValueData[roleName]
	assert(valueData, "角色名称错误: "..(roleName or "未知"))

	----技能数值函数
	local function Cell(skillKey, skillType)
		local tbl = a.table { class = "klbqtable", style = "width: 100%",
			tr / th { class = "text-center", colspan = 2, style = "background-color: #d9edf7;", skillType },
		}
		for _, skill in pairs(valueData[skillKey]) do
			tbl.children:insert(tr {
				th / skill.text,
				td / skill.value,
			})
		end
		return div["col-sm-3"] / tbl
	end

	return div["row"] {
		Cell('QSkill', '主动技能'),
		Cell('PassiveSkill', '被动技能'),
		Cell('ESkill', '战术技能'),
		Cell('XSkill', '终极技能'),
	}
end

----技能觉醒函数
function p.arousal(frame)
	local roleName = frame.args['name']
	local arousalData = data[roleName]
	assert(arousalData, "角色名称错误: "..(roleName or "未知"))
	local skillsDesc = skillData[roleName]
	assert(skillsDesc, "角色名称错误: "..(roleName or "未知"))

	local arousalSkill1 = skillsDesc["技能觉醒"][1]
	local arousalSkill2 = skillsDesc["技能觉醒"][2]
	local arousalSkill3 = skillsDesc["技能觉醒"][3]

	local arousal1Need = arousalData["Arousal"]["Active1Need"]
	local arousal2Need = arousalData["Arousal"]["Active2Need"]
	local arousal3Need = arousalData["Arousal"]["Active3Need"]

	local arousal1 = arousal_value_style(arousal1Need["蓝"], arousal1Need["黄"], arousal1Need["绿"], 1, arousalSkill1
		["Name"],
		arousalSkill1["Intro"])
	local arousal2 = arousal_value_style(arousal2Need["蓝"], arousal2Need["黄"], arousal2Need["绿"], 2, arousalSkill2
		["Name"],
		arousalSkill2["Intro"])
	local arousal3 = arousal_value_style(arousal3Need["蓝"], arousal3Need["黄"], arousal3Need["绿"], 3, arousalSkill3
		["Name"],
		arousalSkill3["Intro"])
	return arousal1, arousal2, arousal3
end

----战术道具函数
function p.tactical_item(frame)
	local roleName = frame.args['name']
	local itemData = data[roleName]
	assert(itemData, "角色名称错误: "..(roleName or "未知"))
	local itemsNeed = itemData["Weapon"]["TacticalItem"]

	local itemsImg = {
		["拦截者"] = "[[文件:T_Dynamic_WeaponIconMobile_18801001.png|50px|link=]]",
		["破片手雷"] = "[[文件:T_Dynamic_WeaponIconMobile_18101001.png|50px|link=]]",
		["烟雾弹"] = "[[文件:T_Dynamic_WeaponIconMobile_18301001.png|50px|link=]]",
		["治疗雷"] = "[[文件:T_Dynamic_WeaponIconMobile_18601001.png|50px|link=]]",
		["闪光弹"] = "[[文件:T_Dynamic_WeaponIconMobile_18201001.png|50px|link=]]",
		["风场雷"] = "[[文件:T_Dynamic_WeaponIconMobile_18401001.png|50px|link=]]",
		["减速雷"] = "[[文件:T_Dynamic_WeaponIconMobile_18501001.png|50px|link=]]",
		["警报器"] = "[[文件:T_Dynamic_WeaponIconMobile_18701001.png|50px|link=]]",
	}

	local result = {}
	for itemName, itemPoints in pairs(itemsNeed) do
		local itemImg = itemsImg[itemName] or ""
		table.insert(result, '|-\n! class="text-center"|'..itemImg..'\n'..itemName..'\n| '..itemPoints..'\n')
	end
	return '{| class="klbqtable"\n|-\n! 名称\n! 购买所需点数\n'..table.concat(result, '')..'|}'
end

return p