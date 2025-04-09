--- Utility for weak tables of possibly-ECS entities.
-- @alias G

require "gn32/lang"

local isEntity
if G.createEntity then
	isEntity = function(e) return type(e) == "userdata" and tostring(e):match("^entity:") end
else
	isEntity = function(e) return type(e) == "table" and type(rawget(e, "__ptr")) == "userdata" and e.isValid end
end

local weaktable_data = setmetatable({}, {__mode="k"})

local function weaktable_next(wt, key)
	local data = weaktable_data[wt]
	if not data then
		error("bad weaktable reference", 2)
	end

	local k, v = key, nil
	while true do
		k, v = next(data.table, k)
		if k == nil then
			return
		end
		if data.keys and isEntity(k) and not k:isValid() then
			data.table[k] = nil
		elseif data.values and isEntity(v) and not v:isValid() then
			data.table[k] = nil
		else
			return k, v
		end
	end
end

local weaktable_mt = {
	__metatable = "weaktable",
	__index = function(wt, key)
		local data = weaktable_data[wt]
		if not data then
			error("bad weaktable reference", 2)
		end

		if data.keys and isEntity(key) and not key:isValid() then
			data.table[key] = nil
			return nil
		end

		local value = data.table[key]

		if data.values and isEntity(value) and not value:isValid() then
			data.table[key] = nil
			return nil
		end

		return value
	end,
	__newindex = function(wt, key, value)
		local data = weaktable_data[wt]
		if not data then
			error("bad weaktable reference", 2)
		end

		if data.keys and isEntity(key) and not key:isValid() then
			data.table[key] = nil
			return
		end
		if data.values and isEntity(value) and not value:isValid() then
			data.table[key] = nil
			return
		end

		data.table[key] = value
	end,
	__pairs = function(wt)
		return weaktable_next, wt, nil
	end,
}

--- Make a new weak entity table.
-- A weak entity table can have weak keys, weak values, or both.
--
-- Any operation performed on a weak entity table using a destroyed entity as a weak key or weak value will remove the
-- relevant key from the table, as if by `tbl[key] = nil`. If the operation is a read operation, the entry will either
-- be skipped or the read will return `nil`, depending on the operation.
--
-- Destroyed entities used as non-weak keys or non-weak values do not trigger this behaviour, and may be used as usual.
--
-- Tables or full userdata used as weak keys or weak values will behave as described in
-- [the Lua docs on weak tables](https://www.lua.org/manual/5.4/manual.html#2.5.4) by default; on non-ECS builds this
-- allows some of the table maintenance work to be performed by Lua's garbage collector. If necessary, this behaviour
-- can be overridden by specifying a different mode string as a second parameter (`lua_mode`).
--
-- @tparam string mode The mode for the table; one of `"k"`, `"v"`, or `"kv"`. If the string contains `k`, the keys of the table are weak; if it contains `v`, the values are weak.
-- @tparam[opt=mode] string lua_mode The mode to set in the Lua metatable.
-- @treturn table A new weak table with the requested characteristics.
function G.newWeakEntityTable(mode, lua_mode)
	local wt = setmetatable({}, weaktable_mt)
	weaktable_data[wt] = {
		table = setmetatable({}, {__mode=lua_mode or mode}),
		keys = mode:find("k") ~= nil,
		values = mode:find("v") ~= nil,
	}
	return wt
end
