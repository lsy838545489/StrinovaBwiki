local p = {}

local stringUtil = require("模块:StringUtil")
local acandy = require("模块:ACandy")
local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

local skillData = mw.loadData("模块:角色/SkillData")
local skinData = mw.loadData("模块:角色/SkinData")

local a, Raw, Fragment = acandy.a, acandy.Raw, acandy.Fragment
local tr, th, td = a.tr, a.th, a.td

local function non_empty(str)
	return str and str ~= ""
end

local function str_fallback(str, fallbackStr)
	return str ~= "" and str or fallbackStr
end

-- 判断皮肤名称中是否含有"-"
local function check_has_hyphen(skinName)
    if type(skinName) ~= "string" then
        return false
    end
    local hasHyphen = string.find(skinName, "-", 1, true) ~= nil
    return hasHyphen
end

-- 辅助函数：根据ID升序排序喵
local function sort_by_id(skinA, skinB)
    return skinA.id < skinB.id
end


----角色页角色技能模板----
function p.roleSkill (frame)
	local args = frame.args
	local role =  strinova.get_page_title(args)
	local skillTypeToNum = {
		["主动"] = 1,  -- 主动技能
		["被动"] = 2,  -- 被动技能
		["终极"] = 3,  -- 终极技能
		["战术"] = 4,  -- 战术技能
	}
	local skills = {}
	
	-- 技能详情创建函数
	local function SkillDetail(skillType)
		local num = skillTypeToNum[skillType]
		local skill = skills[num]

		local roleSkill = skillData[role]
		assert(roleSkill, "角色名称错误: "..(role or "未知"))
		local RoleSkillType1 = skillType.."技能"
		local RoleSkillType = roleSkill[RoleSkillType1]
		assert(RoleSkillType, "技能类型错误: "..(RoleSkillType1 or "未知"))
		local skillinfo = RoleSkillType[1]

		if skillinfo and skillinfo['name'] and skillinfo['desc'] then
		return 	{
			tr / th { colspan = "2", class = "text-center", skillType, "技能" },
			tr {
				td { class = "skill-name text-center", "[[文件:", role, "技能", num, ".png|120px]]", a.br, skillinfo['name'] },
				td { class = "skill-info", skillinfo['desc'] },
			},
		}
		else
			return ""
		end
	end

	-- 创建角色技能表格
	local Roleskilltable = a.table { class = "klbqtable role-skill-table",
		SkillDetail("主动"),  -- 主动技能
		SkillDetail("被动"),  -- 被动技能
		SkillDetail("终极"),  -- 终极技能
		SkillDetail("战术"),  -- 战术技能
	}
	return Roleskilltable
end

----角色页角色时装----
local QualityNameMap = {
    [5] = "传说",
    [4] = "完美",
    [3] = "卓越"
}
---- 视图层：生成内部时装详情 Tab 喵 ----
local function create_skin_img_tab(frame, characterName, skinName, skinQuality, isActive)
    local skinTabNav, skinTabContent = "", ""
    if skinQuality ~= 3 and not (skinQuality == 5 and check_has_hyphen(skinName)) then
        skinTabNav = a.li { class = "klbq-skin-viewer__item", ['data-toggle'] = 'tab', ['data-target'] = '#'..skinName..'立绘', '立绘' }
        skinTabContent = a.div { class = "tab-pane", id = skinName.."立绘", "[[文件:"..characterName.."-"..skinName.."立绘.png]]" }
    end

    local activeClass = isActive and "active" or ""
    return a.div { class = "tab-pane " .. activeClass, id = "skin_pane_" .. skinName,
        a.div { class = "klbq-skin-viewer",
            a.ul { class = "klbq-skin-viewer__nav",
                a.li { class = "klbq-skin-viewer__item active", ['data-toggle'] = 'tab', ['data-target'] = '#'..skinName..'模型正面', '模型正面' },
                a.li { class = "klbq-skin-viewer__item", ['data-toggle'] = 'tab', ['data-target'] = '#'..skinName..'模型背面', '模型背面' },
                skinTabNav,
            },
            a.div { class = "tab-content",
                a.div { class = "tab-pane active", id = skinName.."模型正面", "[[文件:"..characterName.."时装-"..skinName..".jpg|link=]]" },
                a.div { class = "tab-pane", id = skinName.."模型背面", "[[文件:"..characterName.."时装-"..skinName.."_背面.jpg|link=]]" },
                skinTabContent,
            },
        }
    }
end

