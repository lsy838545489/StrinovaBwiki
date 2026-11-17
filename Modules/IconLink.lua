-- 原地址：https://mzh.moegirl.org.cn/%E6%A8%A1%E5%9D%97:IconLink
-- 请在[[模块:IconLink/data]]添加站点数据
local data = require('Module:IconLink/data')
local sites, domains, idPatterns = data.sites, data.domains, data.idPatterns
 
 
-- 短点方便些
local match = string.match
local format = string.format
 
 
-- 从模块参数分析站点
-- 返回：site表 | nil
local function getSiteFromUrl(url)
	local domainParts = mw.text.split(mw.uri.new(url).host, '%.')
	local curPart = domains
	for i = #domainParts, 1, -1 do
		curPart = curPart[domainParts[i]]
		if not curPart then return nil end
		if type(curPart) == 'string' then return sites[curPart] end
	end
	return nil
end
 
 
-- 根据[[模块:IconLink/data]]的sites表，对指定site和id生成URL
local function makeUrl(site, id)
	local urlType = type(site.url)
	if urlType == 'table' then
		for _, v in ipairs(site.url) do
			if (not v[1]) or match(id, v[1]) then
				return format(v[2], id)
			end
		end
		return false
	end
	if urlType == 'function' then return site.url(id) end
	if urlType == 'string' then return format(site.url, id) end
	error('模块:IconLink/data中，sites表' .. site.name .. '的url填写有误。')
end
 
 
-- 生成最终链接
local function makeIconLink(site, url, title, size)
	-- 错误
	-- * 无url，无site: 未正确填写参数
	-- * 无url，有site: 未填写URL/ID或填写了不受支持的URL/ID
	-- * 有url，无site: 未匹配到支持的网站，不显示网站图标，但不报错
	if not url then
		if site then
			error('URL/ID填写有误')
		else
			error('分析参数失败')
		end
	end
 
	if site then
		if title then
			-- [[File:icon]] [url title]
			return format('[[File:%s|%s|link=|%s]] [%s %s]',
				site.icon.file,
				size or site.icon.size or 'x20px',
				site.name,
				url,
				title
			)
		end
		-- [[File:icon|url]]
		return format('[[File:%s|%s|link=%s|%s]]',
			site.icon.file,
			size or site.icon.size or 'x20px',
			url,
			site.name
		)
	end
	-- [url title]
	if title then return '['..url..' '..title..']' end
	-- [url]
	return '['..url..']'
end
 
 
local p = {}
 
function p.main(args)
	local url = args.link
	local site = (args.site and sites[args.site:lower()]) or (url and getSiteFromUrl(url))
	local title = args.title
 
	for _, arg in ipairs(args) do
		arg = mw.text.trim(arg)
		if not url then -- 默认有url的时候就知晓site和id
			-- 若参数是url
			if match(arg, '^[Hh][Tt][Tt][Pp][Ss]?://') then
				url = arg
				-- 从url获取网站
				if not site then site = getSiteFromUrl(url) end
 
			-- 若参数是site或id
			elseif not site then -- 未知site，尝试从该参数获取site
				site = sites[mw.ustring.lower(arg)]
				if not site then
					for idPattern, siteById in pairs(idPatterns) do -- 遍历idPatterns
						if match(arg, idPattern) then
							site = siteById
							url = makeUrl(site, arg)
							break
						end
					end
				end
				if not site then break end -- 连站点都获取不到，还搞啥，润！
 
			-- site已知晓，该参数是id，从中获取url
			else
				url = makeUrl(site, arg)
			end
		elseif not title then -- url（site、id）已知晓，只缺title
			title = arg
		end
	end
 
	return makeIconLink(site, url, title, args.size)
end
 
 
function p.fromParent(frame)
	return p.main(frame:getParent().args)
end
 
 
function p.wrapper(frame)
	local parent = frame:getParent()
	parent.args.site = frame.args.site
	return p._main(parent.args)
end
 
return p