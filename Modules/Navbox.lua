local nav = {}

local notnil = function(value, default) return value or default end
local __nn = notnil
local notnilnorempty = function(value, default)
    if value == nil then return default
    elseif type(value) == "string" and value == "" then return default
    else return value
    end
end
local __nne = notnilnorempty
local notnilnorwhitespace = function(value, default)
    if value == nil then return default
    elseif type(value) == "string" then
        if value == "" then return value
        elseif mw.text.trim(value) == "" then return default
        else return value
        end
    else return value
    end
end
local __nnw = notnilnorwhitespace
local notnilnoremptynorwhitespace = function(value, default)
    if value == nil then return default
    elseif type(value) == "string" and mw.text.trim(value) == "" then return default
    else return value
    end
end
local __nnew = notnilnoremptynorwhitespace

local iif = function(condition, truevalue, falsevalue)
    if condition then return truevalue
    else return falsevalue
    end
end

--[[
    获取当前参数的序号，支持多个序号，且支持多种写法兼容。
pattern:
    格式以正则表达式为基础，另增以下匹配符：
    % - 将自动替换成正则表达式的“(%d+)”，用以匹配这个位置上的序号。
    %% - 将自动替换成正则表达式的“%”，用作正则表达式中“%”字符的转义。
返回：
    【所有序号文本】     【所有序号数值】
    注：以上每个值段都是一个独立的返回值列表项；
示例：
    paramname: prefix000infix10postfix08
    pattern: ^prefix%infix%postfix%$
    返回：000     10     08     0     10     8
--]]
local paramindexes = function(paramname, pattern)
    local indexes = { mw.ustring.match(paramname, mw.ustring.gsub(pattern, "%%%%?", function(m)
        if m == "%%" then return "%"
        else return "(%d+)"
        end
    end)) }
    local count = #indexes
    if count ~= 0 then
        for i = 1, count do
            indexes[i + count] = tonumber(indexes[i])
        end

        return unpack(indexes)
    end
end

local indexedparamvalue = function(args, pattern, raw, index, rawfunc, indexfunc)
    if args == nil or pattern == nil or raw == nil or index == nil then return nil end
    if rawfunc ~= nil and indexfunc == nil then indexfunc = rawfunc end
    rawfunc = rawfunc or __nnew
    indexfunc = indexfunc or __nnew
    if type(raw) ~= "table" then raw = { raw } end
    if type(index) ~= "table" then index = { index } end

    local i = 0
    rawname = mw.ustring.gsub(pattern, "%%%%?", function(m)
        if m == "%%" then return "%"
        else
            i = i + 1
            return tostring(raw[i] or "")
        end
    end)
    rawvalue = args[rawname]
    local result = rawfunc(rawvalue)
    if result then return result end
    i = 0
    indexname = mw.ustring.gsub(pattern, "%%%%?", function(m)
        if m == "%%" then return "%"
        else
            i = i + 1
            return tostring(index[i] or "")
        end
    end)
    indexvalue = args[indexname]
    result = indexfunc(indexvalue)
    if result then return result end

    local fuzzyMatchingOn = __nnew(args.fuzzyMatchingOn, "no") == "yes" -- 模糊匹配。
    if not fuzzyMatchingOn then return nil end -- 不启用参数名模糊匹配时处理流程到此结束。

    -- 开始进行参数名模糊匹配。
    -- 由于大多数参数名格式均为“【名称】【数字序号】”，将【名称】前缀作为第一道筛选程序将会减少耗时的正则匹配函数运行次数，大大优化代码运行效率。
    local prefixpos = 1
    local v1, v2 = 1, 0
    while true do
        local v1, v2 = mw.ustring.find(pattern, "%%+", v1)
        if v1 == nil then
            prefixpos = mw.ustring.len(pattern) + 1
            break
        elseif (v2 - v1) % 2 == 0 then
            prefixpos = v2
            break
        else
            v1 = v2 + 1
        end
    end
    local prefix = mw.ustring.gsub(mw.ustring.sub(pattern, 1, prefixpos - 1), "%%%%", "%") -- 获取纯文本前缀。
    local prefixlen = mw.ustring.len(prefix) -- 获取纯文本前缀字符长度。

    for k, v in pairs(args) do
        if k ~= rawname and k ~= indexname and mw.ustring.sub(k, 1, prefixlen) == prefix then -- 排除已处理参数名称，并筛选【名称】前缀。
            local indexes = { paramindexes(k, "^"..pattern.."$") } -- 获取各序号部分。
            local offset = #indexes / 2 -- 纯数字序号部分的偏移值，也作为序号的个数。
            if #index == offset then -- 序号数量一致。
                local equal = true -- 序号序列一致标识符。
                for _i, _index in ipairs(index) do
                    if _index ~= indexes[_i + offset] then
                        equal = false
                        break
                    end
                end
                if equal then
                    result = rawfunc(v) or indexfunc(v)
                    if result then return result end
                end
            end
        end
    end
