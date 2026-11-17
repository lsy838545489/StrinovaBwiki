local type = type
local getmt = getmetatable
local setmt = setmetatable
local select = select
local unpack = unpack
local pack = function (...)
	return { n = select('#', ...), ... }
end

local function list_iter(list, last_i)
	local i = last_i + 1
	if i > list.n then return nil end
	return i, list[i]
end

local function list_iter_skip_nil(list, last_i)
	local i = last_i + 1
	if i > list.n then return nil end
	local v = list[i]
	if v == nil then
		return list_iter_skip_nil(list, i)
	end
	return i, v
end

local function iterate_args(...)
	return list_iter, pack(...), 0
end

local function stringify_args(...)
	local unserializable = {
		table = true, ['function'] = true, thread = true, userdata = true,
	}

	local t = {}
	for i, arg in iterate_args(...) do
		t[i] = string.format(unserializable[arg] and '(%s)' or '%q', arg)
	end

	return table.concat(t, ', ')
end

local function do_nothing()
	-- no operations
end

local safe_pairs, safe_ipairs
do
	local return_do_nothing = function () return do_nothing end
	local test_tbl = setmt({}, {
		__ipairs = return_do_nothing,
		__pairs = return_do_nothing,
	})

	local next = next
	if pairs(test_tbl) ~= do_nothing then
		safe_pairs = function (x)
			if type(x) ~= 'table' then return do_nothing end
			return next, x, nil
		end
	else
		safe_pairs = function (x)
			local mt = getmt(x)
			if mt and mt.__pairs then
				return mt.__pairs(x)
			elseif type(x) == 'table' then
				return next, x, nil
			end
			return do_nothing
		end
	end

	local ipairs_iter = ipairs({})
	if ipairs(test_tbl) ~= do_nothing then
		safe_ipairs = function (x)
			if type(x) ~= 'table' then return do_nothing end
			return ipairs_iter, x, 0
		end
	else
		safe_ipairs = function (x)
			local mt = getmt(x)
			if mt and mt.__ipairs then
				return mt.__ipairs(x)
			elseif type(x) == 'table' then
				return ipairs_iter, x, 0
			end
			return do_nothing
		end
	end
end


---@alias IterFunc<CTX, ST, V> fun(ctx: CTX, st: ST): ST | nil, V?

---@generic CTX, ST, V
---@param iter IterFunc<CTX, ST, V>
---@param ctx CTX
---@param st ST
---@return table
local function gether(iter, ctx, st)
	local list = {}
	local n = 0
	for _, v in iter, ctx, st do
		n = n + 1
		list[n] = v
	end
	list.n = n
	return list
end

---@alias FlatMapCtx<P_CTX, P_ST, P_V, C_CTX, C_ST, C_V> {
---   mapper: (fun(x: P_V): IterFunc<C_CTX, C_ST, C_V>, C_CTX, C_ST),
---   p_iter: IterFunc<P_CTX, P_ST, P_V>,
---   p_ctx: P_CTX,
---}

---@alias FlatMapSt<P_ST, P_V, C_CTX, C_ST, C_V> {
---   p_st: P_ST,
---   p_value: P_V?,
---   c_iter: IterFunc<C_CTX, C_ST, C_V>?,
---   c_ctx: C_CTX?,
---   c_st: C_ST?,
---}

---@generic P_CTX, P_ST, P_V, C_CTX, C_ST, C_V
---@type IterFunc<FlatMapCtx<P_CTX, P_ST, P_V, C_CTX, C_ST, C_V>, FlatMapSt<P_ST, P_V, C_CTX, C_ST, C_V>, C_V>
local function flat_map_iter(ctx, st)
	local p_iter, p_ctx = ctx.p_iter, ctx.p_ctx
	local p_st, p_value = st.p_st, st.p_value
	if p_value == nil then
		p_st, p_value = p_iter(p_ctx, p_st)
		if p_st == nil then return nil end
	end

	local c_iter, c_ctx, c_st = st.c_iter, st.c_ctx, st.c_st
	if not c_iter then
		c_iter, c_ctx, c_st = ctx.mapper(p_value)
	end

	local next_c_st, c_value = c_iter(c_ctx, c_st)
	if next_c_st == nil then
		return flat_map_iter(ctx, { p_st = p_st })
	end

	return {
		p_st = p_st,
		p_value = p_value,
		c_iter = c_iter,
		c_ctx = c_ctx,
		c_st = next_c_st,
	}, c_value
