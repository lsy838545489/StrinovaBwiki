local getArgs = require('Module:Arguments').getArgs

local p = {}

function p.main(frame)
    local args = getArgs(frame, {
        removeBlanks = false,
        trim = false
    }) -- 保留空格和换行
    return p._main(args)
end

function p._main(args)
    local buffer = {'{|'} -- 表格开头的{|

    for k, v in pairs(args) do
        -- 没记错的话Lua输入命名参数后是没法按照顺序呈现的，因此需要通过遍历查找命名参数，即表格第一行<table>中的class等内容
        if type(k) ~= 'number' then
            --[=[ 
                表格第一行，此时直接读入的参数不包括等号前面的内容，
                例如class="wikitable"只会读入一个键为class、值为"wikitable"的参数，需要手动将前面的class=加上去。
            ]=]
            table.insert(buffer, string.format(' %s=%s', k, v))
        end
    end
    table.insert(buffer, '\n')

    for _, v in ipairs(args) do
        table.insert(buffer, '|')
        table.insert(buffer, v)
    end

    -- 补上结尾的|}，然后将表串起来并返回
    table.insert(buffer, '\n|}')
    return table.concat(buffer)
end

return p;