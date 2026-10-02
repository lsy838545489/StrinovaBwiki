local p = {}

local format = string.format

local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

-- ================= 辅助函数 =================
-- 稀有度标签
local function rarity_tag(frame, quality, name)
	return format('<span class="badge rounded-pill" data-quality="%s">%s</span>', quality or 1, name or '')
end

-- 通用卡片样式
local function build_style(frame, name, quality, get, desc, file)
	return "File:" .. file .. "::"
		.. rarity_tag(frame, quality, name) .. "::"
		.. (desc or '') .. "::"
		.. strinova.array_to_ul(get, true)
end

-- 超弦体动作卡片样式
local function build_role_action_style(frame, name, quality, get, desc, file)
	local actionName = rarity_tag(frame, quality, name)
	local info = frame:expandTemplate { 
		title = '弹出面板', 
		args = { actionName, '[[文件:' .. name .. '.gif|class=text-center]]', '动作预览' } 
	}
	return "File:" .. file .. "::"
		.. info .. "::"
		.. (desc or '') .. "::"
		.. strinova.array_to_ul(get)
end

-- 意识重构卡片样式
local function build_lottery_style(frame, file, name, quality)
	local html = file .. "|" .. rarity_tag(frame, quality, name)
	return tostring(html)
end

-- 意识重构专用 CSS 样式
local function get_lottery_css(frame)
	return frame:callParserFunction {
		name = '#css',
		args = { '.gallerytext .badge {font-size: 14px;}' },
	}
end

-- 通用生成 GalleryGrid 参数的函数
-- @param frame: 框架对象
-- @param data: 数据表
-- @param filterStr: 过滤关键词 (可选)
-- @param options: 配置项 (itemType, width, height, fit, filePattern, styleFunc, template, class, isExact)
local function generate_gallery_args(frame, data, filterStr, options)
	options = options or {}
	local itemType = options.itemType
	-- 如果没有配置 isExact，则默认采用局部匹配（false）
	local isExact = (options.isExact ~= nil) and options.isExact or false

	local args = {
		template = options.template or 'PlayerDecoration',
		class = options.class or 'player-decoration',
		widths = options.widths or nil,
		heights = options.heights or nil,
		gap = '16px',
	}

	-- 构建反向索引匹配 Set（如果有筛选词）
	local idSet = nil
	if filterStr and filterStr ~= "" and itemType then
		local targetIds = get_ways_module.getIdsByWay(itemType, filterStr, isExact)
		if #targetIds == 0 then
			return nil -- 代表筛选无匹配项
		end
		idSet = {}
		for _, id in ipairs(targetIds) do
			idSet[id] = true
		end
	end

	-- 提取并按 ID 排序，保证遍历输出顺序稳定
	local sortedList = {}
	for _, items in pairs(data) do
		if not idSet or (items.id and idSet[items.id]) then
			table.insert(sortedList, items)
		end
	end

	if #sortedList == 0 then
		return nil
	end

	table.sort(sortedList, function(a, b)
		return (a.id or 0) < (b.id or 0)
	end)

	-- 默认为标准样式构建函数
	local styleFunc = options.styleFunc or build_style

	for _, items in ipairs(sortedList) do
		-- 动态获取途径数据（实现机器数据与手写途径解耦）
		local getWays = items.get
		if itemType and items.id then
			getWays = get_ways_module.getWays(itemType, items.id)
		end

		-- 处理文件名：优先使用传入的 filePattern 格式化，否则使用 items.file
		local file = items.file
		if options.filePattern and items.id then
			file = format(options.filePattern, items.id)
		end

		local entry = styleFunc(frame, items.name, items.quality, getWays, items.desc, file)
		table.insert(args, entry)
	end

	return args
end


-- ================= 主要展示页面函数 =================

