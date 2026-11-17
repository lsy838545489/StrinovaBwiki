local util = {}

local setmt = setmetatable

---@alias MetatableIndexFunc fun(t: any, k: any): any
---@alias MetatableIndex table | MetatableIndexFunc


---返回一个新的__index元方法，访问它的键时，将依次以该键访问每个参数，直到找到一个非nil值为止；如果所有fallback都为nil，则访问该键的结果是nil。
---
---示例：
---```
---local tbl = setmetatable({ a = 1 }, merge_indexes(
---   { b = 2 },
---   function (t, k) return k == 'c' and 3 or nil end
---))
---print(tbl.a, tbl.b, tbl.c, tbl.d)
-----> 1, 2, 3, nil
---
---@param ... MetatableIndex 多个fallback，每个fallback的格式与__index元方法一致
---@return MetatableIndex
local function merge_indexes(...)
	local indexes = { ... }
	for i, index in ipairs(indexes) do
		if type(index) == 'table' then
			indexes[i] = function (_, k)
				return index[k]
			end
		end
	end

	return function (t, k)
		for _, index in ipairs(indexes) do
			local v = index(t, k)
			if v ~= nil then return v end
		end
		return nil
	end
end
util.merge_indexes = merge_indexes


---返回一个新表，访问它的键时，将依次以该键访问每个参数，直到找到一个非nil值为止；如果所有fallback都为nil，则访问该键的结果是nil。
---
---示例：
---```
---local tbl = table_with_fallback(
---   { a = 1 },
---   { b = 2 },
---   function (t, k) return k == 'c' and 3 or nil end
---)
---print(tbl.a, tbl.b, tbl.c, tbl.d)
-----> 1, 2, 3, nil
---```
---
---@param ... MetatableIndex 多个fallback，每个fallback的格式与__index元方法一致
---@return table
function util.table_with_fallback(...)
	return setmt({}, { __index = merge_indexes(...) })
end

return util