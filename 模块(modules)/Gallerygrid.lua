local p = {};
local getArgs = require('Module:Arguments').getArgs;

function p.render(frame)
    -- 解决参数无法传递到模板的问题
    local option = {parent = true}
    local args = getArgs(frame, option);
    local parsedArgs = {}
    local itemArray = {}

    -- 处理编号参数--
    for i, v in ipairs(args) do itemArray[i] = v end

    -- 拼html
    local grid = {
        ["widths"] = args.widths,
        ["heights"] = args.heights,
        ["thumbsize"] = args.thumbsize,
        ["gap"] = args.gap or "1.5rem 1rem",
        ["template"] = args.template or "default",
        ["fit"] = args.fit or "contain",
        ["class"] = args.class or ""
    }
    grid["open"] =
        "<div class='"..grid.class.." gallerygrid' style='display: grid;grid-gap:" .. grid.gap .. ";--gallerygrid-fit:"..grid.fit..";'>";
    grid["close"] = "</div>"

    -- 准备元素
    grid["items"] = "";
    for i, v in ipairs(itemArray) do
        itemArgs = splitArgs(v);
        
        -- 构建传递给子模板的参数表
        local templateArgs = {
            filename = itemArgs[1],
            width = grid.widths,
            height = grid.heights
        }
        
        -- 如果模板不是默认模板，对text参数进行分割并作为匿名参数传递
        if grid.template ~= "default" and (#itemArgs >= 2) then
            -- itemArgs[2] -> anonymous 1 (templateArgs[1])
            for j = 2, #itemArgs do
                templateArgs[j - 1] = itemArgs[j]
            end
        else
            -- 默认模板：保持原有行为，把第二段作为 text
            templateArgs.text = itemArgs[2] or ""
        end

        grid["items"] = grid["items"] .. frame:expandTemplate{
            title = "Gallerygrid/" .. grid.template,
            args = templateArgs
        }
        
    end
    local outputText = grid["open"] .. grid["items"] .. grid["close"]

    -- debug
    local output = ""
    for i, v in ipairs(itemArray) do
        output = output .. i .. "=" .. mw.text.nowiki(v) .. ";<br />"
    end
    return outputText
end

function splitArgs(str)
    local itemArgs = mw.text.split(str, "::", true);
    return itemArgs
end

return p