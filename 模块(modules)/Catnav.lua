local p = {}

local MAX_DEPTH = 10

local BAD_PATTERNS = {
        '分类:分类',
        '不可索引',
        '有错误的Scribunto模块',
        '有过多高开销解析器函数调用的页面',
        '有脚本错误的页面',
        '有模板循环的页面',
        '积压工作',
}

local function isBadCategory(title)
        for _, pat in ipairs(BAD_PATTERNS) do
                if mw.ustring.find(title, pat) then
                        return true
                end
        end
        return false
end

-- 从分类页源码中解析父分类
-- =========================
local function getParentCategories(titleObj)
    local content = titleObj and titleObj:getContent()
    if not content then return {} end

    local parents = {}
    for cat in mw.ustring.gmatch(content, '%[%[%s*[^%]]-:%s*([^%]|]+)') do
        local tempTitle = mw.title.new(cat, 14)
        if tempTitle and tempTitle.namespace == 14 then
            local full = tempTitle.fullText
            if not isBadCategory(full) then
                table.insert(parents, tempTitle)
            end
        end
    end
    return parents
end


local function pickParent(titleObj)
        local parents = getParentCategories(titleObj)
        return parents[1]
end


-- 追溯分类路径
-- =========================
local function tracePath(start)
        local path = {}
        local visited = {}
        local current = start
        local depth = 0

        while current and depth < MAX_DEPTH do
                if visited[current.fullText] then
                        break
                end
                visited[current.fullText] = true

                table.insert(path, 1, current.fullText)

                local parent = pickParent(current)
                if not parent then
                        break
                end

                current = parent
                depth = depth + 1
        end

        return path
end

-- 渲染 breadcrumb
-- =========================
local function renderBreadcrumb(path)
        if not path or #path == 0 then
                return ''
        end

        local ol = mw.html.create('ol')
                :addClass('breadcrumb')
                :css({ padding = '8px 15px', margin = '0' })

        for i, full in ipairs(path) do
                local title = mw.title.new(full)
                local li = ol:tag('li'):addClass('breadcrumb-item')

                if i == #path then
                        li:addClass('active')
                          :wikitext('[[:分类:'..title.text..'|'..title.text..']]')
                else
                        li:wikitext('[[:分类:'..title.text..'|'..title.text..']]')
                end
        end

        return tostring(ol)
end

-- 接口
-- =========================
function p.main(frame)
        local title = mw.title.getCurrentTitle()

        if title.namespace ~= 14 then
                return ''
        end

        local path = tracePath(title)
        return renderBreadcrumb(path)
end

return p