local p = {}
local format = string.format

local QualityNameToNum = {
    ["初始"] = 0,
    ["优秀"] = 1,
    ["精致"] = 2,
    ["卓越"] = 3,
    ["完美"] = 4,
    ["传说"] = 5,
    ["私服"] = 6,
    ["臻藏"] = 8,
}

-- 统一分类名称
local ERROR_CATEGORY = "[[分类:图标模块调用错误的页面]]"

-- ================= 辅助函数 =================
-- 统一错误处理函数
local function format_error(msg)
    return format('<span class="error">%s</span>%s', msg, ERROR_CATEGORY)
end

-- 通用函数：处理道具图标样式 HTML 生成
local function icon_style(prefix, itemName, itemFile, itemQuality, size, imgSize, count)
    local html = mw.html.create()

    local iconHTML = html
        :tag('span'):addClass('item-icon'):addClass('item-icon--quality-'..itemQuality)
        :tag('span')
        :addClass('item-icon__img')
        :attr('data-count', (count and count ~= "") and count or nil)
        :wikitext(format('[[文件:%s|%s|class=radius10|link=]]', itemFile, imgSize))
        :done()
        :tag('span')
        :addClass('item-icon__text')
        :attr('data-type', (prefix and prefix ~= "") and prefix or nil)
        :css("font-size", size)
        :wikitext(itemName)
        :done()
        :done()
    return tostring(iconHTML)
end

-- 通用函数：在数据表中查找道具
local function find_item_in_data(data, itemName)
    for _, item in pairs(data) do
        if item.name == itemName then
            return item
        end
    end
    return nil
end

-- 通用处理逻辑：用于处理大部分结构相同的道具
local function generic_item_handler(itemName, size, imgSize, dataPath, prefix, filePattern, idField, itemCount)
    local data = mw.loadData(dataPath)
    local item = find_item_in_data(data, itemName)

    if item then
        local fileName = item.file
        if filePattern then
            local id = item[idField or 'id']
            fileName = format(filePattern, id)
        end

        return icon_style(prefix, item.name, fileName, item.quality, size, imgSize, itemCount)
    else
        return format_error("名称错误或无数据")
    end
end

