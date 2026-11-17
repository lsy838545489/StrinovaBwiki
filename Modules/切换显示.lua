local module = {}

local getArgs = require('Module:Arguments').getArgs
local sortedArgs = require('Module:SortArgs').sortedArgs

local initSpan = function(className, templateName, frame)
	local args = getArgs(frame, { wrappers = 'Template:' .. templateName })

	local span = mw.html.create('span')
	span:attr('class', className)

	if className == 'textToggleDisplayButtons' then -- 自Template:切换显示调用。
		local operators = {} -- 操作参数。
		local contentlist = {} --[[内容表列。结构为：
												{
													strcode = 字符串代号,
													on = @on后缀的内容,
													off = @off后缀的内容,
													default = 没有@on或@off后缀的内容,
												}
											]]
		for k, v in sortedArgs(args, frame.args['@sort'], '|') do
			mw.log(k, v)
			if mw.ustring.sub(k, 1, 1) == '@' then
				operators[k] = v
			else
				local strcode
				local onoff = nil
				-- 获取字符串代号和开关类型。
				if mw.ustring.sub(k, -3) == '@on' then
					strcode = mw.ustring.sub(k, 1, mw.ustring.len(k) - 3)
					onoff = 'on'
				elseif mw.ustring.sub(k, -4) == '@off' then
					strcode = mw.ustring.sub(k, 1, mw.ustring.len(k) - 4)
					onoff = 'off'
				else
					strcode = k
				end
				onoff = onoff or 'default' -- 没有开关类型就是默认值。

				if not contentlist[strcode] then
					table.insert(contentlist, {strcode = strcode}) -- 增加空的内容表。
					contentlist[strcode] = #contentlist -- 定位新增加的索引，绑定到参数k。
				end
				contentlist[contentlist[strcode]][onoff] = v -- 替换内容。
			end
		end

		local counter = 0 -- 计数器。
		for k_operators, v_operators in pairs(operators) do
			span:attr('data-key-' .. counter, k_operators):attr('data-value-' .. counter, v_operators)
			counter = counter + 1
		end

		for index, content in ipairs(contentlist) do
			span:tag('span'):attr('data-order', index - 1):attr('data-key', content.strcode):tag('span'):addClass(
				'textToggleDisplayButtonLabelText on'
			):wikitext(frame:preprocess(content.on or content.default)):done():tag('span'):addClass(
				'textToggleDisplayButtonLabelText off'
			):wikitext(frame:preprocess(content.off or content.default))
		end
	else
		local counter = 0 -- 计数器
		for k, v in pairs(args) do
			if v ~= nil then
				span:attr('data-key-' .. counter, k):attr('data-value-' .. counter, v)
				counter = counter + 1
			end
		end
	end

	return tostring(span)
end

function module.template(frame)
	local args = getArgs(frame, { wrappers = 'Template:切换显示/模板' })

	local tTitle = args['@'] or ''
	if tTitle == '' then
		return nil
	end
	local tag = args['@tag']

	local branches = {}
	local params = {}
	for k, v in sortedArgs(args, frame.args['@sort'], '|') do
		if not mw.ustring.match(k, '^@[^@]') then
			local i = 1
			while true do
				local _, j, flag = mw.ustring.find(k, '@(.)', i)
				if j == nil then
					i = mw.ustring.len(k)
					break
				elseif flag == '@' then
					i = j + 1
				else
					i = j - 2
					break
				end
			end

			local param = mw.text.trim(mw.ustring.gsub(mw.ustring.sub(k, 1, i), '@@', '@'))
			local branch = mw.ustring.sub(k, i + 2)
			if mw.text.trim(param) ~= '' then
				if params[param] == nil then
					params[param] = {}
				end
				if branch ~= '' and branches[branch] == nil then
					branches[branch] = #branches + 1
					table.insert(branches, branch)
				end
				if branch == '' then
					params[param][0] = v
				else
					params[param][branch] = v
				end
			end
		end
	end

	local result = {}
	for _, branch in ipairs(branches) do
		if type(branch) == 'string' then
			local tArgs = {}
			for param, bValue in pairs(params) do
				tArgs[param] = bValue[branch] or bValue[0]
			end

			table.insert(
				result,
				frame:expandTemplate {
					title = '切换显示',
					args = {
						[1] = branch,
						[2] = frame:expandTemplate {title = tTitle, args = tArgs},
						[3] = tag
					}
				}
			)
		end
	end

	return table.concat(result)
end

function module.button(frame)
	return initSpan('textToggleDisplayButtons', '切换显示按钮', frame)
end

function module.style(frame)
	return initSpan('textToggleDisplayStyle', '切换显示样式', frame)
end

function module.buttonStyle(frame)
	return initSpan('textToggleDisplayButtonsStyle', '切换显示按钮样式', frame)
end

return module