p["封装"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/FrameData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'Frame',
		heights = '250px',
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["基板页面"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/IDCardData")
	local args = generate_gallery_args(frame, data, frame.args[1], {
		itemType = 'IDCard',
	})
	if not args then return "暂无符合该获得途径的基板" end
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["喷漆页面"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/DecalData")
	local args = generate_gallery_args(frame, data, frame.args[1], {
		itemType = 'Decal',
		filePattern = '喷漆_%d.png',
	})
	if not args then return "暂无符合该获得途径的喷漆" end
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["勋章页面"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/BadgeData")
	local args = generate_gallery_args(frame, data, frame.args[1], {
		itemType = 'Badge',
		filePattern = '勋章_%d.png',
	})
	if not args then return "暂无符合该获得途径的勋章" end
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["聊天气泡"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/ChatBubblesData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'ChatBubbles',
		filePattern = '聊天气泡_%d.png',
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["头套"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/MascotHeadData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'MascotHead',
		filePattern = '头套_%d.png',
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["超弦体动作"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/RoleActionData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'RoleAction',
		template = 'RoleAction',
		filePattern = '超弦体动作图标_%d.png',
		styleFunc = build_role_action_style,
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["房间外观"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/ChangeBgData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'ChangeBg',
		template = 'ChangeBg',
		filePattern = '房间外观_%d',
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["休息室手办"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/GarageKitsData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'GarageKits',
		filePattern = '道具图标_%d.png',
		heights = '200px',
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

p["个性名片"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/ProfileCardData")
	local args = generate_gallery_args(frame, data, nil, {
		itemType = 'ProfileCard',
		filePattern = '个性名片_%d.png',
		heights = '240px',
	})
	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

-- ================= 大图子页面函数 =================
p["基板大图"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/IDCardData")
	local filter = frame.args[1]
	local targetIds = get_ways_module.getIdsByWay("IDCard", filter, false)

	if #targetIds == 0 then return "暂无符合该获得途径的基板" end

	local idSet = {}
	for _, id in ipairs(targetIds) do idSet[id] = true end

	local resultList = {}
	for _, items in pairs(data) do
		if items.id and idSet[items.id] then
			local html = format("%s|'''<big>%s</big>'''", items.img or items.file, items.name)
			table.insert(resultList, html)
		end
	end

	if #resultList == 0 then return "暂无符合该获得途径的基板" end

	return frame:preprocess('<gallery mode="nolines" widths=140px heights=340px>\n' .. table.concat(resultList, "\n") .. '\n</gallery>')
end

p["喷漆大图"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/DecalData")
	local filter = frame.args[1]
	local targetIds = get_ways_module.getIdsByWay("Decal", filter, false)

	if #targetIds == 0 then return "暂无符合该获得途径的喷漆" end

	local idSet = {}
	for _, id in ipairs(targetIds) do idSet[id] = true end

	local resultList = {}
	for _, items in pairs(data) do
		if items.id and idSet[items.id] then
			local file = format('喷漆_L_%d.png', items.id)
			local html = format("%s|'''<big>%s</big>'''", file, items.name)
			table.insert(resultList, html)
		end
	end

	if #resultList == 0 then return "暂无符合该获得途径的喷漆" end

	return frame:preprocess('<gallery mode="nolines" widths=200px heights=200px>\n' .. table.concat(resultList, "\n") .. '\n</gallery>')
end


-- ================= 意识重构专用函数 =================
p["意识重构基板"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/IDCardData")
	local get = frame.args[1]
	local targetIds = get_ways_module.getIdsByWay("IDCard", get, false)

	if #targetIds == 0 then return "暂无符合该获得途径的基板" end

	local idSet = {}
	for _, id in ipairs(targetIds) do idSet[id] = true end

	local resultList = {}
	for _, items in pairs(data) do
		if items.id and idSet[items.id] then
			local html = build_lottery_style(frame, items.file, items.name, items.quality)
			table.insert(resultList, html)
		end
	end

	if #resultList == 0 then return "暂无符合该获得途径的基板" end

	local css = get_lottery_css(frame)
	return css .. frame:preprocess('<gallery mode="packed">\n' .. table.concat(resultList, "\n") .. '\n</gallery>')
end

p["意识重构喷漆"] = function (frame)
	local data = mw.loadData("模块:玩家装饰/DecalData")
	local get = frame.args[1]
	local targetIds = get_ways_module.getIdsByWay("Decal", get, false)

	if #targetIds == 0 then return "暂无符合该获得途径的喷漆" end
	
	local idSet = {}
	for _, id in ipairs(targetIds) do idSet[id] = true end

	local resultList = {}
	for _, items in pairs(data) do
		if items.id and idSet[items.id] then 
			local file = format('喷漆_%d.png', items.id)
			local html = build_lottery_style(frame, file, items.name, items.quality)
			table.insert(resultList, html)
		end
	end
	
	if #resultList == 0 then return "暂无符合该获得途径的喷漆" end
	
	local css = get_lottery_css(frame)
	return css .. frame:preprocess('<gallery mode="packed">\n' .. table.concat(resultList, "\n") .. '\n</gallery>')
end

return p