-- ================= 主要逻辑 =================
function p.main(frame)
    local args = frame.args
    local itemType = args["type"] or ""
    local itemCount = args["count"] or ""
    local typeName = args["typeName"] or ""
    local itemName = args[1] or ""
    local roleName = args["role"]
    local size = args["size"]
    local imgSize = args["imgSize"]

    local itemFunctions = {
        ["时装"] = p["角色时装"],
        ["外观"] = p["武器外观"],
        ["礼物"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:角色礼物/Data", "礼物") end,
        ["喷漆"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/DecalData", "喷漆", "喷漆_%d.png") end,
        ["喷漆移动端"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰移动端/DecalData", "喷漆", "喷漆移动端_%d.png") end,
        ["基板"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/IDCardData", "基板") end,
        ["封装"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/FrameData", "封装") end,
        ["勋章"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/BadgeData", "勋章", "勋章_%d.png") end,
        ["勋章移动端"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰移动端/BadgeData", "勋章", "勋章移动端_%d.png") end,
        ["表情"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:角色表情/Data", "表情") end,
        ["语音"] = p["语音"],
        ["动作"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/RoleActionData", "超弦体动作",
                "超弦体动作图标_%d.png") end,
        ["登场特效"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/LoginFXData", "登场特效",
                "登场特效图标_%d.png") end,
        ["气泡"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/ChatBubblesData", "聊天气泡", "聊天气泡_%d.png") end,
        ["手办"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/GarageKitsData", "休息室手办", "道具图标_%d.png") end,
        ["头套"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰/MascotHeadData", "头套", "头套_%d.png") end,
        ["卡牌"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:生化卡牌/Data", "卡牌", "生化卡牌_%d.png", "cardid") end,
        ["互动"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:功能道具/InteractivePropsData", "互动道具", "互动道具_%d.png", nil, itemCount) end,
        ["头像框移动端"] = function (n, s, i) return generic_item_handler(n, s, i, "模块:玩家装饰移动端/HeadFrameData", "头像框", "头像框移动端_%d.png") end,
        [""] = p["功能道具"],
    }

    if itemFunctions[itemType] then
        return itemFunctions[itemType](itemName, size, imgSize, roleName, itemCount)
    else
        return p["其它"](itemName, args["file"], args["quality"], size, imgSize, itemCount, typeName)
    end
end

-- ================= 特殊处理函数 =================

p["角色时装"] = function (itemName, size, imgSize, roleName)
    local data = mw.loadData("模块:角色/SkinData")

    local function find_skin(rName)
        local roleData = data[rName]
        if roleData and roleData[itemName] then
            local roleSkin = roleData[itemName]
            return icon_style(
                "角色时装",
                itemName,
                "角色时装图鉴_"..roleSkin.id..".png",
                roleSkin.quality,
                size,
                imgSize
            )
        end
        return nil
    end

    if roleName and roleName ~= "" then
        local result = find_skin(roleName)
        if result then return result end
    else
        for rName, _ in pairs(data) do
            local result = find_skin(rName)
            if result then return result end
        end
    end

    return format_error("时装名称错误或无数据")
end

p["武器外观"] = function (itemName, size, imgSize)
    local skinData = mw.loadData("模块:武器/SkinData")

    local parts = mw.text.split(itemName, "-")
    if #parts < 2 then return format_error("格式错误 (应为 武器-皮肤)") end

    local weaponName = parts[1]
    local skinName = parts[2]

    local function get_skin_info(database)
        if database[weaponName] and database[weaponName][skinName] then
            return database[weaponName][skinName]
        end
        return nil
    end

    local targetSkin = get_skin_info(skinData)

    if targetSkin then
        return icon_style(
            "武器外观",
            weaponName.."-"..skinName,
            "武器外观图鉴_"..targetSkin.id..".png",
            targetSkin.quality,
            size,
            imgSize
        )
    else
        return format_error("外观名称错误或无数据")
    end
end

p["语音"] = function (itemName, size, imgSize)
    local idMap = {
        ['米雪儿·李'] = 22101001,
        ['米雪儿'] = 22101001,
        ['信'] = 22108001,
        ['心夏'] = 22124001,
        ['伊薇特'] = 22131001,
        ['芙拉薇娅'] = 22115001,
        ['忧雾'] = 22121001,
        ['蕾欧娜'] = 22123001,
        ['千代'] = 22125001,
        ['明'] = 22132001,
        ['拉薇'] = 22128001,
        ['梅瑞狄斯'] = 22133001,
        ['令'] = 22109001,
        ['香奈美'] = 22137001,
        ['艾卡'] = 22119001,
        ['珐格兰丝'] = 22120001,
        ['玛拉'] = 22122001,
        ['奥黛丽·格罗夫'] = 22105001,
        ['奥黛丽'] = 22105001,
        ['玛德蕾娜·利里'] = 22107001,
        ['玛德蕾娜'] = 22107001,
        ['绯莎'] = 22112001,
        ['星绘'] = 22146001,
        ['白墨'] = 22110001,
        ['加拉蒂亚·利里'] = 22205001,
        ['加拉蒂亚'] = 22205001,
    }

    local voiceID = idMap[itemName]
    if voiceID then
        local voiceFile = format('道具图标_%d.png', voiceID)
        return icon_style("语音", itemName.."语音", voiceFile, 2, size, imgSize)
    else
        return format_error("语音角色名称错误")
    end
end

p["功能道具"] = function (itemName, size, imgSize, roleName, count)
    local data = mw.loadData("模块:功能道具/Data")
    local mobileData = mw.loadData("模块:功能道具/MobileData")

    local targetItem = find_item_in_data(data, itemName) or find_item_in_data(mobileData, itemName)

    if targetItem then
        return icon_style("", targetItem.name, targetItem.file, targetItem.quality, size, imgSize, count)
    else
        return format_error("名称错误或无数据")
    end
end

p["其它"] = function (Name, File, Quality, size, imgSize, count, typeName)
    local qualityNum = QualityNameToNum[Quality] or 0
    return icon_style(typeName, Name, File, qualityNum, size, imgSize, count)
end

return p