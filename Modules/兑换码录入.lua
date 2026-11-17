local p = {}

function p.main(frame)
    -- 获取传入的奖励字符串
    local rewardString = frame.args[1] or ""
    
    if rewardString == "" then 
        return "" 
    end
    
    -- 第一层切割：处理中文逗号或英文逗号，并去除多余空格
    local rewardItems = mw.text.split(rewardString, '[,，]%s*')
    -- 提取图片大小参数，如果未提供则默认 60px
    local itemImgSize = frame.args[2] or "60px"
    
    -- 情况一：如果没有逗号分割（只有一个道具）
    if #rewardItems == 1 then
        local itemParts = mw.text.split(rewardItems[1], '%*')
        local itemName = mw.text.trim(itemParts[1] or "")
        local itemQuantity = mw.text.trim(itemParts[2] or "1")
        
        -- 直接返回展开的模板，不嵌套列表
        return frame:expandTemplate{
            title = '道具图标',
            args = {
                itemName,
                ['数量'] = itemQuantity,
                ['imgsize'] = itemImgSize
            }
        }
    end
    
    -- 情况二：有逗号分割（存在多个道具），创建原生的 HTML ul 列表
    local resultHtml = mw.html.create('ul')
    
    for _, item in ipairs(rewardItems) do
        if item ~= "" then
            local itemParts = mw.text.split(item, '%*')
            local itemName = mw.text.trim(itemParts[1] or "")
            local itemQuantity = mw.text.trim(itemParts[2] or "1")
            
            -- 调用 {{道具图标}} 模板
            local templateResult = frame:expandTemplate{
                title = '道具图标',
                args = {
                    itemName,
                    ['数量'] = itemQuantity,
                    ['imgsize'] = itemImgSize
                }
            }
            
            -- 将生成的模板内容包裹在 li 中追加到 ul
            resultHtml:tag('li')
                :wikitext(templateResult)
                :done()
        end
    end
    
    return tostring(resultHtml)
end

return p