end

local xor = function(left, right) return (left == true and right ~= true) or (left ~= true and right == true) end

local detectevenodd = function(list_previous, evenodd_i, evenodd, iseven)
    if evenodd_i == "swap" then
        if evenodd == "even" or evenodd == "odd" then
            return true, evenodd -- 每次swap都交换一次，基础值：全局evenodd。
        else
            return true, nil -- 每次swap都交换一次。
        end
    end

    if evenodd == "even" or evenodd == "odd" then
        return false, evenodd -- 不交换，基础值：全局evenodd。
    end

    if list_previous then
        -- 在上一个列表的HTML代码中查找最后一项的class。
        list_previous = mw.ustring.gsub(list_previous, "<!%-%-.-%-%->", "") -- 删除HTML注释。
        local evenodd_previous = nil -- 上一个navbox-list奇偶样式（抓取自td标签的class属性）。
        for tagstart, classstr in mw.ustring.gmatch(list_previous, [[<%s*([Tt][Dd][^>]-)%s[Cc][Ll][Aa][Ss][Ss]="([^"]-navbox%-list[^"]-)"]]) do
            if mw.text.trim(mw.ustring.sub(tagstart, 3, 3)) == "" then -- 标签是td。
                for _, class in ipairs(mw.text.split(classstr, "%s+")) do
                    class = mw.ustring.match(class, "^navbox%-(.+)$")
                    if class == "even" or class == "odd" then
                        evenodd_previous = class
                    end
                end
            end
        end
        if evenodd_previous then -- 找到上一个列表中的最后一项的class
            return xor(evenodd_previous == "even", not iseven), nil -- 当最后一项的奇偶性与当前项的奇偶性相同时交换一次。
        end
    end

    return false, nil -- 不进行样式修正。
end

