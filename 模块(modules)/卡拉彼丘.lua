local p = {}


--道具稀有度名称表
p.qualityNumToName = {
	[0] = "初始",
	[1] = "优秀",
	[2] = "精致",
	[3] = "卓越",
	[4] = "完美",
	[5] = "传说",
	[6] = "私服",
	[8] = "臻藏",
}

--道具稀有度颜色表
p.qualityNameToColor = {
	["初始"] = "#ECECEC",
	["优秀"] = "#ECECEC",
	["精致"] = "#60A3F7",
	["卓越"] = "#F285FF",
	["完美"] = "#FFC555",
	["传说"] = "#F85555",
	["私服"] = "#F78653",
	["臻藏"] = "#F78653",
}
p.qualityToColor = {
	[0] = "#ECECEC",
	[1] = "#ECECEC",
	[2] = "#60A3F7",
	[3] = "#F285FF",
	[4] = "#FFC555",
	[5] = "#F85555",
	[6] = "#F78653",
	[8] = "#F78653",
}


--获取页面标题函数
function p.get_page_title(args)
	local title = mw.title.getCurrentTitle()
	local mode = args['mode']

    -- up：一路爬到根页面
    -- down：当前页面的最末级
    -- 默认：完整页面名（不含命名空间）
    if mode == "up" then
        while title.basePageTitle
          and title.basePageTitle.fullText ~= title.fullText
        do
            title = title.basePageTitle
        end
        return title.title.basePageTitle
    elseif mode == "down" then
    	return title.subpageText
    else
    	return title.fullText
    end
end


--稀有度标签函数
function p.rarity_tag(frame, quality)
	return frame:expandTemplate { title = '稀有度标签', args = { quality } }
end


--通用函数：检查数组（或字符串）中是否存在包含指定子串的元素
-- @param haystack table|string 要搜索的数组或单字符串
-- @param needle string 要查找的子串
-- @return boolean 是否匹配成功
function p.has_sub_string(haystack, needle)
	if not needle or needle == "" then
		return true
	end
	if type(haystack) == "table" then
		for _, item in ipairs(haystack) do
			if type(item) == "string" and string.find(item, needle, 1, true) then
				return true
			end
		end
		return false
	end
	if type(haystack) == "string" then
		return string.find(haystack, needle, 1, true) ~= nil
	end
	return false
end


--通用函数：对数组内容格式化为无序列表
-- @param items table|string 要格式化的数组或单字符串
function p.array_to_ul(items)
	if not items or items == "" then
		return ""
	end

	-- 创建一个 <ul> 节点
	local ul = mw.html.create('ul')

	-- 处理单字符串的情况
	if type(items) == "string" then
		-- 使用 :wikitext() 确保内容里的 [[内部链接]] 依然能被正确解析
		ul:tag('li'):wikitext(tostring(items))
		return tostring(ul)
	end

	-- 处理表（数组）的情况
	if type(items) == "table" then
		if items[1] == nil then
			return ""
		end

		for _, item in ipairs(items) do
			ul:tag('li'):wikitext(tostring(item))
		end
		
		return tostring(ul)
	end

	return ""
end


return p