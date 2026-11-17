local p = {}

-- 辅助函数：按逗号分割字符串并去除空白
local function split_string(str)
    local resultList = {}
    for match in (str .. ","):gmatch("(.-)" .. ",") do
        local trimmed = mw.text.trim(match)
        if trimmed ~= "" then
            table.insert(resultList, trimmed)
        end
    end
    return resultList
end

function p.render(frame)
    local args = frame:getParent().args
    if not args.nav then 
        args = frame.args 
    end
    
    local navString = args.nav or ""
    local navItems = split_string(navString)
    
    -- 使用了重构后的类名 btn-tabs 和 btn-tabs__list
    local wrapperDiv = mw.html.create('div'):addClass('btn-tabs')
    local navUl = mw.html.create('ul'):addClass('btn-tabs__list')
    local contentDiv = mw.html.create('div'):addClass('tab-content')
    
    local isFirstActive = true
    
    for _, itemName in ipairs(navItems) do
        if mw.ustring.sub(itemName, 1, 3) == "下拉:" then
            local groupName = mw.ustring.sub(itemName, 4)
            local dropItemsStr = args[itemName] or ""
            local dropItems = split_string(dropItemsStr)
            
            local dropId = "btnTabDrop_" .. groupName
            
            local dropLi = mw.html.create('li'):addClass('dropdown')
            
            local dropToggleTag = frame:callParserFunction('#tag', {
                'a',
                groupName .. " ▾",
                href = "#",
                id = dropId,
                class = "dropdown-toggle",
                ['data-toggle'] = "dropdown"
            })
            
            local dropMenuUl = mw.html.create('ul')
                :addClass('dropdown-menu')
                :attr('role', 'menu')
                :attr('aria-labelledby', dropId)
            
            local hasActiveChild = false
            
            for _, subItemName in ipairs(dropItems) do
                local subId = "tab_pane_" .. subItemName
                
                local aTagDropdown = frame:callParserFunction('#tag', {
                    'a',
                    subItemName,
                    href = '#' .. subId,
                    ['data-toggle'] = "tab"
                })
                
                local subLi = mw.html.create('li'):wikitext(aTagDropdown)
                
                local subPane = mw.html.create('div')
                    :addClass('tab-pane')
                    :attr('id', subId)
                    :wikitext(args[subItemName] or "")
                    
                if isFirstActive then
                    subLi:addClass('active')
                    subPane:addClass('active')
                    hasActiveChild = true
                    isFirstActive = false
                end
                
                dropMenuUl:node(subLi)
                contentDiv:node(subPane)
            end
            
            if hasActiveChild then
                dropLi:addClass('active')
            end
            
            dropLi:wikitext(dropToggleTag):node(dropMenuUl)
            navUl:node(dropLi)
        else
            local tabId = "tab_pane_" .. itemName
            
            local aTagFixed = frame:callParserFunction('#tag', {
                'a',
                itemName,
                href = '#' .. tabId,
                ['data-toggle'] = "tab"
            })
                
            local tabLi = mw.html.create('li'):wikitext(aTagFixed)
            
            local tabPane = mw.html.create('div')
                :addClass('tab-pane')
                :attr('id', tabId)
                :wikitext(args[itemName] or "")
                
            if isFirstActive then
                tabLi:addClass('active')
                tabPane:addClass('active')
                isFirstActive = false
            end
            
            navUl:node(tabLi)
            contentDiv:node(tabPane)
        end
    end
    
    wrapperDiv:node(navUl):node(contentDiv)
    
    return tostring(wrapperDiv)
end

return p