end

---@generic P_CTX, P_ST, P_V, C_CTX, C_ST, C_V
---@param mapper (fun(x: P_V): C_V)
---@param iter IterFunc<P_CTX, P_ST, P_V>
---@param ctx P_CTX
---@param st0 P_ST
local function flat_map(mapper, iter, ctx, st0)
	return
		flat_map_iter,
		{ mapper = mapper, p_iter = iter, p_ctx = ctx },
		{ p_st = st0 }
end

---@class (exact) Symbol
---@type Symbol, Symbol, Symbol, Symbol, Symbol, Symbol, Symbol
local PARENT, ENTRY, ITER, CTX, ST0, NEXT = {}, {}, {}, {}, {}, {}

---@class Getter

local Getter_mt  ---@type metatable

---@return Getter
local function Getter(parent, entry, iter, ctx, st0)
	return setmt({
		[PARENT] = parent,
		[ENTRY] = entry,
		[ITER] = iter,
		[CTX] = ctx,
		[ST0] = st0,
	}, Getter_mt)
end


local methods = {}

methods.one = function (self)
	local st, value = self[ITER](self[CTX], self[ST0])
	if st == nil then return nil end
	return value
end

methods.must_one = function (self, message)
	local st, value = self[ITER](self[CTX], self[ST0])
	if st == nil then
		error(message or 'there should be at least one value meeting the query, but nothing found', 2)
	end
	return value
end

local function method_iterate(self)
	return self[ITER], self[CTX], self[ST0]
end
methods.iterate = method_iterate


local function to_generator(iter, ctx, st)
	return function ()
		local value
		st, value = iter(ctx, st)
		if st == nil then return nil end
		return value
	end
end

local function method_generate(self)
	return to_generator(method_iterate(self))
end
methods.generate = method_generate


local List_mt = {
	__index = table,
}
local method_all = function (self)
	return setmt(gether(self[ITER], self[CTX], self[ST0]), List_mt)
end
methods.all = method_all


methods.unpack = function (self)
	return unpack(method_all(self))
end

-- chainable methods:

---@generic CTX, ST, V
---@param f fun(self: Getter, ...): IterFunc<CTX, ST, V>, CTX, ST
local function chainable_method(f)
	local function method(self, ...)
		local iter, ctx, st0 = f(self, ...)
		return Getter(self, method, iter, ctx, st0)
	end
	return method
end

local function field_iter(ctx, st)
	local entry = ctx.entry
	for next_st, node in ctx.p_iter, ctx.p_ctx, st do
		if type(node) == 'table' then
			local value = node[entry]
			if value then
				return next_st, value
			end
		end
	end
	return nil
end

local function method_field(self, key)
	local ctx = { p_iter = self[ITER], p_ctx = self[CTX], entry = key }
	local st0 = self[ST0]
	return Getter(self, key, field_iter, ctx, st0)
end
methods.field = method_field


