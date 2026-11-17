local p = {}

function p.main(frame)
	local args = require('Module:Arguments').getArgs(frame)
	local titleArgKey = 'TemplateAsyncLoadTitle'
	local title = args[titleArgKey]
	local titleObj

	-- 标题检查
	assert(title, '未输入标题参数')
	titleObj = mw.title.new(title, 'Template')
	assert(titleObj, '无效标题')
	assert(not titleObj.isExternal and titleObj.namespace == 10, '仅可输入模板标题')
	assert(titleObj.exists, '模板不存在')
	-- 标题规范化
	title = titleObj.fullText

	--处理传入参数
	local count = 1
	local data = {}
	for key, value in pairs(args) do
		if key ~= titleArgKey then
			table.insert(data, string.format('data-key-%d="%s"', count, key))
			table.insert(data, string.format('data-value-%d="%s"', count, value))
			count = count + 1
		end
	end

	return '<div class="TemplateAsyncLoad" style="text-align:center" data-title="' .. title .. '" ' .. table.concat(data, ' ') .. '>加载中……</div>'
end

return p