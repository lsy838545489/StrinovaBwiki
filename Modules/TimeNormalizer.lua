local p = {}

-- 将人类输入格式化为机器时间
function p.format_time(frame)
    local inputTime = frame.args[1] or ""
    inputTime = mw.text.trim(inputTime)
    
    if inputTime == "" then
        return ""
    end
    
    if inputTime == "未知" or inputTime == "常驻" then
        return "2099-12-31 23:59:59"
    end
    
    if inputTime == "失效" then
        return "1999-12-31 23:59:59"
    end
    
    -- 1. 统一替换常用分隔符
    local normalizedTime = inputTime
    normalizedTime = string.gsub(normalizedTime, "年", "-")
    normalizedTime = string.gsub(normalizedTime, "月", "-")
    normalizedTime = string.gsub(normalizedTime, "日", " ")
    normalizedTime = string.gsub(normalizedTime, "/", "-")
    normalizedTime = string.gsub(normalizedTime, "%s+", " ")
    normalizedTime = mw.text.trim(normalizedTime)
    
    -- 2. 正则匹配提取数字并自动补零 (格式：YYYY-MM-DD [HH:MM:SS])
    local y, m, d, h, min, s = string.match(normalizedTime, "^(%d+)%-(%d+)%-(%d+)%s*(%d*):?(%d*):?(%d*)$")
    
    if y and m and d then
        y = tonumber(y)
        m = tonumber(m)
        d = tonumber(d)
        
        -- 如果传入了小时和分钟
        if h ~= "" and min ~= "" then
            h = tonumber(h) or 0
            min = tonumber(min) or 0
            s = (s ~= "" and tonumber(s)) or 0
            return string.format("%04d-%02d-%02d %02d:%02d:%02d", y, m, d, h, min, s)
        else
            -- 仅有年月日
            return string.format("%04d-%02d-%02d", y, m, d)
        end
    end
    
    return normalizedTime
end

-- 将机器时间逆向转换为中文时间
function p.to_chinese_time(frame)
    local inputTime = frame.args[1] or ""
    inputTime = mw.text.trim(inputTime)
        
    if inputTime == "" then return "未知" end
        
    -- 1. 拦截占位符
    if string.find(inputTime, "2099") then return "未知" end
    if string.find(inputTime, "1999") then return "失效" end
        
    local year, month, day, hour, minute
        
    -- 2. ISO 带时间 (如 2023-06-16 23:59:00 / 2023/06/16T23:59)
    year, month, day, hour, minute = string.match(inputTime, "(%d%d%d%d)[%-/](%d%d?)[%-/](%d%d?)[T%s]+(%d%d?):(%d%d?)")
        
    -- 3. 日-月-年 带时间 (如 26 4月 2026 23:59:00)
    if not year then
        day, month, year, hour, minute = string.match(inputTime, "(%d%d?)%s*(%d%d?)月%s*(%d%d%d%d)%s+(%d%d?):(%d%d?)")
    end

    -- 4. 中文年月日 带时间 (如 2023年6月16日 23:59)
    if not year then
        year, month, day, hour, minute = string.match(inputTime, "(%d%d%d%d)年(%d%d?)月(%d%d?)日%s+(%d%d?):(%d%d?)")
    end

    -- 5. 纯 日-月-年 (如 16 6月 2023)
    if not year then
        day, month, year = string.match(inputTime, "(%d%d?)%s*(%d%d?)月%s*(%d%d%d%d)")
    end
        
    -- 6. ISO 纯日期 (如 2023-06-16)
    if not year then
        year, month, day = string.match(inputTime, "(%d%d%d%d)[%-/](%d%d?)[%-/](%d%d?)")
    end

    -- 7. 纯 中文年月日 (如 2023年6月16日)
    if not year then
        year, month, day = string.match(inputTime, "(%d%d%d%d)年(%d%d?)月(%d%d?)日")
    end

    -- 8. 动态判断输出格式
    if year and month and day then
        -- 去除月/日前导零 (如 06月 -> 6月)
        month = tostring(tonumber(month))
        day = tostring(tonumber(day))
        
        -- 判断是否成功捕获到了有效的小时和分钟
        if hour and minute and hour ~= "" and minute ~= "" then
            local h = string.format("%02d", tonumber(hour))
            local m = string.format("%02d", tonumber(minute))
            return string.format("%s年%s月%s日 %s:%s", year, month, day, h, m)
        else
            -- 仅有日期时，只输出 YYYY年M月D日
            return string.format("%s年%s月%s日", year, month, day)
        end
    end
        
    -- 9. 兜底策略：如果正则全部失败，原样返回输入值
    return inputTime
end

return p