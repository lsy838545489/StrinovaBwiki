local getArgs = require("Module:Arguments").getArgs
local p = {}

function p.main(frame)
    local args = getArgs(frame, {
        removeBlanks = false
    })
    local noJP = false
    local buffer = {}
    local tableClass = ""
    local cntdstyle = 'style="background-color: rgba(230,230,230,.5)"'
    local jptdstyle = 'style="background-color: rgba(235,248,255,.5)"'

    -- 遍历检查noJP等参数
    for k, _ in pairs(args) do
        if (k == "noJP") then
            noJP = true
            tableClass = " nojp"
        end
    end

    table.insert(buffer, '{| class="klbqtable voice-table' .. tableClass .. '"')
    local i = 0
    -- 遍历其他数字参数，生成表格
    for key, value in ipairs(args) do
        i = i + 1
        local AudioPlayer = (value == '' and '' or '<div style="display: none">[[媒体文件:' .. value .. ']]</div><div class="media-audio" data-file="{{filepath: ' .. value .. ' | nowiki }}" data-panel="" data-button="" data-progress="" data-dot="" data-bar="" data-mini="true" data-preload="none"></div>')
        if noJP then
            -- 当提供noJP参数时，每三个参数形成一组行和单元格
            if (i % 3 == 1) then
                table.insert(buffer, "|-")
                table.insert(buffer, "! rowspan=1 |" .. value)
            elseif (i % 3 == 2) then
                table.insert(buffer, "| " .. cntdstyle .. "|" .. AudioPlayer)
            elseif (i % 3 == 0) then
                table.insert(buffer, "| " .. cntdstyle .. "|" .. value)
            end
        else
            -- 默认情况，每五个参数形成一组行和单元格
            if (i % 5 == 1) then
                table.insert(buffer, "|-")
                table.insert(buffer, "! rowspan=2 |" .. value)
            elseif (i % 5 == 2) then
                table.insert(buffer, "| " .. cntdstyle .. "|" .. AudioPlayer)
            elseif (i % 5 == 3) then
                table.insert(buffer, "| " .. cntdstyle .. "|" .. value)
            elseif (i % 5 == 4) then
                table.insert(buffer, "|-")
                table.insert(buffer, "| " .. jptdstyle .. "|" .. AudioPlayer)
            elseif (i % 5 == 0) then
            	table.insert(buffer, "| " .. jptdstyle .. "|" .. (value == "" and "" or '<span lang="ja">' .. value .. "</span>"))
            end
        end
    end
    table.insert(buffer, "|}")
    return table.concat(buffer, "\n")
end

return p