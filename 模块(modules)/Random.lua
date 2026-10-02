local module = {}
 
local getArgs = require('Module:Arguments').getArgs
 
function _main(args)
  local upset = 0
  function upsetRandomSeed()
    math.randomseed(tostring(os.time()):reverse():sub(1, 7)..upset..args['upset'])
    upset = upset + 1
  end
 
  upsetRandomSeed()  
  
  local count = tonumber(args['count'] or 1)
  if count < 1 then count = 1 end
  local result = {}
	
  function testRepetition(val)
    for i, v in ipairs(result) do
      if v == val then
        return true
      end
    end
    return false
  end
 
  function getRandomNumber()
    local ran, min, max = 0, 0, 1
    if args[1] == nil then
      return math.random(0, 1), 0, 1
    elseif args[1] == 'raw' then
      ran = math.random()
    else
      if args[2] then
      	min, max = tonumber(args[1]), tonumber(args[2])
      else
        max = tonumber(args[1])
      end
      
      if min > max then min, max = max, min end
      ran = math.random(min, max)
    end
 
    return ran, min, max
  end
  
  repeat
    local ran, min, max = getRandomNumber()
    if testRepetition(ran) == false or args['allowrepeat'] then
      result[#result + 1] = ran 
    end
    
    if args[1] ~= 'raw' and #result >= max - min + 1 then
      for i=#result + 1, count do
        if args[1] == nil then upsetRandomSeed() end
        result[i] = math.random(min, max)
      end
    end
  until(#result >= count)
  
  return table.concat(result, ',')
end
 
function module.main(frame)
  local args = getArgs(frame)
  return _main(args)
end
 
return module