---- 视图层：生成外层切换 Tabs 框架 喵 ----
local function build_outer_skin_tabs(frame, roleName, skinsByQuality)
    local navTabs = {}
    local tabPanes = {}
    local isFirstActive = true

    -- 处理固定顺位：稀有度0和6
    for _, quality in ipairs({ 0, 6 }) do
        if #skinsByQuality[quality] > 0 then
            for _, skinInfo in ipairs(skinsByQuality[quality]) do
                local skinName = skinInfo.name
                
                local aTagFixed = frame:callParserFunction('#tag', {
                    'a',
                    skinName,
                    href = "#skin_pane_" .. skinName,
                    ['data-toggle'] = "tab"
                })

                navTabs[#navTabs + 1] = a.li { class = "klbq-skin-group__item " .. (isFirstActive and "active" or ""),
                	['data-quality'] = quality,
                    Raw(aTagFixed)
                }

                tabPanes[#tabPanes + 1] = create_skin_img_tab(frame, roleName, skinName, quality, isFirstActive)
                
                isFirstActive = false
            end
        end
     end

    -- 只有当前面有固定顺位皮肤（navTabs不为空），且后面存在 5/4/3 星皮肤时，才插入分割线
    if #navTabs > 0 then
        local hasDropdownSkins = false
        for _, quality in ipairs({ 5, 4, 3 }) do
            if #skinsByQuality[quality] > 0 then
                hasDropdownSkins = true
                break
            end
        end
        
        if hasDropdownSkins then
            navTabs[#navTabs + 1] = a.li { class = "klbq-skin-group__divider" }
        end
    end

    -- 2. 处理带有下拉列表组的稀有度 (5, 4, 3)
    for _, quality in ipairs({ 5, 4, 3 }) do
        local skins = skinsByQuality[quality]
        if #skins > 0 then
            local dropdownItems = {}
            local groupName = QualityNameMap[quality] or (quality .. "星")
            local dropId = "skinTabDrop" .. quality

            for _, skinInfo in ipairs(skins) do
                local skinName = skinInfo.name
                
                local aTagDropdown = frame:callParserFunction('#tag', {
                    'a',
                    skinName,
                    href = "#skin_pane_" .. skinName,
                    ['data-toggle'] = "tab"
                })

                dropdownItems[#dropdownItems + 1] = a.li {
                    Raw(aTagDropdown)
                }
                
                tabPanes[#tabPanes + 1] = create_skin_img_tab(frame, roleName, skinName, quality, isFirstActive)

                if isFirstActive then isFirstActive = false end
            end

            local dropToggleTag = frame:callParserFunction('#tag', {
                'a',
                groupName .. " ▾",
                href = "#",
                id = dropId,
                class = "dropdown-toggle",
                ['data-toggle'] = "dropdown"
            })

            navTabs[#navTabs + 1] = a.li { class = "klbq-skin-group__item dropdown",
            	['data-quality'] = quality,
                Raw(dropToggleTag),
                a.ul { class = "dropdown-menu", role = "menu", ['aria-labelledby'] = dropId, dropdownItems }
            }
        end
    end

    return a.div { class = "klbq-skin-group", 
        a.ul { class = "klbq-skin-group__nav", navTabs },
        a.div { class = "tab-content", tabPanes }
    }, a.br
end

p["角色时装"] = function (frame)
    local args = frame.args
    local roleName = strinova.get_page_title(args)
    local skinsByQuality = { [0] = {}, [6] = {}, [5] = {}, [4] = {}, [3] = {} }

    local roleSkinData = skinData[roleName]
    if not roleSkinData then return "未找到角色数据" end

    for skinName, skin in pairs(roleSkinData) do
        local rarity = skin.quality
        local skinsOfThisQuality = skinsByQuality[rarity]
        if skinsOfThisQuality then
            skinsOfThisQuality[#skinsOfThisQuality + 1] = {
                name = skinName,
                id = skin['id'] or 9999
            }
        end
    end
    
    for quality, skins in pairs(skinsByQuality) do
        if #skins > 1 then
            table.sort(skins, sort_by_id)
        end
    end

    return build_outer_skin_tabs(frame, roleName, skinsByQuality)
end


local function flatten_skin_data(data)
    local flatData = {}
    for roleName, skins in pairs(data) do
        for skinName, skin in pairs(skins) do
            table.insert(flatData, {
                id = skin.id,
                ["角色"] = roleName,
                ["时装名称"] = skinName,
                ["稀有度"] = skin.quality,
                ["简介"] = skin.desc,
            })
        end
    end
    return flatData
end

local function render_skin_image(skin)
	local rarityPopupSet = { [3] = true, [4] = true, [5] = true, [6] = true }
    local file = "角色时装图鉴_" .. skin.id .. ".png"
    local role = skin['角色']
    local skinName = skin['时装名称']

    if rarityPopupSet[skin['稀有度']] then
        return '<span class="popup"><span style="display: table-cell;"><div style="position:relative;">[[File:'
            .. file .. '|200px|link=]]'
            .. '</div></span><span style="display:none;">[[file:'
            .. role .. '时装-' .. skinName .. '.jpg|200px]]</span></span>'
    end

    return '[[文件:' .. file .. '|200px|link=]]'
end

local function render_acquire_method(ways)
    if type(ways) ~= "table" then return "" end
    local parts = {}
    for _, part in ipairs(ways) do
        if part and part ~= "" then
            parts[#parts + 1] =
                '<span class="badge bg-primary">'..part..'</span>'
        end
    end
    return table.concat(parts, "<br>")
end

p["角色时装筛选"] = function (frame)
    local flatData = flatten_skin_data(skinData)
    local result = {}
    
    for _, skin in ipairs(flatData) do
    	if skin["稀有度"] ~= 0 and not (skin["稀有度"] == 5 and check_has_hyphen(skin["时装名称"])) then
			-- 从 模块:获得方式/RoleSkin 获取四个指定字段
			local waysInfo = get_ways_module.getWays("RoleSkin", skin.id)
			local waysTable = type(waysInfo) == "table" and waysInfo or {}
			
			local ways = type(waysTable.get) == "table" and waysTable.get or {}
			local validWays = {}
			for _, v in ipairs(ways) do
				if non_empty(v) then
					validWays[#validWays + 1] = v
				end
			end
			local acquireStr = table.concat(validWays, ",")
			local babloCrystals = tostring(waysTable.BabloCrystals or "")
			local basestrings = tostring(waysTable.Basestrings or "")
			local remarkText = waysTable.remark or ""

            local cardHtml = frame:expandTemplate{
                title = "Gallerygrid/RoleSkin",
                args = {
                    ["角色"] = skin["角色"],
                    ["稀有度"] = skin['稀有度'],
                    ["时装名称"] = skin["时装名称"],
                    ["时装图片"] = render_skin_image(skin), 
                    ["稀有度标签"] = strinova.rarity_tag(frame, skin['稀有度']),
                    ["获得方式数据"] = acquireStr,
                    ["巴布洛晶核数据"] = str_fallback(babloCrystals, "无"),
                    ["基弦数据"] = str_fallback(basestrings, "无"),
                    ["巴布洛晶核"] = non_empty(babloCrystals) and (babloCrystals .. "[[文件:图标-小巴布洛晶核.png|15px|link=]]") or "",
                    ["基弦"] = non_empty(basestrings) and (basestrings .. "[[文件:图标-小基弦.png|15px|link=]]") or "",
                    ["获得方式"] = render_acquire_method(ways),
                    ["简介"] = skin["简介"] or "",
                    ["备注"] = remarkText,
                }
            }
            table.insert(result, cardHtml)
        end
    end
    
    return '<div class="gallerygrid">' .. table.concat(result) .. '</div>'
end


p["意识重构时装筛选"] = function (frame)
    local get = frame.args[1]
	local targetIds = get_ways_module.getIdsByWay("RoleSkin", get)
    local formatter = stringUtil.Formatter [=[
|-
| {时装}
| {稀有度标签}
| {简介}
]=]

    if #targetIds == 0 then return "暂无符合该获得途径的时装" end
	
	local idSet = {}
	for _, id in ipairs(targetIds) do idSet[id] = true end
	
    local resultList = {}

    for roleName, skins in pairs(skinData) do
        for skinName, skin in pairs(skins) do
            if idSet[skin.id] then
                table.insert(resultList, formatter({
                    ['时装'] = render_skin_image({
                        ['id'] = skin.id,
                        ['角色'] = roleName,
                        ['时装名称'] = skinName,
                        ['稀有度'] = skin.quality,
                    }).."<br>" .. roleName .. "：" .. skinName,
                    ['稀有度标签'] = strinova.rarity_tag(frame, skin.quality),
                    ['简介'] = skin.desc or "",
                }, ''))
            end
        end
    end
    
    if #resultList == 0 then return "暂无符合该获得途径的时装" end

    return table.concat(resultList)
end


return p