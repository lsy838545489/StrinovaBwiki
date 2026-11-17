local p = {}

local getArgs = require('模块:Arguments').getArgs

function p._convert(args)
    local input = args[1]
    if not input then
        error('调用模板或模块的参数错误')
    end

    -- 提取月份和日期（支持 "1月8日"、"01月08日"、"0108" 等格式）
    local month, day = input:match("(%d+)月(%d+)日")  -- 匹配 "X月X日" 格式
    if not month then
        -- 如果不是 "X月X日" 格式，尝试直接解析数字（如 0108）
        month, day = input:match("^(%d%d)(%d%d)$")  -- 匹配 0108 格式
        if not month then
            error('输入格式错误，请使用 "1月8日" 或 "0108" 格式')
        end
    end

    month = tonumber(month)
    day = tonumber(day)
    local combined = string.format('%02d%02d', month, day)

    if combined < '0121' then
        return '摩羯座'
    elseif combined < '0220' then
        return '水瓶座'
    elseif combined < '0321' then
        return '双鱼座'
    elseif combined < '0421' then
        return '白羊座'
    elseif combined < '0522' then
        return '金牛座'
    elseif combined < '0622' then
        return '双子座'
    elseif combined < '0723' then
        return '巨蟹座'
    elseif combined < '0823' then
        return '狮子座'
    elseif combined < '0923' then
        return '处女座'
    elseif combined < '1024' then
        return '天秤座'
    elseif combined < '1123' then
        return '天蝎座'
    elseif combined < '1222' then
        return '射手座'
    else
        return '摩羯座'
    end
end

function p.convert(frame)
    local args = getArgs(frame, {wrappers='模板:星座'})
    return p._convert(args)
end

return p