local function _bar(args, frame)
    local node = mw.html.create()

    local nodiv = __nnew(args.nodiv)
    local style = __nnew(args.style)
    if nodiv then
        node = node:wikitext("&nbsp;"):tag("span")
    else
        node = node:tag("div")
    end
    node:addClass("noprint")
        :addClass("plainlinks")
        :addClass("hlist")
        :addClass("navbar")
        :addClass("nomobile")
        :cssText(style)

    ---------------核心代码---------------

    --- 左方括号 ---
    local brackets = __nnew(args.brackets)
    if brackets then
        node = node:wikitext("&#91;")
    end

    --- 前文 ---
    local mini = __nnew(args.mini)
    local miniv = __nnew(args.miniv)
    local plain = __nnew(args.plain) or __nnew(args.viewplain)
    if not (mini or miniv or plain) then
        node:wikitext("本模板:&nbsp;")
    end

    local _1 = __nn(args[1], "{{{1}}}")
    local fontstyle = __nnew(args.fontstyle)
    local fontcolor = __nnew(args.fontcolor, "#002bb8")
    local history = __nnew(args.history)
    local purge = __nnew(args.purge)

    local span
    node:wikitext("[[Template:".._1.."|")

    span = node:tag("span")
        :css("background", "transparent!important")
    if fontstyle then
        span:cssText(fontstyle)
    else
        span:css("color", fontcolor)
    end
    span:attr("title", "-{zh-hans:查看;zh-hant:檢視}-这个模板")
    if miniv then
        span:wikitext("v")
    elseif plain then
        span:wikitext("view")
    elseif mini then
        span:wikitext("查")
    else
        span:wikitext("-{zh-hans:查看;zh-hant:檢視}-")
    end
    node:wikitext("]]")

    if not (miniv or plain) then
        node:wikitext("&nbsp;·&nbsp;[[Template talk:".._1.."|")

        span = node:tag("span")
            :css("background", "transparent!important")
        if fontstyle then
            span:cssText(fontstyle)
        else
            span:css("color", fontcolor)
        end
        span:attr("title", "关于这个模板的讨论页面")
        if mini then
            span:wikitext("论")
        else
            span:wikitext("讨论")
        end

        node:wikitext("]]&nbsp;·&nbsp;[")
            :wikitext(frame:preprocess("{{fullurl:Template:".._1.."|action=edit}}"))
            :wikitext(" ")

        span = node:tag("span")
            :css("background", "transparent!important")
        if fontstyle then
            span:cssText(fontstyle)
        else
            span:css("color", fontcolor)
        end
        span:attr("title", "您可以编辑这个模板。请在储存变更之前先预览")
        if mini then
            span:wikitext("编")
        else
            span:wikitext("编辑")
        end
        node:wikitext("]")

        if history then
            node:wikitext("&nbsp;·&nbsp;[")
                :wikitext(frame:preprocess("{{fullurl:Template:".._1.."|action=history}}"))
                :wikitext(" ")

            span = node:tag("span")
                :css("background", "transparent!important")
            if fontstyle then
                span:cssText(fontstyle)
            else
                span:css("color", fontcolor)
            end
            span:attr("title", "-{zh-hans:查看;zh-hant:查詢}-这个模板的编辑历史")
            if mini then
                span:wikitext("历")
            else
                span:wikitext("历史")
            end
            node:wikitext("]")
        end

        if purge then
            node:wikitext("&nbsp;·&nbsp;[")
                :wikitext(frame:preprocess("{{fullurl:Template:".._1.."|action=purge}}"))
                :wikitext(" ")

            span = node:tag("span")
                :css("background", "transparent!important")
            if fontstyle then
                span:cssText(fontstyle)
            else
                span:css("color", fontcolor)
            end
            span:attr("title", "清除这个模板的缓存")
            if mini then
                span:wikitext("清")
            else
                span:wikitext("清除缓存")
            end
            node:wikitext("]")
        end
    end

    --- 右方括号 ---
    if brackets then
        node = node:wikitext("&#93;"):done()
    end

    --------------------------------------

    if nodiv then
        node:wikitext("&nbsp;")
    end

    return node
end

