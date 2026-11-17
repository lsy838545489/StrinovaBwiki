local p = {}

-- 缓存
local dataCache = {}

-- 允许的字符：大小写字母、数字、汉字、下划线、斜杠（子页面）
local function isValidModuleName(s)
    return s and type(s) == "string" and s:match("^[%w_/\128-\255]+$") ~= nil
end

-- 根据ID查找获得方式函数
function p.getWays(itemType, itemId)
    if not isValidModuleName(itemType) then
        return { "物品类型参数不合法" }
    end
    if itemId == nil then
        return { "物品ID不能为空" }
    end

    local cached = dataCache[itemType]
    if cached == nil then
        local moduleName = "模块:获得方式/" .. itemType
        local success, data = pcall(mw.loadData, moduleName)
        if not success then
            mw.log("加载模块失败: " .. moduleName .. ", 错误: " .. tostring(data))
            dataCache[itemType] = false 
            return { "获取途径类型错误或未建表" }
        elseif type(data) ~= "table" then
            mw.log("模块返回非表格数据: " .. moduleName)
            dataCache[itemType] = false
            return { "数据格式错误" }
        else
            dataCache[itemType] = data 
        end
    end

    local data = dataCache[itemType]
    if data == false then
        return { "获取途径类型错误或未建表" }
    end

    local numericId = tonumber(itemId)
    
    if not numericId then
        return { "物品ID格式不合法，无法转换为数值" }
    end

    return data[numericId] or { "暂无获取途径" }
end


-- 根据获得方式查找ID函数
function p.getIdsByWay(itemType, keyword, isExact)
    if not keyword or keyword == "" then return {} end
    
    -- 默认值设置：如果不传 isExact，则默认为 true（全匹配）
    if isExact == nil then
        isExact = true
    end

    local moduleName = "模块:获得方式/" .. itemType
    local success, wayData = pcall(mw.loadData, moduleName)
    if not success or type(wayData) ~= "table" then return {} end

    local matchedIds = {}

    for id, wayVal in pairs(wayData) do
        local wayList = nil

        -- 适配新格式：{ get = {...}, remark = ... }
        if type(wayVal) == "table" and type(wayVal.get) == "table" then
            wayList = wayVal.get
        -- 适配旧格式（数组）
        elseif type(wayVal) == "table" then
            wayList = wayVal
        -- 适配旧格式（单字符串）
        elseif type(wayVal) == "string" then
            wayList = { wayVal }
        end

        if wayList then
            for _, wayStr in ipairs(wayList) do
                if type(wayStr) == "string" then
                    local isMatched = false

                    if isExact then
                        -- 全字段精确匹配
                        isMatched = (wayStr == keyword)
                    else
                        -- 局部模糊匹配（包含关键词）
                        -- plain 设为 true 禁用正则元字符转义，进行纯文本查找
                        isMatched = (string.find(wayStr, keyword, 1, true) ~= nil)
                    end

                    if isMatched then
                        table.insert(matchedIds, id)
                        break
                    end
                end
            end
        end
    end

    return matchedIds
end


return p