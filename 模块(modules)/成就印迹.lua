local p = {}

local achievementData = mw.loadData("Module:成就印迹/AchievementData")
local roleAchievementData = mw.loadData("Module:成就印迹/RoleAchievementData")

------成就页面
p["成就页面"] = function (frame)
	local achievementType = frame.args[1]
	local achievementLevel = tonumber(frame.args[2])
	local resultList = {}

	for _, item in ipairs(achievementData) do
		if achievementType == item.type and achievementLevel == item.level then
			local html = item.file.."|'''<big>"..item.name.."</big>'''<br /><small>"
			..item.desc.."</small><br /><br />'''获得方式：'''"..item.get
			table.insert(resultList, tostring(html))
		end
	end
	local result = table.concat(resultList, "\n")
	return frame:preprocess('\n<gallery mode="packed">\n'..result..'\n</gallery>')
end

p["成就页面光辉事迹"] = function (frame)
	local resultList = {}
	for _, item in pairs(achievementData) do
		if item.type == "光辉事迹" then
			local html = item.file.."|'''<big>"..item.name.."</big>'''<br /><small>"
				..item.desc.."</small><br /><br />'''获得方式：'''"..item.get
			table.insert(resultList, tostring(html))
		end
	end
	local result = table.concat(resultList, "\n")
	return frame:preprocess('<gallery mode="packed">\n'..result..'\n</gallery>')
end



------印迹页面、角色印迹模板
function p.main(frame)
	local roleAchievement = frame.args[1]
	local achievementLevel = tonumber(frame.args[2])
	local resultList = {}

	for _, item in ipairs(roleAchievementData) do
		if roleAchievement == item.role and achievementLevel == item.level then
			local html = item.file.."|'''<big>"..item.name.."</big>'''<br /><small>"
			..item.desc.."</small><br /><br />'''获得方式：'''"..item.get
			table.insert(resultList, tostring(html))
		end
	end
	local result = table.concat(resultList, "\n")
	return frame:preprocess('\n<gallery mode="packed">\n'..result..'\n</gallery>')
end

------勋章页面印迹勋章部分
function p.main2(frame)
	local roleAchievement = frame.args[1]
	local groupedAchievements = {}

	-- 遍历数据，将同一角色的印迹按组分类，并存储每组的最高等级
	for _, achievement in ipairs(roleAchievementData) do
        if roleAchievement == achievement.role then
            -- 从 achievement.id 中提取前7位作为基准ID (例如: 33500011 -> 3350001)
            local achievementId = tostring(achievement.id or "")
            local baseKey = string.sub(achievementId, 1, 7)
            
            if baseKey ~= "" then
                if not groupedAchievements[baseKey] or achievement.level > groupedAchievements[baseKey].maxLevel then
                    groupedAchievements[baseKey] = {
                        maxLevel = achievement.level,
                        data = achievement,
                        baseKey = baseKey
                    }
                end
            end
        end
    end

	-- 收集并按 baseKey 排序，保证页面渲染的相对顺序稳定
    local sortedGroups = {}
    for _, groupData in pairs(groupedAchievements) do
        table.insert(sortedGroups, groupData)
    end
    table.sort(sortedGroups, function(a, b)
        return a.baseKey < b.baseKey
    end)

    -- 生成最终 Gallery 输出结果
    local resultList = {}
    for _, groupData in ipairs(sortedGroups) do
        local achievement = groupData.data
        local html = string.format("%s|'''<big>%s</big>'''", achievement.file or "", achievement.name or "")
        table.insert(resultList, html)
    end

    if #resultList == 0 then
        return ""
    end

    local result = table.concat(resultList, "\n")
    local galleryStr = string.format("\n<gallery mode=\"packed\">\n%s\n</gallery>", result)

    return frame:preprocess(galleryStr)
end

return p