local function _box(args, frame)
    local node = mw.html.create()

    local border = __nnew(args.border) or __nne(args[1])
    if border ~= nil then border = mw.text.trim(border) end
    -- 删去可能会有的多余的空白字符。
    if type(border) == "string" then
        border = mw.text.trim(border)
    end
    -- 当前模板用于生成子列表时，关闭父模板用于padding的div
    if border == "subgroup" or border == "child" then
        node:wikitext("</div>")
    elseif border ~= "none" then
        node = node:tag("table")
                :addClass("navbox")
                :addClass(__nnew(args.class))
                :attr("cellspacing", 0)
                :cssText(__nnew(args.bodystyle))
                :cssText(__nnew(args.style))
                :tag("tr")
                    :tag("td")
                    :css("padding", "2px")
    end

    node = node:tag("table")
            :attr("cellspacing", 0)
            :addClass("nowraplinks")
            :css("display", "table")
            :css("width", "100%")
            :cssText(__nnew(args.innerstyle))
    local title = __nnew(args.title)
    local state = __nnew(args.state)
    if title then
        if state ~= "plain" and state ~= "off" then
            node:addClass("mw-collapsible")
                :addClass(state or "autocollapse")
        end
    end
    if border == "subgroup" or border == "child" or border == "none" then
        node:addClass("navbox-subgroup")
            :cssText(__nnew(args.bodystyle))
            :cssText(__nnew(args.style))
    else
        node:css("background", "transparent")
            :css("color", "inherit")
    end
    ---------------核心代码---------------

    local imageleft = __nnew(args.imageleft)
    local image = __nnew(args.image)

    --- Title and Navbar ---
    local grouppadding = __nnew(args.grouppadding)
    local groupstyle = __nnew(args.groupstyle)
    local basestyle = __nnew(args.basestyle)
    if title then
        local temp = node
        node = node:tag("tr")
        local titlegroup = __nnew(args.titlegroup)
        if titlegroup then
            node = node:tag("td")
                    :addClass("navbox-group")
                    :cssText(basestyle)
                    :cssText(groupstyle)
                    :cssText(__nnew(args.titlegroupstyle))
                    :wikitext(titlegroup)
                    :tag("th")
                        :css("border-left", "2px solid transparent")
                        :css("width", "100%")
        else
            node = node:tag("th")
        end
        local titlestyle = __nnew(args.titlestyle)
        local titleclass = __nnew(args.titleclass)
        node:addClass(titleclass)
            :cssText(basestyle)
            :cssText(titlestyle)
            :attr("colspan", 2 + iif(imageleft, 1, 0) + iif(image, 1, 0) + iif(titlegroup, -1, 0))
            :addClass("navbox-title")

        local navbar = __nnew(args.navbar)
        local name = __nnew(args.name)
        if (navbar == "plain" or navbar == "off") or
            (not name and (border == "subgroup" or border == "child" or border == "none")) then
            if navbar == "off" then
                if state == "plain" then
                    node:tag("div")
                            :css("float", "right")
                            :css("width", "2.78em")
                            :wikitext("&nbsp;")
                end
            elseif state ~= "plain" then
                node:tag("div")
                        :css("float", "left")
                        :css("width", "2.78em")
                        :css("text-align", 'left')
                        :wikitext("&nbsp;")
            end
        else
            node:tag("div")
                    :css("float", "left")
                    :css("width", "2.78em")
                    :css("text-align", 'left')
                    :tag("span")
                            :addClass("mobileonly")
                            :wikitext("&nbsp;")
                            :done()
                    :node(_bar({
                        [1] = args.name,
                        fontstyle = iif(basestyle, (basestyle or "")..";", "")..iif(titlestyle, (titlestyle or "")..";", "").."border:none",
                        mini = 1
                    }, frame))
            if state == "plain" then
                node:tag("div")
                        :css("float", "right")
                        :css("width", "2.78em")
                        :wikitext("&nbsp;")
            end
        end
        node:tag("span")
                :css("font-size", iif(border == "subgroup" or border == "child" or border == "none", "100%", "110%"))
                :wikitext(args.title or "{{{title}}}")

        node = temp -- 复原节点位置
    end

    --- Above ---
    local above = __nnew(args.above)
    if above then
        if title then
            node:tag("tr"):css("height", "2px"):tag("td")
        end
        node:tag("tr"):tag("td")
                :addClass("navbox-abovebelow")
                :cssText(basestyle)
                :cssText(__nnew(args.abovestyle))
                :attr("colspan", 2 + iif(imageleft, 1, 0) + iif(image, 1, 0))
                :wikitext(args.above or "{{{above}}}")
    end

    --- Body ---
    local lists = {}
    local listmax = 0
    for k, v in pairs(args) do
        if type(k) == "string" and mw.ustring.sub(k, 1, 4) == "list" then
            local raw, index = paramindexes(k, "^list%$")
            if index ~= nil and index > 0 and __nnew(v) then
                table.insert(lists, { raw, index, v }) -- 添加新项
                lists[tostring(index)] = #lists -- 将字符串格式的搜索键映射到对应的新项索引
                listmax = math.max(listmax, index)
            end
        end
    end

    --- groups/lists ---
    local evenstyle = __nnew(args.evenstyle)
    local oddstyle = __nnew(args.oddstyle)
    local evenodd = __nnew(args.evenodd)
    local liststyle = __nnew(args.liststyle)
    local listpadding = __nnew(args.listpadding)

    local visiblelist = 0 -- 可见的列表。
    local imageleftnode, imagenode
    local swap = evenodd == "swap" -- 列表项奇偶样式是否交换。
    local autoSwapOn = __nnew(args.autoSwapOn, "yes") == "yes" -- 自动交换开关。
    for index = 1, listmax do
        if lists[tostring(index)] then -- 存在这个键
            visiblelist = visiblelist + 1 -- 增加计数。

            local raw, _, list_i = unpack(lists[lists[tostring(index)]])
            if visiblelist > 1 or (title or above) then
                node:tag("tr"):css("height", "2px"):tag("td")
            end

            local tr = node:tag("tr")

            if visiblelist == 1 then
                if imageleft then
                    imageleftnode = tr:tag("td")
                            :css("width", "0%")
                            :css("padding", "0px 2px 0px 0px")
                            :cssText(__nnew(args.imageleftstyle))
                            :wikitext(imageleft)
                end
            end

            local td
            local group_i = indexedparamvalue(args, "group%", raw, index)
            if group_i then
                local groupstyle_i = indexedparamvalue(args, "group%style", raw, index)
                td = tr:tag("td")
                        :addClass("navbox-group")
                        :cssText(basestyle)
                        :cssText(groupstyle)
                        :cssText(groupstyle_i)
                        :wikitext(group_i)
                        :done()
                    :tag("td")
                        :css("text-align", "left")
                        :css("border-left", "2px solid transparent")
            else
                td = tr:tag("td")
                        :attr("colspan", 2)
            end
            local liststyle_i = indexedparamvalue(args, "list%style", raw, index)
            local list_previous = nil -- 上一个可见列表内容。
            if autoSwapOn then -- 通过控制list_previous是否为nil来控制是否执行自动交换程序。
                for _index = index - 1, 1, -1 do
                    if lists[tostring(_index)] then -- 存在这个键
                        _, _, list_previous = unpack(lists[lists[tostring(_index)]])
                        break
                    end
                end
            end
            local evenodd_i = indexedparamvalue(args, "evenodd%", raw, index)
            if evenodd_i ~= "even" and evenodd_i ~= "odd" then
                local swap_i = nil
                swap_i, evenodd_i = detectevenodd(list_previous, evenodd_i, evenodd, xor(visiblelist % 2 == 0, swap)) -- 查找上一列表中的最后一项的样式。
                if swap_i then swap = not swap end -- 交换列表项奇偶样式。
                if evenodd_i then
                    if swap then
                        evenodd_i = iif(evenodd_i == "even", "odd", "even")
                    end
                else
                    evenodd_i = iif(xor(visiblelist % 2 == 0, swap), "even", "odd")
                end
            end
            td:addClass("navbox-list")
                :addClass("navbox-"..evenodd_i)
                :css("width", "100%")
                :css("padding", "0px")
                :cssText(liststyle)
            if evenodd_i == "even" then td:cssText(evenstyle)
            elseif evenodd_i == "odd" then td:cssText(oddstyle)
            else td:cssText(iif(xor(visiblelist % 2 == 0, swap), evenstyle, oddstyle)) -- 偶数行使用evenstyle，奇数行使用oddstyle。（特殊情况下交换。）
            end
            td:cssText(liststyle_i)
                :tag("div")
                    :css("padding", listpadding or "0em 0.25em")
                    :wikitext(list_i)

            if visiblelist == 1 then
                if image then
                    imagenode = tr:tag("td")
                            :css("width", "0%")
                            :css("padding", "0px 0px 0px 2px")
                            :cssText(__nnew(args.imagestyle))
                            :wikitext(image)
                end
            end
        end
    end
    if imageleftnode then
        imageleftnode:attr("rowspan", visiblelist * 2 - 1)
    end
    if imagenode then
        imagenode:attr("rowspan", visiblelist * 2 - 1)
    end

    --- Below ---
    local below = __nnew(args.below)
    if below then
        if title or above or visiblelist ~= 0 then
            node:tag("tr"):css("height", "2px"):tag("td")
        end
        node:tag("tr"):tag("td")
                :addClass("navbox-abovebelow")
                :cssText(basestyle)
                :cssText(__nnew(args.belowstyle))
                :attr("colspan", 2 + iif(imageleft, 1, 0) + iif(image, 1, 0))
                :wikitext(below)
    end
    --------------------------------------

    node = node:allDone() -- 回到最上层节点。
    -- 当前模板用于生成子列表时，对标上文父模板被关闭的div
    if border == "subgroup" or border == "child" then
        node:wikitext("<div>")
    end

    return node
