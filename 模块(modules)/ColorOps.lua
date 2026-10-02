--原模块:https://mzh.moegirl.org.cn/Module:ColorOps
local module = {}
 
local getArgs = require('Module:Arguments').getArgs
local Color = require('Module:color')
 
function _main(args)
  local action = args[1]
  local arg1 = args[2]
  local arg2 = args[3]
  local arg3 = args[4]
  
  if action == 'reverse' then
    local color = arg1
 
    return Color.create(color):reverse():toString('hex')
  end
 
  if action == 'random' then
    local min = arg1 or 0
    local max = arg2 or 255
 
    return Color.random(min, max):toString('hex')
  end
  
  if action == 'opacity' then
    local color = arg1
    local opacity = arg2
 
  	return Color.create(color):setOpacity(opacity):toString()
  end
 
  if action == 'isLight' then
    local color = arg1
    return Color.create(color):isLight() and 1 or ''
  end
 
  if action == 'isDark' then
    local color = arg1
    return Color.create(color):isDark() and 1 or ''
  end
 
  if action == 'mix' then
    local color1 = Color.create(arg1)
    local color2 = Color.create(arg2)
    local weight = arg3
 
    return color1:mix(color2, weight):rgb():toString('hex-opacity')
  end
 
    -- 映射要使用的每组操作颜色属性的方法
    local methods = {
      saturation = {'saturate', 'desaturate'},
      lightness = {'lighten', 'darken'},
      default = {'darken', 'lighten'}	-- 历史遗留原因，默认是加深、减淡
    }
 
  if action:find('^test:[ls]?') then
    function block(text, color)
      return '<ruby style="color:'..color..'">■<rt style="color:black">'..text..'<rt></ruby>&nbsp;'
    end
    
    local property = ({
        s = 'saturation',
        l = 'lightness'
    })[action:sub(#action, #action)] or 'default'
    local usedMethods = methods[property]
    
    local color = Color.create(arg1)
	  local left = ''
	  local right = ''
	  for i=1, 9 do
	    i = i * 10
	    local clonedColor1 = color:clone()
	    local clonedColor2 = color:clone()
	    
	    left = block('-'..i, Color[usedMethods[2]](clonedColor1, i):toString())..left
	    right = right..block('+'..i, Color[usedMethods[1]](clonedColor2, i):toString())
	  end
	  return '<div style="font-size:30px">'..left..block('▼', color:toString())..right..'</div>'
	end
 
  if action:find('^[sl]?[%+%-]') then
    local color = Color.create(arg1)
    local operateProperty = 'default'
    local operator = ''
    local ratio = 0
 
    if action:find('^[sl]') then 
      operateProperty = ({
        s = 'saturation',
        l = 'lightness'
      })[action:sub(1, 1)]
 
      operator = action:sub(2, 2)
      ratio = tonumber(action:sub(3)) or 10
    else
      operator = action:sub(1, 1)
      ratio = tonumber(action:sub(2)) or 10
    end
    
    local usedMethods = methods[operateProperty]
    local usedMethod = operator == '+' and usedMethods[1] or usedMethods[2]
    
    return Color[usedMethod](color, ratio):toString('hex')
  end
end
 
function module.main(frame)
	local args = getArgs(frame)
	return _main(args)
end
 
return module