local function bfs_descendants_iter(root, st)
	if not st then
		return { root }, root
	end

	local unvisited = st
	local visiting_node = unvisited[1]
	if visiting_node == nil then return nil end

	local c_iter, c_ctx, c_st = st.iter, st.ctx, st.st
	if not c_iter then
		c_iter, c_ctx, c_st = safe_pairs(visiting_node)
	end

	local next_c_st, node = c_iter(c_ctx, c_st)  ---@diagnostic disable-line: param-type-mismatch
	if next_c_st == nil then  -- current visiting node is exhausted, visit next unvisited node
		return bfs_descendants_iter(root, { unpack(unvisited, 2) })
	end

	local new_st = {
		iter = c_iter,
		ctx = c_ctx,
		st = next_c_st,
		unpack(unvisited),
	}
	new_st[#new_st+1] = node

	return new_st, node
end

local function iterate_bfs_descendants(value)
	return bfs_descendants_iter, value, nil
end

local method_bfs_descendants = chainable_method(function (self)
	return flat_map(iterate_bfs_descendants, method_iterate(self))
end)
-- no need to be added to `methods`


local function iterate_filtered(predicate, iter, ctx, st0)
	return
		function (ctx, st)
			for new_st, node in iter, ctx, st do
				if predicate(node) then
					return new_st, node
				end
			end
			return nil
		end,
		ctx,
		st0
end

methods.filter = chainable_method(function (self, predicate)
	return iterate_filtered(predicate, method_iterate(self))
end)


local method_items = chainable_method(function (self, filter)
	if not filter then
		return flat_map(safe_ipairs, method_iterate(self))
	end
	return iterate_filtered(filter, flat_map(safe_ipairs, method_iterate(self)))
end)
methods.items = method_items


methods.values = chainable_method(function (self, filter)
	if not filter then
		return flat_map(safe_pairs, method_iterate(self))
	end
	return iterate_filtered(filter, flat_map(safe_pairs, method_iterate(self)))
end)


methods.map = chainable_method(function (self, mapper)
	local p_iter, p_ctx, p_st0 = method_iterate(self)
	return
		function (ctx, st)
			local next_st, value = p_iter(ctx, st)
			if next_st == nil then return nil end
			return next_st, mapper(value)
		end,
		p_ctx,
		p_st0
end)


local keys_to_ignore = {
	[PARENT] = true, [ENTRY] = true, [ITER] = true, [CTX] = true, [ST0] = true, [NEXT] = true,
}
Getter_mt = {
	__index = function (self, key)
		if keys_to_ignore[key] then return nil end
		if key == '_' then
			if self[ENTRY] == method_bfs_descendants then
				error('attempt to retrieve descendants continuously, i.e., `xxx._._`', 2)
			end
			return method_bfs_descendants(self)
		end

		local key_type = type(key)
		if key_type == 'function' then
			return method_items(self, key)
		end
		return method_field(self, key)
	end,
	-- Example:
	-- ```
	-- local books = get(data).books
	-- local items = get(data).books.items
	--
	-- -- case 1: gether values
	-- local case1 = get(data).books.items()  -- is `items()`
	--
	-- -- case 2: call methods
	-- local case2 = get(data).books:items()  -- is `items(books)`
	--
	-- -- case 3: use as an iterator function
	-- for book in get(data).books:items() do
	--    -- this will call `case2(nil, nil)` and `case2(nil, st)`
	-- end
	-- ```
	__call = function (self, ...)
		-- this judgement must take place before `arg_len` check,
		-- as `arg_len` can also be 2 here:
		if ... == self[PARENT] then  -- case 2, `self` is `items` in example
			local method = methods[self[ENTRY]]  -- `self[ENTRY]` is 'items'
			if not method then
				error(("no method named '%s'"):format(self[ENTRY]), 2)
			end
			return method(...)
		end

		local arg_len = select('#', ...)

		if arg_len == 2 then  -- case 3, `self` is `case2` in example
			local _, st = ...
			if st == nil then
				self[NEXT] = method_generate(self)
			end
			return self[NEXT]()
		end

		-- case 1, `self` is `items` in example
		if arg_len ~= 0 then
			error('LuaGet对象函数调用收到了意外的参数：'..stringify_args(...), 2)
		end
		return method_all(self)
	end,
}

local function get(...)
	return Getter('(LuaGet)', get, list_iter_skip_nil, pack(...), 0)
end

return setmt({}, {
	__call = function (_, ...)
		return get(...)
	end,
})