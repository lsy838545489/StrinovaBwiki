local p = {}

-- 按指定分隔符分割字符串，并清理首尾空白（使用 plain 查找，支持多字符分隔符）
local function split(s, sep)
    local res = {}
    if not s or s == "" then return res end
    sep = sep or "、"
    local start = 1
    while true do
        local i, j = string.find(s, sep, start, true) -- plain 查找，避免模式干扰
        if not i then
            local part = mw.text.trim(string.sub(s, start))
            if part ~= "" then table.insert(res, part) end
            break
        end
        local part = mw.text.trim(string.sub(s, start, i - 1))
        if part ~= "" then table.insert(res, part) end
        start = j + 1
    end
    return res
end

function p.label(frame)
    local args = frame:getParent().args or frame.args or {}
    local items = {}

    -- 1) 读取逐号无名参数（优先）
    for i = 1, 100 do
        local v = args[tostring(i)]
        if not v or v == "" then break end
        table.insert(items, mw.text.trim(v))
    end

    -- 2) 如果没有逐号参数，尝试读取 items / list / 第一个无名参数并用 sep 分割
    local sep = args.sep or "、"
    if #items == 0 then
        local raw = args.items or args.list or args[1] or ""
        if raw and raw ~= "" then
            items = split(raw, sep)
        end
    end

    -- 其它可选参数
    local labelType = args["class"] or "label-default"
    local class = "label " .. labelType
    local css = args.css or ""
    local containerClass = args.containerClass or "" -- 可选：外层容器 class

    local html = mw.html.create("span")
    if containerClass ~= "" then
        html:addClass(containerClass)
    end

    for i, item in ipairs(items) do
        html:tag("span")
            :addClass(class)
            :cssText('font-size: 100%;' .. css)
            :wikitext(item)
            :done()

        if i < #items then
            html:wikitext(sep)
        end
    end

    return tostring(html)
end

function p.panel(frame)
	local args = frame:getParent().args or frame.args or {}
	local title = args["标题"] or ""

	local html = mw.html.create("div"):addClass("panel")
	html:tag("div"):addClass("panel-heading panel-heading-h2")
		:tag("div"):addClass("panel-title"):wikitext(title):done():done()

	for i = 1, 50 do
		local content = args["内容块"..i] and mw.text.trim(args["内容块"..i]) or nil
		if content and content ~= "" then
			local subtitle = args["小标题"..i] or ""
			if subtitle ~= "" then
				html:tag("div"):addClass("panel-title panel-title-h3"):wikitext(subtitle):done()
			end
			html:tag("div"):addClass("panel-body"):wikitext(content):done()
		end
	end

	return tostring(html)
end

function p.tabs(frame)
	local args = frame:getParent().args or frame.args or {}

	local tabs = {}
	for i = 1, 50 do
		local label = args["标签"..i]
		local content = args["标签内容"..i]
		if label and content then
			table.insert(tabs, {
				label = label or ("Tab "..i),
				content = content or "",
			})
		end
	end

	if #tabs == 0 then
		return ""
	end

	-- 构造 HTML（使用 mw.html）
	local html = mw.html.create("div")
		:addClass("tab")

	local ul = html:tag("ul")
		:addClass("nav")
		:addClass("nav-tabs")
		:attr("role", "tablist")

	for i, t in ipairs(tabs) do
		local is_active = (i == 1)
		local li = ul:tag("li")
			:attr("role", "presentation")
		if is_active then li:addClass("active") end
		li:wikitext(frame:callParserFunction('#tag:a', { t.label, class = 'radius5', href = '#'..t.label, ['data-toggle'] = 'tab' }))
	end

	local contentWrap = html:tag("div")
		:addClass("tab-content")

	for i, t in ipairs(tabs) do
		local is_active = (i == 1)
		local pane = contentWrap:tag("div")
			:addClass("tab-pane fade")
			:attr("id", t.label)
			:attr("role", "tabpanel")
		if is_active then pane:addClass("active in") end
		pane:wikitext(t.content)
	end

	return tostring(html)
end

return p