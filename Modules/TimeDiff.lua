-- 模块:TimeDiff —— 计算两个日期时间的差值
-- 用法：{{#invoke:TimeDiff|main|起始|结束|format=text|tz=8|abs=0|unit=|decimals=2}}
--       {{#invoke:TimeDiff|status|起始|结束|before=|during=|after=}}
-- 支持：2026-11-18 / 2026-11-18 12:30 / 2026年11月18日 12:30 / 2026/11/18 / 2026.11.18 / now
-- 时区默认 +8（北京时间），可写 tz=8 或 tz=5.5，也可在日期串里写 UTC+8 / +08:00

local p = {}

local SEC_MIN, SEC_HOUR, SEC_DAY = 60, 3600, 86400

local function err(msg)
	return '<span class="error">TimeDiff：' .. tostring(msg) .. '</span>'
end

-- 公历年月日 -> 距 1970-01-01 的天数（Howard Hinnant civil_from_days 算法）
local function daysFromCivil(y, m, d)
	if m <= 2 then y = y - 1 end
	local era = math.floor(y / 400)
	local yoe = y - era * 400
	local mp = (m + 9) % 12
	local doy = math.floor((153 * mp + 2) / 5) + d - 1
	local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end

-- 解析日期字符串 -> UTC 时间戳（秒）；失败返回 nil, 错误信息
local function parseDate(raw, tz)
	if raw == nil then return nil, '缺少日期参数' end
	local s = mw.text.trim(raw)
	if s == '' or s == 'now' or s == '现在' or s == '今天' then
		return os.time()
	end

	s = s:gsub('　', ' ')

	-- 日期串里自带的时区优先于 tz 参数
	local u = s:match('[Uu][Tt][Cc]%s*([%+%-]?[%d%.]+)')
	if u then
		tz = tonumber(u) or tz
		s = s:gsub('[Uu][Tt][Cc]%s*[%+%-]?[%d%.]+', ' ')
	end
	local oh, om = s:match('([%+%-]%d%d):(%d%d)%s*$')
	if oh then
		local sign = oh:sub(1, 1) == '-' and -1 or 1
		tz = sign * (tonumber(oh:sub(2)) + tonumber(om) / 60)
		s = s:gsub('([%+%-]%d%d):(%d%d)%s*$', ' ')
	end

	-- 归一化中文分隔符
	-- 注意：Lua 字符类 [日号] 按字节匹配，会切坏「护」等多字节字的字节，必须逐个替换
	s = s:gsub('年', '-'):gsub('月', '-'):gsub('日', ' '):gsub('号', ' ')
	s = s:gsub('时', ':'):gsub('分', '')
	s = s:gsub('/', '-'):gsub('%.', '-')
	s = mw.text.trim(s)

	local y, mo, d, rest = s:match('^(%d%d%d%d)%-(%d%d?)%-(%d%d?)(.*)$')
	if not y then
		-- 省略年份时按当年处理
		local m2, d2, r2 = s:match('^(%d%d?)%-(%d%d?)(.*)$')
		if m2 then
			y, mo, d, rest = os.date('!%Y'), m2, d2, r2
		end
	end
	if not y then
		return nil, '无法识别的日期「' .. raw .. '」'
	end

	y, mo, d = tonumber(y), tonumber(mo), tonumber(d)
	if y < 1 or y > 9999 then return nil, '年份超出范围：' .. y end
	if mo < 1 or mo > 12 then return nil, '月份不合法：' .. mo end
	if d < 1 or d > 31 then return nil, '日期不合法：' .. d end

	local h, mi, se = 0, 0, 0
	local tail = rest or ''
	local hh, mm, ss = tail:match('(%d%d?):(%d%d):?(%d?%d?)')
	if hh then
		h, mi, se = tonumber(hh), tonumber(mm), tonumber(ss) or 0
	else
		hh = tail:match('(%d%d?)%s*$')
		if hh then h = tonumber(hh) end
	end
	if h > 23 then return nil, '小时不合法：' .. tostring(h) end
	if mi > 59 or se > 59 then return nil, '分钟/秒不合法：' .. tail end

	return daysFromCivil(y, mo, d) * SEC_DAY + h * SEC_HOUR + mi * SEC_MIN + se - tz * SEC_HOUR
end

-- 秒数 -> 「X天X小时X分」
local function human(sec)
	local neg = sec < 0
	sec = math.floor(math.abs(sec))
	local d = math.floor(sec / SEC_DAY)
	local h = math.floor(sec % SEC_DAY / SEC_HOUR)
	local m = math.floor(sec % SEC_HOUR / SEC_MIN)
	local out = {}
	if d > 0 then out[#out + 1] = d .. '天' end
	if h > 0 then out[#out + 1] = h .. '小时' end
	if m > 0 or #out == 0 then out[#out + 1] = m .. '分' end
	return (neg and '-' or '') .. table.concat(out)
end

function p.main(frame)
	local args = frame.args
	local tz = tonumber(args.tz) or 8
	local a = args[1] or args.a or args.start
	local b = args[2] or args.b or args['end'] or 'now'

	local ea, e1 = parseDate(a, tz)
	if not ea then return err(e1) end
	local eb, e2 = parseDate(b, tz)
	if not eb then return err(e2) end

	local diff = eb - ea
	if args.abs == '1' or args.abs == 'yes' then diff = math.abs(diff) end

	local fmt = mw.text.trim(tostring(args.format or 'text'))
	local unit = args.unit or ''

	if fmt == 'seconds' or fmt == 'sec' or fmt == 's' then
		return string.format('%d', math.floor(diff + (diff >= 0 and 0.5 or -0.5))) .. unit
	elseif fmt == 'minutes' or fmt == 'min' then
		return string.format('%.1f', diff / SEC_MIN) .. unit
	elseif fmt == 'hours' or fmt == 'hour' or fmt == 'h' then
		return string.format('%.1f', diff / SEC_HOUR) .. unit
	elseif fmt == 'days' or fmt == 'day' or fmt == 'd' then
		local dec = tonumber(args.decimals) or 2
		if dec < 0 then dec = 0 elseif dec > 6 then dec = 6 end
		return string.format('%.' .. dec .. 'f', diff / SEC_DAY) .. unit
	end
	return human(diff) .. unit
end

-- 按当前时间判断区间状态
function p.status(frame)
	local args = frame.args
	local tz = tonumber(args.tz) or 8
	local a = args[1] or args.start
	local b = args[2] or args['end']

	local s, e1 = parseDate(a, tz)
	if not s then return err(e1) end

	local e
	if b and mw.text.trim(tostring(b)) ~= '' then
		local e2
		e, e2 = parseDate(b, tz)
		if not e then return err(e2) end
	end

	local now = os.time()
	if now < s then return args.before or '未开始' end
	if e and now > e then return args.after or '已结束' end
	return args.during or '进行中'
end

return p