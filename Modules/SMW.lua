-- 功能 1. 查询页面指定属性 2.设置smw属性  3.将模板所有参数设置为smw属性，支持序号参数用双冒号分割键值如 射速::360rpm
-- 参考了 https://rimworld.huijiwiki.com/wiki/模块:SMW , 其作者是 Lu 、 Duduluu
-- 由于bwiki没有Semantic Scribunto插件，重构了查询逻辑。
local p = {}

local getArgs = require('Module:Arguments').getArgs

function p.ask(frame)
    local args = getArgs(frame)
    local query = args.query or args[1]  -- 获取查询语句，可以通过 `query` 参数或第一个无名参数传入
    if not query then
        return "模块:SMW ask 需要一个查询语句"
    end
    
    local options = {}
    for k, v in pairs(args) do
        if k ~= "query" and k ~= "1" then
            table.insert(options, k .. "=" .. v)
        end
    end
    
    local result = frame:callParserFunction{
        name = "#ask:" .. query,
        args = options
    }
    
    return result or "(no results)"
end

-- 用于查询一个值
function p.show(frame)
    -- local queryResult = mw.smw.ask("[[" .. page .. "]]|?" .. prop .. "|mainlabel=-|headers=hide")
    if not (frame.args[1] and frame.args[2]) then
    	return "模块:SMW show 需要参数1和2"
    end
    if frame.args[1] == '' or frame.args[2] == '' then
    	return "模块:SMW show 需要非空参数1和2"
    end

	local result = frame:callParserFunction{name="#ask:[[" .. frame.args[1] .. "]]", args={
		"?".. frame.args[2],
		mainlabel="-",
		headers="hide"
	}}

	if result and result ~= '' then
		return result
    elseif frame.args[3] then
        return frame.args[3]
    else
        return ''
    end
end

-- 用于设置一些smw属性，在模板页面，也同时包括所有模板属性
function p.set(frame)
  local args = getArgs(frame)
  local properties = {}
  for k, v in pairs(args) do
    if k and v then
      properties[k] = v
    end
  end
  -- mw.smw.set(properties)
  -- frame:callParserFunction( '#set', properties)
  local firstK, firstV = next(properties)
  if firstK and firstV then
    frame:callParserFunction('#set:'.. firstK ..'=' .. firstV,  properties)
  end
end

-- 用于设置模板中的所有参数作为smw属性。无需填写参数，直接在模板用调用即可
function p.setAllArgs(frame)
  local args = getArgs(frame)
  local properties = {}
  for k, v in pairs(args) do
  	-- 支持以双冒号分割键值。
    if type(k) == 'number' then
      local splitValues = mw.text.split(v, "::")
      if #splitValues == 2 then
        properties[splitValues[1]] = splitValues[2]
      else
      	error("使用模块 SMW 的 setAllArgs 时，应当保证在参数的值中只有一个分隔符“::”，如“射速::360rpm”，但有参数为："..v)
      end
    else
      properties[k] = v
    end
  end
  
  -- mw.smw.set(properties) -- 如果支持 Semantic Scribunto，可以使用这一行
  local firstK, firstV = next(properties)
  if firstK and firstV then
    frame:callParserFunction('#set:'.. firstK ..'=' .. firstV,  properties)
  end
end

return p