end

local function _subgroupbox(args, frame)
    args.border = __nnew(args.border, "subgroup")

    args.style = (args.style or "")..iif(args.bodystyle, ";"..(args.bodystyle or ""), "")

    return args
end

-- 前排提醒，不要边遍历table边给元素设置为nil，特别是非当前元素！
local function _collapsiblegroupsbox(args, frame)
	local newargs = {}
    newargs[1] = args[2]

    newargs.style = (args.style or "")..iif(args.bodystyle, ";"..(args.bodystyle or ""), "")

    local selected = __nnew(args.selected)
    local basestyle = __nnew(args.basestyle)
    local groupstyle = __nnew(args.groupstyle)
    local sectstyle = __nnew(args.sectstyle)
    local secttitlestyle = __nnew(args.secttitlestyle)
    local liststyle = __nnew(args.liststyle)
    for k, v in pairs(args) do
        if type(k) == "string" then
            local raw, index = paramindexes(k, "^list%$")
            if index ~= nil and index > 0 and __nnew(v) then
                local group_i = indexedparamvalue(args, "group%", raw, index)
                local sect_i = indexedparamvalue(args, "sect%", raw, index)
                local abbr_i = indexedparamvalue(args, "abbr%", raw, index)
                local state_i = indexedparamvalue(args, "state%", raw, index)
                local groupstyle_i = indexedparamvalue(args, "group%style", raw, index)
                local sectstyle_i = indexedparamvalue(args, "sect%style", raw, index)
                local liststyle_i = indexedparamvalue(args, "list%style", raw, index)
                local image_i = indexedparamvalue(args, "image%", raw, index)
                local imageleft_i = indexedparamvalue(args, "imageleft%", raw, index)
                local _args = {
                    border = "child",
                    state = iif(selected == abbr_i, "mw-uncollapsed", state_i or "mw-collapsed"),
                    style = (sectstyle or "")..iif(sectstyle_i, ";"..(sectstyle_i or ""), ""),
                    titlestyle = (basestyle or "")..iif(groupstyle, ";"..(groupstyle or ""), "")..iif(secttitlestyle, ";"..(secttitlestyle or ""), "")..iif(groupstyle_i, ";"..(groupstyle_i or ""), ""),
                    liststyle = (liststyle or "")..iif(liststyle_i, ";"..(liststyle_i or ""), ""),
                    title = group_i or sect_i,
                    list1 = v,
                    image = image_i,
                    imageleft = imageleft_i
                }

                newargs[k] = tostring(_box(_args, frame))
            end
        end
    end
    -- 白名单，不保证没有缺漏或多余
    local list_valid = { 'name', 'state', 'navbar', 'border', 'title', 'above', 'image', 'imageleft', 'below', 'selected', 'bodystyle', 'titlestyle', 'titleclass',
    	'abovestyle', 'belowstyle', 'basestyle', 'imagestyle', 'imageleftstyle', 'sectstyle', 'groupstyle', 'liststyle', 'listpadding' }
    for _, val in ipairs(list_valid) do
    	if args[val] then newargs[val] = args[val] end
    end

    return newargs
