local p = {}

local format = string.format
local stringUtil = require("Module:StringUtil")
local strinova = require("模块:卡拉彼丘")
local get_ways_module = require("模块:获得方式")

--道具ID范围表
local ItemsTypeRanges = {
    { min = 1,    max = 99,   type = "货币"    },
    { min = 101,  max = 999,  type = "超弦体"  },
    { min = 10201,  max = 10399,  type = "消耗品"  },
    { min = 10401,  max = 10499,  type = "特别行动加速卡"  },
    { min = 10501,  max = 10599,  type = "排位赛消耗品"  },
    { min = 10601,  max = 10699,  type = "商城优惠券"  },
    { min = 10801,  max = 10899,  type = "特别行动升级卡"  },
    { min = 20001,  max = 20999,  type = "礼盒礼包"  },
    { min = 21001,  max = 24999,  type = "盲盒礼包"  },
    { min = 25001,  max = 25999,  type = "礼盒礼包"  },
    { min = 26001,  max = 26999,  type = "挑战赛宝箱"  },
    { min = 27001,  max = 27999,  type = "超弦体体验卡"  },
    { min = 28001,  max = 28099,  type = "卡牌包"  },
    { min = 29001,  max = 29099,  type = "消耗品12"  },
    { min = 31001,  max = 31999,  type = "礼盒"  },
    { min = 40001,  max = 40999,  type = "抽奖道具"  },
    { min = 50001,  max = 50999,  type = "活动代币"  },
    { min = 70001,  max = 79999,  type = "宿舍手办"  },
    { min = 80001,  max = 89999,  type = "卡牌"  },
    { min = 90001,  max = 91000,  type = "头套"  },
    { min = 93001,  max = 93999,  type = "房间外观"  },
    { min = 110100,  max = 199999,  type = "超弦体体验卡"  },
    { min = 200001,  max = 299999,  type = "战令商城礼盒"  },
    { min = 300001,  max = 399999,  type = "限时商城定向匣"  },
    { min = 400001,  max = 499999,  type = "通用道具"  },
    { min = 500001,  max = 599999,  type = "定制外观"  },
    { min = 600001,  max = 610000,  type = "终结特效"  },
    { min = 700001,  max = 700999,  type = "兑换物"  },
    { min = 802001,  max = 802999,  type = "晶源感染模式卡组"  },
    { min = 3010001, max = 3019999, type = "头像"  },
    { min = 3020001, max = 3029999, type = "头像框"  },
    { min = 10100001, max = 19999999, type = "武器外观"  },
    { min = 20101001, max = 20999999, type = "超弦体时装"  },
    { min = 21101001, max = 21999999, type = "超弦体动作"  },
    { min = 22101001, max = 19999999, type = "超弦体语音"  },
    { min = 30000001, max = 30999999, type = "喷漆"  },
    { min = 31000001, max = 31999999, type = "基板"  },
    { min = 32000001, max = 32999999, type = "封装"  },
    { min = 33000001, max = 33999999, type = "勋章"  },
    { min = 60000001, max = 60999999, type = "表情"  },
    { min = 61000001, max = 61999999, type = "互动道具"  },
    { min = 70000001, max = 70999999, type = "聊天气泡"  },
    { min = 101000010,  max = 199999999,  type = "武器外观体验卡"  },
    { min = 201010010,  max = 209999999,  type = "超弦体外观体验卡"  },
    -- 按需继续添加区间（保持升序且不重叠）
}


p["互动道具"] = function (frame)
	local propsData = mw.loadData("模块:功能道具/InteractivePropsData")
	local formatter = stringUtil.Formatter [=[
|-
| class="text-center"|[[文件:{file}|100px]]<br>'''{name}'''
| {稀有度标签}
| {desc}
| {get}
]=]

    local result = {}

    for _, items in pairs(propsData) do
    	local getInfo = get_ways_module.getWays("InteractiveProps", items.id)
        table.insert(result, formatter({
        	file = format("互动道具_%d.png", items.id),
        	name = items.name,
            ['稀有度标签'] = strinova.rarity_tag(frame, items.quality),
            get = strinova.array_to_ul(getInfo, true),
            desc = items.desc,
            }, ''))
    end

    return table.concat(result)
end


-- 内部：确保 ranges 按 min 升序并返回排序后的引用
local function ensure_sorted(ranges)
    table.sort(ranges, function(a, b) return a.min < b.min end)
    return ranges
end

-- 内部二分查找，返回 type 或 nil（需要 ranges 已排序且不重叠）
local function binary_search(ranges, id)
    local lo, hi = 1, #ranges
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local r = ranges[mid]
        if id < r.min then
            hi = mid - 1
        elseif id > r.max then
            lo = mid + 1
        else
            return r.type
        end
    end
    return nil
end

-- 获取道具类型函数
function p.items_type(id)
    local n = tonumber(id)
    if not n then return nil end
    ensure_sorted(ItemsTypeRanges)
    return binary_search(ItemsTypeRanges, n)
end

p["道具筛选"] = function (frame)
    local data = mw.loadData("模块:功能道具/Data")
    local result = {}
    
    for _, item in pairs(data) do
        local itemType = p.items_type(item.id) or ""
        
        -- 直接展开画廊卡片模板，将参数传入
        local cardHtml = frame:expandTemplate{
            title = "Gallerygrid/Items",
            args = {
                itemType = itemType,
                quality = item.quality,
                file = item.file,
                name = item.name,
                desc = item.desc or ""
            }
        }
        table.insert(result, cardHtml)
    end
    
    -- 外层包裹 gallerygrid 网格容器
    return '<div class="gallerygrid">' .. table.concat(result) .. '</div>'
end


return p