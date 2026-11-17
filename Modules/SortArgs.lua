local module = {}

function module.sortedArgs(args, sort_ref, ref_sep)
	local args_dump = {}
	sort_ref = mw.text.split(sort_ref, ref_sep, false)
	if #sort_ref then table.remove(sort_ref, #sort_ref) end
	for idx, key in ipairs(sort_ref) do
		args_dump[idx] = { key, args[key] or args[tonumber(key)] }
	end
	local index = 0
	return function ()
		index = index + 1
		if not args_dump[index] then
			index = 0
			return nil
		end
		return unpack(args_dump[index])
	end
end

return module