end

local function _columnsbox(args, frame)
    args[1] = args[2]
    args[2] = nil

    local bodystyle = __nnew(args.bodystyle)
    args.style = (args.style or "")..iif(bodystyle, ";"..(bodystyle or ""), "")
    args.tracking = "no"

    local lists = {}
    -- 收集所有含有列的列表。
    for k, v in pairs(args) do
        if type(k) == "string" then
            local lraw, craw, lindex, cindex -- list和column的raw和index。
            craw, cindex = paramindexes(k, "^col%$") -- 为兼容，先检查是否存在 col+数字 格式的参数。
            if cindex ~= nil then
                lraw, lindex = "1", 1
            else -- 匹配指定列表和列的序号的参数。
                lraw, craw, lindex, cindex = paramindexes(k, "^list%col%$")
            end
            if lindex ~= nil and lindex > 0 and cindex > 0 and __nnew(v) then
                local cols
                if lists[tostring(lindex)] then
                    cols = lists[lists[tostring(lindex)]]
                else
                    cols = {}
                    table.insert(lists, cols) -- 添加新项
                    lists[tostring(lindex)] = #lists -- 将字符串格式的搜索键映射到对应的新项索引
                    lists["#"] = math.max(lists["#"] or 0, lindex)
                end

                table.insert(cols, { { lraw, craw }, { lindex, cindex }, v }) -- 添加新项
                cols[tostring(cindex)] = #cols -- 将字符串格式的搜索键映射到对应的新项索引
                cols["#"] = math.max(cols["#"] or 0, cindex)

                args[k] = nil -- 清除原有的内容以便覆写，防止影响Navbox构造逻辑。
            end
        end
    end

    local coltablestyle = __nnew(args.coltablestyle)
    local fullwidth = __nnew(args.fullwidth)
    local colwidth = __nnew(args.colwidth)
    local colheaderstyle = __nnew(args.colheaderstyle)
    local padding = __nnew(args.padding)
    local colstyle = __nnew(args.colstyle)
    local oddcolstyle = __nnew(args.oddcolstyle)
    local evencolstyle = __nnew(args.evencolstyle)
    for lindex = 1, lists["#"] do
        local cols = lists[lists[tostring(lindex)]]
        if cols then
            local node = mw.html.create("table")
                :addClass("navbox-columns-table")
                :css("border-spacing", "0px")
                :css("text-align", "left")
                :cssText(coltablestyle)
            --if fullwidth then
                node = node:css("width", "100%")
            --else
            --    node = node
            --        :css("width", "auto")
            --        :css("margin-left", "auto")
            --        :css("margin-right", "auto")
            --end

            local header = mw.html.create("tr") -- Header row
            local main = mw.html.create("tr") -- Main columns
            local footer = mw.html.create("tr") -- Footer row

            local hasheader = false
            local hasfooter = false
            local visiblecol = 0 -- 计数可见的列。
            for cindex = 1, cols["#"] do
                if cols[cols[tostring(cindex)]] then
                    visiblecol = visiblecol + 1 -- 增加计数。

                    local raw, index, col_i = unpack(cols[cols[tostring(cindex)]])
                    local colheader_i = indexedparamvalue(args, "list%col%header", raw, index)
                    local colfooter_i = indexedparamvalue(args, "list%col%footer", raw, index)
                    local colstyle_i = indexedparamvalue(args, "list%col%style", raw, index)
                    local colheadercolspan_i = indexedparamvalue(args, "list%col%headercolspan", raw, index)
                    local colfootercolspan_i = indexedparamvalue(args, "list%col%footercolspan", raw, index)
                    local colheaderstyle_i = indexedparamvalue(args, "list%col%headerstyle", raw, index)
                    local colfooterstyle_i = indexedparamvalue(args, "list%col%footerstyle", raw, index)
                    local colwidth_i = indexedparamvalue(args, "list%col%width", raw, index)
                    if lindex == 1 then -- 如果是第一个列表，则需要考虑兼容，检查省略list1的参数名称。
                        colheader_i = colheader_i or indexedparamvalue(args, "col%header", raw[2], index[2])
                        colfooter_i = colfooter_i or indexedparamvalue(args, "col%footer", raw[2], index[2])
                        colstyle_i = colstyle_i or indexedparamvalue(args, "col%style", raw[2], index[2])
                        colheadercolspan_i = colheadercolspan_i or indexedparamvalue(args, "col%headercolspan", raw[2], index[2])
                        colfootercolspan_i = colfootercolspan_i or indexedparamvalue(args, "col%footercolspan", raw[2], index[2])
                        colheaderstyle_i = colheaderstyle_i or indexedparamvalue(args, "col%headerstyle", raw[2], index[2])
                        colfooterstyle_i = colfooterstyle_i or indexedparamvalue(args, "col%footerstyle", raw[2], index[2])
                        colwidth_i = colwidth_i or indexedparamvalue(args, "col%width", raw[2], index[2])
                    end

                    --- Header row ---
                    local hcol
                    if colheader_i then
                        hasheader = true

                        hcol = header:tag("td")
                            :addClass("navbox-abovebelow")
                            :attr("colspan", colheadercolspan_i or 1)
                            :css("font-weight", "bold")
                            :cssText(colheaderstyle)
                            :cssText(colheaderstyle_i)
                            :wikitext(colheader_i)
                    end

                    --- Main columns ---
                    main:css("vertical-align", "top")

                    if visiblecol == 1 and
                        not (colheader_i or colfooter_i or fullwidth) and
                        not (padding == "off" or mw.ustring.find(padding, "^;*-?0+%a+;*$"))
                        then
                        main:tag("td"):css("width", padding or "5em"):wikitext("&nbsp;&nbsp;&nbsp;")
                    end

                    mcol = main:tag("td")
                        :css("padding", "0px")
                        :css("width", colwidth_i or colwidth or "10em")
                        :cssText(colstyle)
                        :cssText(iif(visiblecol % 2 == 1, oddcolstyle, evencolstyle))
                        :cssText(colstyle_i)
                        :tag("div")
                            :wikitext(col_i)
                            :done()

                    --- Footer row ---
                    local fcol
                    if colfooter_i then
                        hasfooter = true

                        fcol = footer:tag("td")
                            :addClass("navbox-abovebelow")
                            :att("colspan", colfootercolspan_i or 1)
                            :css("font-weight", "bold")
                            :cssText(colfooterstyle)
                            :cssText(colfooterstyle_i)
                            :wikitext(colfooter_i)
                    end

                    if visiblecol ~= 1 then
                        mcol:css("border-left", "2px solid #fdfdfd")
                        if hcol then
                            hcol:css("border-left", "2px solid #fdfdfd")
                        end
                        if fcol then
                            fcol:css("border-left", "2px solid #fdfdfd")
                        end
                    end
                end
            end

            node:node(header) -- 添加Header row。
            if hasheader then
                node:tag("tr"):css("height", "2px"):tag("td") -- 添加header下方的分隔线。
            end
            node:node(main) -- 添加Main columns。
            if hasfooter then
                node:tag("tr"):css("height", "2px"):tag("td") -- 添加footer上方的分隔线。
            end
            node:node(footer) -- 添加Footer row。

            args["list"..tostring(lindex)] = tostring(node)
            args["list"..tostring(lindex).."style"] = "background:transparent;color:inherit;"
            args["list"..tostring(lindex).."padding"] = "0px"
        end
    end

    return args
