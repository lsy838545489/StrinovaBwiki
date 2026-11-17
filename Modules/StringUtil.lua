local util = {}

local select = select  -- 转为upvalue

local ESC_LBRACE = '\254\255LBRACE\255\254'  -- 转义“{”
local ESC_RBRACE = '\254\255RBRACE\255\254'  -- 转义“}”

---@param template string
---@param replacer TemplateReplacer
---@param on_missing? OnMissingParam
---@return string
local function format_template(template, replacer, on_missing)
	local get_replacement = type(replacer) == 'function' and replacer or function (key) return replacer[key] end
	local get_fallback = type(on_missing) == 'function' and on_missing or function () return on_missing end

	local function replace_placeholder(placeholder)
		return placeholder:gsub('^.%s*(.-)%s*.$', function (key)
			local replacement = get_replacement(key)
			if replacement ~= nil then return replacement end

			---@diagnostic disable-next-line: cast-local-type
			replacement = get_fallback(key)
			if replacement ~= nil then return replacement end

			error('模板字符串：缺失对'..placeholder..'的替换值', 6)
		end)
	end

	return (template
		:gsub('{{', ESC_LBRACE)  -- 处理“{{”转义
		:gsub('}}', ESC_RBRACE)  -- 处理“}}”转义
		:gsub('%b{}', replace_placeholder)
		:gsub(ESC_LBRACE, '{')
		:gsub(ESC_RBRACE, '}'))
end

---@alias TemplateReplacer
---| { [string]: string | number | false | nil }
---| fun(key: string): string | number | false | nil

---@alias OnMissingParam string | number | (fun(key: string): string | number | false)

---@alias TemplateFormatter fun(replacer: TemplateReplacer, on_missing?: OnMissingParam): string

---模板字符串替换，将`template`中的“{key}”替换为`replacer[key]`或`replacer(key)`的值。
---
---要在`template`表示字符“{”和“}”本身，请用“{{”和“}}”代替。
---
---示例：
---```
---fmt('Hello, {name}!', { name = 'Lua' }) --> 'Hello, Lua!'
---fmt('Hello, {name}!', function (key)
---   if key == 'name' then
---       return 'Lua'
---   end
---end)  --> 'Hello, Lua!'
---fmt('Hello, {{name}}', { name = 'Lua' })  --> 'Hello, {name}!'，因为“{{”和“}}”是“{”和“}”的转义
---fmt('Hello, {name}', { name = false })  --> 'Hello, {name}!'，因为false代表不替换
---```
---
---`on_missing`示例：
---```
---fmt('Hello, {name}!', { name = nil }, 'Unknown')  --> 'Hello, Unknown!'
---fmt('Hello, {name}!', { name = nil }, function (key)
---   return '<'..key..'>'
---end)  --> 'Hello, <name>!'
---```
---
---不传入`replacer`和`on_missing`时返回一个formatter，使用方法如下：
---```
---local format = fmt('Hello, {name}!')  -- 等价于Formatter('Hello, {name}!')
---format({ name = 'Lua' })  --> 'Hello, Lua!'
---```
---这是为了以下语法糖而设计的：
---```
---fmt 'Hello, {name}!' { name = 'Lua' }  --> 'Hello, Lua!'
---```
---
---@param template string
---@param replacer TemplateReplacer 替换器，用法同string.gsub的第二个参数。未传入时则返回一个formatter函数，用法见同模块的Formatter
---@param on_missing? OnMissingParam 当replacer输出nil时触发on_missing：若on_missing是字符串或数字，则用该值替换{key}；若on_missing是函数，则用on_missing(key)替换{key}；若未传入on_missing，则抛出错误
---@return string | TemplateFormatter
---@overload fun(template: string): TemplateFormatter
function util.fmt(template, replacer, on_missing)
	if replacer == nil then
		if on_missing ~= nil then
			error('string interpolation: missing replacer', 2)
		end
		return util.Formatter(template)
	end
	return format_template(template, replacer, on_missing)
end

---返回一个`format(replacer[, on_missing])`函数（参数同`fmt`的后两个参数）。
---
---示例：
---```
---local format = Formatter('Hello, {name}!')
---format({ name = 'Lua' })  --> 'Hello, Lua!'
---```
---
---可以提供一个`on_missing`，并且可以在每次调用`format`时覆盖：
---```
---local format = Formatter('Hello, {name}!', 'Missing')
---format({ name = nil })  --> 'Hello, Missing!'
---format({ name = nil }, 'Unknown')  --> 'Hello, Unknown!'
---```
---
---@param template string
---@param on_missing? OnMissingParam
---@return TemplateFormatter
function util.Formatter(template, on_missing)
	return function (replacer, ...)
		if select('#', ...) > 0 then
			return format_template(template, replacer, ...)
		end
		return format_template(template, replacer, on_missing)
	end
end

return util