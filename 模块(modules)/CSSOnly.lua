local p = {}

local function normalize_css(css)
    if not css or css == "" then
        return ""
    end

    return (css:gsub('%s*[\r\n]+%s*', ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

function p.render_style(frame)
    local raw_css = frame.args[1]

    if raw_css == nil or raw_css == "" then
        raw_css = frame:getParent().args[1] or ""
    end

    local clean_css = normalize_css(raw_css)

    if clean_css:match("^%s*$") then
        return ""
    end

    local hash_key = "CSS_" .. mw.hash.hashValue("sha1", clean_css)

    local exists = frame:callParserFunction("#varexists", { hash_key })

    if exists == "1" then
        return ""
    end

    frame:callParserFunction("#vardefine", { hash_key, "1" })

    return frame:preprocess("<bstyle>" .. clean_css .. "</bstyle>")
end

return p