end

local checkNamespaces = function(frame)
    local title = mw.title.new(frame:getParent():getTitle())
    if not title:inNamespaces(
        "Template"
    ) and not mw.title.equals(title, mw.title.new("沙盒", "Help")) and not mw.title.equals(title, mw.title.new("Nav", "Module_talk")) then
        return "[[Category:在非模板名字空间下的页面中调用Nav模块]]"
    end
end

local getArgs = function(frame)
    local _params_ = __nnew(frame.args._params_, "overwrite")

    if _params_ == "self" then
        return frame.args
    elseif _params_ == "overwrite" then
        local parent = frame:getParent()
        local args = {}
        if parent ~= nil then
            for k, v in pairs(parent.args) do
                args[k] = v
            end
        end
        for k, v in pairs(frame.args) do
            if k ~= "_params_" then
                args[k] = v
            end
        end
        return args
    elseif _params_ == "default" then
        local parent = frame:getParent()
        local args = {}
        for k, v in pairs(frame.args) do
            if k ~= "_params_" then
                args[k] = v
            end
        end
        if parent ~= nil then
            for k, v in pairs(parent.args) do
                args[k] = v
            end
        end
        return args
    else
        return nil
    end
end

function nav.box(frame)
    local result = checkNamespaces(frame) or ""
    local args = getArgs(frame)
    if args == nil then
        return require("Module:Error").error({ message = mw.ustring.format("不能识别的参数获取方式：“%s”", frame.args._params_ or "") })
    end

    local version = __nne(args[1])
    if version ~= nil then version = mw.text.trim(version) end
    local border = __nnew(args.border) or version
    if border == "subgroup" then
        args = _subgroupbox(args, frame)
    elseif version == "collapsible groups" then
        args = _collapsiblegroupsbox(args, frame)
    elseif version == "columns" then
        args = _columnsbox(args, frame)
    end

    return result..tostring(_box(args, frame))
end

function nav.bar(frame)
    local result = checkNamespaces(frame) or ""
    local args = getArgs(frame)
    if args == nil then
        return require("Module:Error").error({ message = mw.ustring.format("不能识别的参数获取方式：“%s”", frame.args._params_ or "") })
    end
    return result..tostring(_bar(args, frame))
end

return nav