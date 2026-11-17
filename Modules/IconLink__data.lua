-- 一些小函数，可以在sites中使用

local match = string.match
local gsub = string.gsub

-- 删除字符串前的一个'@'
local function removeAt(str)
	return gsub(str, '^@', '', 1)
end


--[[
在这里添加站点。

sites格式：
	<网站英文小写> = {
		name = '<网站名称>',
		icon = {file = '<文件名，最好是svg>' [, size = '<大小，默认是x20px>']},
		url = '<url的format，用%s代替id的位置，用于string.format>'
		或
		url = {
			{'<id的pattern，用于string.match>', '<url的format，用%s代替id的位置，用于string.format>'},
			{同上},
			……
			{'<id的pattern>' 或 nil, '<url的format'}, -- 作为最后一个表时，pattern可以是nil
		}
		或
		url = function(id)，返回url或false（false表示id格式错误）
	}

在这里添加之后，还需要在domains中添加域名。
]]
local sites = {
	acfun = {
		name = 'AcFun',
		icon = {file = 'Acfun_logo2.png'},
		url = {
			{'^ac[%a%d]+$', 'www.acfun.cn/v/%s'},  -- v/ac
			{'^%d+$',       'www.acfun.cn/u/%s'},  -- user
		}
	},
    applemusic = {
		name = 'Apple Muisc',
		icon = {file = 'ApplemusicFavicon.png'},
		url = 'music.apple.com/%s'
	},
	bilibili = {
		name = 'bilibili',
		-- mainpage = 'www.bilibili.com/',
		icon = {file = 'Bilibili_Logo.svg', size = '25px'},
		url = {
			{'^[Bb][Vv][%a%d]+$', 'www.bilibili.com/video/%s'},  -- BV
			{'^av%d+$',           'www.bilibili.com/video/%s'},  -- av
			{'^[cC][vV]%d+$',     'www.bilibili.com/read/%s'},   -- cv
			{'^%d+$',             'space.bilibili.com/%s'},  -- 空间
		}
	},
	instagram = {
		name = 'Instagram',
		icon = {file = 'Instagram Logo.svg', size = '30px'},
		url = 'www.instagram.com/%s'
	},
    music163 = {
		name = '网易云音乐',
		icon = {file = '网易云音乐-logo.png'},
		url = 'music.163.com/%s'
	},
	niconico = {
		name = 'niconico',
		-- mainpage = 'www.nicovideo.jp/',
		icon = {file = 'Niconico_Logo_(2020).svg'},
		url = {
			{'^s[mo]%d+$', 'www.nicovideo.jp/watch/%s'}, -- sm, so
			{'^%d+$',      'www.nicovideo.jp/user/%s'}   -- user
		}
	},
	piapro = {
		name = 'piapro',
		icon = {file = 'Piapro_icon.svg'},
		url = 'piapro.jp/%s'  -- 根据insource搜索，多数使用情况是个人主页而非歌曲页
	},
    qqmusic = {
		name = 'QQ音乐',
		icon = {file = 'Logo_QQMusicIcon_2.png'},
		url = 'y.qq.com/%s'
	},
	twitch = {
		name = 'twitch',
		icon = {file = 'Twitch_icon.svg'},
		url = 'www.twitch.tv/%s'
	},
	pixiv = {
		name = 'pixiv',
		icon = {file = 'Pixiv_Logo.svg', size = '30px'},
		url = 'www.pixiv.net/%s'
	},
	twitter = {
		name = 'Twitter',
		icon = {file = 'Twitter_logo.svg', size = '30px'},
		url = function(id)
			-- username (A-Za-z0-9_)
			if match(id, '^@?[%a%d_]+$') then
				return 'twitter.com/'..removeAt(id)
			end
			-- tweet
			if match(id, '^@?[%a%d_]+%s+%d+$') then
				id = mw.text.split(id, '%s+')
				return 'twitter.com/'..removeAt(id[1])..'/status/'..id[2]
			end
			return false
		end
	},
	weibo = {
		name = '微博',
		icon = {file = 'Weibo_Icon.svg', size = '30px'},
		url = 'weibo.com/%s'
	},
	youtube = {
		name = 'YouTube',
		-- mainpage = 'www.youtube.com/',
		icon = {file = 'YouTube_Logo.png', size = '30px'},
		url = {
			{'^@',             'www.youtube.com/%s'},          -- handle
			{'^UC...........', 'www.youtube.com/channel/%s'},  -- channel
			{nil,              'www.youtube.com/watch?v=%s'},  -- video
			-- 参考资料：webapps.stackexchange.com/questions/54443/format-for-id-of-youtube-video/101153#101153
		}
	},
}

-- 在此处添加别名。为避免别名重复，请按照别名的字母顺序摆列
sites.ac = sites.acfun
sites.bl = sites.bilibili
sites.bili = sites.bilibili
-- sites.fb = sites.facebook
sites.ig = sites.instagram
sites.nc = sites.niconico
sites.nico = sites.niconico
sites.ttv = sites.twitch
sites.tw = sites.twitter
sites.wb = sites.weibo
sites.yt = sites.youtube
sites.ytb = sites.youtube


--[[ domains
格式
	顶级域名 = {
		二级域名 = {
			…… = {
				N级域名 = sites中的key
			}
		},
	},
]]
local domains = {
	cn = {
		acfun = 'acfun',
		weibo = 'weibo',
	},
	com = {
        apple = {
        	music = 'applemusic',
    	},
		bilibili = 'bilibili',
		instagram = 'instagram',
        qq = {
        	y = 'qqmusic',
        },
		twitter = 'twitter',
		weibo = 'weibo',
		youtube = 'youtube',
		['163'] = {
			music = 'music163',
		},
	},
	net = {
		pixiv = 'pixiv',
	},
	jp = {
		nicovideo = 'niconico',
		piapro = 'piapro',
	},
	tv = {
		twitch = 'twitch',
	},
}

-- id patterns，按站点字母顺序
local idPatterns = {
	['^ac%d+$'] = sites.acfun,  -- 无大写
	['^[aCc][Vv]%d+$'] = sites.bilibili,  -- av无大写
	['^[Bb][Vv][%a%d]+$'] = sites.bilibili,
	['^sm%d+$'] = sites.niconico,  -- 无大写
}


return {
	sites = sites,
	domains = domains,
	idPatterns = idPatterns
}