local p = {}
local format = string.format
local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

-- 辅助函数：生成稀有度 HTML 标签
local function rarity_tag(frame, quality, name)
	local rarityTag = format('<span class="badge rounded-pill" data-quality="%s">%s</span>', quality, name)
	return rarityTag
end

-- 辅助函数：构建标准装饰品的参数字符串
local function build_style(frame, name, quality, get, desc, file)
	return "File:"..file.."::"
		..rarity_tag(frame, quality, name).."::"
		..desc.."::"
		..strinova.array_to_ul(get)
end

-- 辅助函数：构建载具外观的参数字符串（包含特殊描述）
local function vehicle_skin_style(frame, name, quality, get, spdesc, desc, file)
	return "File:"..file.."::"..rarity_tag(frame, quality, name).."::"
		..desc.."::"
		..spdesc.."::"
		..strinova.array_to_ul(get)
end

-- 通用生成函数：用于处理结构相同的图库
local function generate_standard_gallery(frame, dataPath, filePrefix, itemsType)
	local data = mw.loadData(dataPath)
	local args = {
		template = 'PlayerDecoration',  -- 调用的模板
		class = 'player-decoration',
		gap = '16px',
	}

	for _, items in ipairs(data) do
		-- 自动拼接文件名
		local file = format('%s_%s.png', filePrefix, items.id)
		local getWays = get_ways_module.getWays(itemsType, items.id)
		local entry = build_style(frame, items.name, items.quality, getWays, items.desc, file)
		table.insert(args, entry)
	end

	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

-- ================= 导出函数 =================

p["喷漆移动端"] = function (frame)
	return generate_standard_gallery(frame, "模块:玩家装饰移动端/DecalData", "喷漆移动端", "DecalMobile")
end

p["喷漆大图移动端"] = function (frame)
	local data = mw.loadData("模块:玩家装饰移动端/DecalData")
	local resultList = {}

	for _, items in pairs(data) do
		local file = format('喷漆移动端_L_%d.png', items.id)
		local html = format("%s|'''<big>%s</big>'''", file, items.name)
		table.insert(resultList, html)
	end
	local result = table.concat(resultList, "\n")
	return frame:preprocess('<gallery mode="nolines" widths=200px heights=200px>\n'..result..'\n</gallery>')
end

p["勋章移动端"] = function (frame)
	return generate_standard_gallery(frame, "模块:玩家装饰移动端/BadgeData", "勋章移动端", "BadgeMobile")
end

p["头像框移动端"] = function (frame)
	return generate_standard_gallery(frame, "模块:玩家装饰移动端/HeadFrameData", "头像框移动端", "HeadFrameMobile")
end

p["聊天气泡移动端"] = function (frame)
	return generate_standard_gallery(frame, "模块:玩家装饰移动端/ChatBubblesData", "聊天气泡移动端", "ChatBubblesMobile")
end

p["载具外观移动端"] = function (frame)
	local data = mw.loadData("模块:玩家装饰移动端/VehicleSkinData")
	local args = {
		template = 'VehicleSkin',
		class = 'vehicle-skin',
		gap = '1.5rem 3rem',
		widths = '300px',
		heights = '200px',
	}

	for _, items in ipairs(data) do
		local file = format('载具外观_%s.png', items.id)
		local getWays = get_ways_module.getWays("VehicleSkinMobile", items.id)
		local entry = vehicle_skin_style(frame, items.name, items.quality, getWays, items.spdesc, items.desc, file)
		table.insert(args, entry)
	end

	return frame:expandTemplate { title = 'gallerygrid', args = args }
end


p["按键外观移动端"] = function (frame)
	return generate_standard_gallery(frame, "模块:玩家装饰移动端/HudSkinData", "按键外观移动端", "HudSkinMobile")
end

return p