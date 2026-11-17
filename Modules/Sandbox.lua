local p = {}

local acandy = require("模块:ACandy")
local a, Raw, Fragment = acandy.a, acandy.Raw, acandy.Fragment
local tr, th, td = a.tr, a.th, a.td
local strinova = require("模块:卡拉彼丘")

local SkinData = mw.loadData("模块:角色/SkinData")

-- 辅助函数：检查是否包含连字符喵
local function check_has_hyphen(str)
    return string.find(str, "-") ~= nil
end

-- 辅助函数：根据ID升序排序喵
local function sort_by_id(skinA, skinB)
    return skinA.id < skinB.id
end

-- 稀有度对应下拉菜单名称映射表喵
local QualityNameMap = {
    [5] = "传说",
    [4] = "完美",
    [3] = "卓越"
}

---- 视图层：生成内部时装详情 Tab 喵 ----
local function create_skin_img_tab(frame, characterName, skinName, skinQuality, isActive)
    local skinTabNav, skinTabContent = "", ""

    if skinQuality ~= 3 and not (skinQuality == 5 and check_has_hyphen(skinName)) then
        skinTabNav = a.li { ['data-toggle'] = 'tab', ['data-target'] = '#'..skinName..'立绘', '立绘' }
        skinTabContent = a.div { class = "tab-pane", id = skinName.."立绘", "[[文件:"..characterName.."-"..skinName.."立绘.png]]" }
    end

    local activeClass = isActive and "active" or ""

    return a.div { class = "tab-pane " .. activeClass, id = "skin_pane_" .. skinName,
        a.div { class = "klbq-skin-viewer",
            a.ul { class = "klbq-skin-viewer-list",
                a.li { class = "active", ['data-toggle'] = 'tab', ['data-target'] = '#'..skinName..'模型正面', '模型正面' },
                a.li { ['data-toggle'] = 'tab', ['data-target'] = '#'..skinName..'模型背面', '模型背面' },
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

                navTabs[#navTabs + 1] = a.li { class = isFirstActive and "active" or "",
                    Raw(aTagFixed)
                }
                tabPanes[#tabPanes + 1] = create_skin_img_tab(frame, roleName, skinName, quality, isFirstActive)
                
                isFirstActive = false
            end
        end
    end

    -- 处理带有下拉列表组的稀有度 (5, 4, 3)
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
                groupName .. "▾",
                href = "#",
                id = dropId,
                class = "dropdown-toggle",
                ['data-toggle'] = "dropdown"
            })

            navTabs[#navTabs + 1] = a.li { class = "dropdown",
                Raw(dropToggleTag),
                a.ul { class = "dropdown-menu", role = "menu", ['aria-labelledby'] = dropId, dropdownItems }
            }
        end
    end

    -- 组装最终的外层 BS3 Tabs 框架
    return a.div { class = "klbq-skin-group", 
        a.ul { class = "klbq-skin-group-list", navTabs },
        a.div { class = "tab-content", tabPanes }
    }, a.br
end

---- 逻辑层：主入口函数 喵 ----
p["角色时装"] = function (frame)
    local args = frame.args
    local roleName = strinova.get_page_title(args)
    local skinsByQuality = { [0] = {}, [6] = {}, [5] = {}, [4] = {}, [3] = {} }

    local roleSkinData = SkinData[roleName]
    if not roleSkinData then return "未找到角色数据" end

    -- 1. 数据收集与映射
    for skinName, skin in pairs(roleSkinData) do
        local rarity = skin['稀有度']
        local skinsOfThisQuality = skinsByQuality[rarity]
        if skinsOfThisQuality then
            skinsOfThisQuality[#skinsOfThisQuality + 1] = {
                name = skinName,
                id = skin['id'] or 9999
            }
        end
    end
    
    -- 2. 列表内排序
    for quality, skins in pairs(skinsByQuality) do
        if #skins > 1 then
            table.sort(skins, sort_by_id)
        end
    end

    -- 3. 调用视图层函数生成结果
    return build_outer_skin_tabs(frame, roleName, skinsByQuality)
end

return p