local p = {}

local format = string.format
local data = mw.loadData("模块:超弦推进卡牌/Data")

local function build_style(file, name, category, desc, role, quality)
	return "文件:"..file..
		"::"..name..
		"::"..category..
		"::".."\n"..desc..
		"::"..role..
		"::"..quality
end

local function concat_proxied_table(t, sep)
	local buf = {}
	for i, v in ipairs(t) do
		buf[i] = v
	end
	return table.concat(buf, sep)
end

p["超弦推进卡牌筛选"] = function (frame)
	local args = {
		id = 'CardSelectGallery',
		template = 'EscortCard',
		widths = '190px',
		gap = '16px',
		fit = 'contain',
	}

	for _, items in pairs(data) do
		local file = format('超弦推进卡牌_%s.png', items.icon)
		local unlockRoles = items.unlockRoles and concat_proxied_table(items.unlockRoles, "、") or ""
		local entry = build_style(file, items.name, items.category, items.desc, unlockRoles, items.quality)
		table.insert(args, entry)
	end

	return frame:expandTemplate { title = 'gallerygrid', args = args }
end

return p