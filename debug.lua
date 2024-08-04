-- Module: gn32/debug
-- Description: debug utilities

require "gn32/lang"

G.debug = {
	global = false,
	enabled = setmetatable({}, {
		__index = function(_, cat)
			debug.cats[cat] = true
			return debug.global
		end,
	}),
	cats = {},
}

function debug.print(...)
	if debug.global then
		print(...)
	end
end

function debug.dump(t, nl, id, ids, gseen)
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

	if nl == true then
		nl = "\n"
		id = "    "
		ids = ""
	elseif nl == nil then
		nl = ""
		id = ""
		ids = ""
	end
	if id == nil then id = "" end
	if ids == nil then ids = "" end

	if gseen == nil then gseen = {} end
	if gseen[t] then return "..." end
	gseen[t] = true

	local ientries = {}
	local seen = {}
	for k = 1, #t do
		local v = rawget(t, k)
		if v == nil then break end
		table.insert(ientries, debug.dump(v, nl, id, ids .. id, gseen))
		seen[k] = true
	end

	local entries = {}
	for k, v in next, t do
		if not seen[k] then
			table.insert(entries, "[" .. debug.dump(k, nl, id, ids .. id, gseen) .. "]=" .. debug.dump(v, nl, id, ids .. id, gseen))
		end
	end

	table.sort(entries)
	for _, v in ipairs(entries) do
		table.insert(ientries, v)
	end

	if #ientries == 0 then
		return "{}"
	end
	return "{" .. nl .. ids .. id .. table.concat(ientries, "," .. nl .. ids .. id) .. nl .. ids .. "}"
end
