--- Debug utilities.
-- @pragma nostrip

require "gn32/lang"

G.debug = {}

--- Toggle for debug printing. Default false.
debug.global = false

--- Mapping from category to whether debug is enabled for that category.
-- When reading, if a category is not present, the value of `debug.global` is returned.
-- @table debug.enabled
debug.enabled = setmetatable({}, {
	__index = function(_, cat)
		debug.cats[cat] = true
		return debug.global
	end,
	__newindex = function(t, cat, v)
		rawset(t, cat, v)
		debug.cats[cat] = true
	end,
})

--- Table of all categories that have been accessed or set in `debug.enabled`.
-- Accessed categories are mapped to `true`.
-- @table debug.cats
debug.cats = {}


--- Print a message if global debug is enabled.
-- @param ... The args to pass to `print`.
function debug.print(...)
	if debug.global then
		print(...)
	end
end

local dump


local function dump_tkey(ident, id, nlids, gseen)
	if type(ident) == "number" then
		return "[" .. ident .. "]"
	end

	if type(ident) == "string" then
		if string.match(ident, "^%a%w*$") then
			return ident
		end
	end

	return "[" .. dump(ident, id, nlids, gseen) .. "]"
end

dump = function(t, id, nlids, gseen)
	if t == nil then
		return "nil"
	end
	if type(t) == "string" then
		return "\"" .. t .. "\""
	end
	if type(t) == "boolean" then
		if t then return "true"
		else return "false"
		end
	end
	if type(t) == "function" then
		return tostring(t)
	end
	if type(t) ~= "table" then
		return "" .. t
	end

	if gseen[t] then return "..." end
	gseen[t] = true

	local ientries = {}
	local seen = {}
	for k = 1, #t do
		local v = rawget(t, k)
		if v == nil then break end
		table.insert(ientries, dump(v, id, nlids .. id, gseen))
		seen[k] = true
	end

	local entries = {}
	for k, v in next, t do
		if not seen[k] then
			table.insert(entries, dump_tkey(k, id, nlids .. id, gseen) .. "=" .. dump(v, id, nlids .. id, gseen))
		end
	end

	table.sort(entries)
	for _, v in ipairs(entries) do
		table.insert(ientries, v)
	end

	if #ientries == 0 then
		return "{}"
	end
	local comma = ", "
	local trailingComma = ""
	if id ~= "" then
		comma = ","
		trailingComma = ","
	end
	return "{" .. nlids .. id .. table.concat(ientries, comma .. nlids .. id) .. trailingComma .. nlids .. "}"
end

--- Dump a value as a string.
-- @param t The value to dump.
-- @tparam[opt] boolean|string indent
--
-- - `false` or `nil`: Format entire value on a single line.
-- - `true`: Format table values on multiple lines; indent by four spaces per level
-- - ***string***: Format table values on multiple lines; indent by this string for each level.
function debug.dump(t, indent)
	local id, nlids = "", "", ""
	if indent then
		nlids = "\n"
		if type(indent) == "string" then
			id = indent
		else
			id = "    "
		end
	end

	return dump(t, id, nlids, {})
end
