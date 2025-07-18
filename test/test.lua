require "gn32/lang-strict"
G.traceback = debug.traceback
local lua_debug = debug
require "gn32/test/min-ee"
require "gn32/debug"

G.testcode = 0

G.printed = {}
G.testPrint = print
function print(...)
	table.insert(printed, {...})
end
function G.consumePrinted()
	local p = printed
	printed = {}
	return p
end

function G.test(name, f)
	local ok, err = pcall(f)

	local output = consumePrinted()
	if #output > 0 then
		testPrint(name .. " ...")
		for _, line in ipairs(output) do
			testPrint(table.unpack(line))
		end
	end

	if ok and err == "SKIP" then
		testPrint(name .. " SKIP")
	elseif ok then
		testPrint(name .. " OK")
	else
		if err == nil then err = "<nil>" end
		testPrint(name .. " FAIL " .. tostring(err))
		testcode = 1
	end
	collectgarbage()
end

G.equivalentAny = {}

local function rawEquivalent(a, b, checked, path, path_idx, why)
	if a == equivalentAny or b == equivalentAny then
		return true
	end

	if type(a) ~= type(b) then
		path[path_idx] = nil
		why(path, a, b)
		return false
	end

	if type(a) ~= "table" then
		if a ~= b then
			path[path_idx] = nil
			why(path, a, b)
			return false
		end
		return true
	end

	if checked[a] == nil then checked[a] = {} end
	checked[a][b] = true

	if checked[b] == nil then checked[b] = {} end
	checked[b][a] = true

	for k, av in pairs(a) do
		local bv = b[k]

		path[path_idx] = k

		if not rawEquivalent(av, bv, checked, path, path_idx+1, why) then return false end
	end
	for k, bv in pairs(b) do
		local av = a[k]

		path[path_idx] = k

		if not rawEquivalent(av, bv, checked, path, path_idx+1, why) then return false end
	end

	return true
end

function G.equivalent(a, b, why)
	if not why then why = function() end end
	return rawEquivalent(a, b, {}, {}, 1, why)
end

function G.getcallsite(n)
	local trace = lua_debug.traceback("", n+1)
	return string.match(trace, "stack traceback:\n\t([^:]+:[^:]+): ")
end

assert = setmetatable({}, {
	__call = function(tbl, arg, msg)
		if not arg then
			if msg then
				error(msg, 2)
			else
				error("assertion failed", 2)
			end
		end
	end,
	__index = {
		equal = function(a, b, epsilon)
			if (epsilon and math.abs(a - b) > epsilon) or (not epsilon and a ~= b) then
				error("values not equal: " .. debug.dump(a) .. " ~= " .. debug.dump(b), 2)
			end
		end,
		equivalent = function(a, b)
			local err
			if not equivalent(a, b, function(path, x, y)
				local p
				for _, e in ipairs(path) do
					if p then
						p = p .. "." .. debug.dump(e)
					else
						p = debug.dump(e)
					end
				end
				err = "values not equivalent at " .. (p or "$root") .. ": " .. debug.dump(x) .. " ~= " .. debug.dump(y) .. "\na = " .. debug.dump(a, true) .. "\nb = " .. debug.dump(b, true)
			end) then
				error(err, 2)
			end
		end,
		betweenOrEqual = function(v, lo, hi)
			if v < lo or hi < v then
				error("value " .. v .. " should be between " .. lo .. " and " .. hi .. " inclusive", 2)
			end
		end,
		contained = function(val, set, allowNil)
			if val == nil then
				if allowNil then return end
				error("value is nil", 2)
			end
			for _, v in pairs(set) do
				if v == val then return end
			end
			error("value " .. debug.dump(val) .. " not found", 2)
		end,
		error = function(f, expect)
			local ok, actual = pcall(f)
			if ok then
				error("function did not throw an error", 2)
			end
			if not string.match(tostring(actual), "^" .. expect .. "$") then
				error("function threw unexpected error: " .. tostring(actual), 2)
			end
		end,
		errorat = function(f, expect)
			local loc = getcallsite(2)
			local ok, actual = pcall(f, function() loc = getcallsite(2) end)
			if ok then
				error("function did not throw an error", 2)
			end
			if not string.match(tostring(actual), "^" .. loc .. ": " .. expect .. "$") then
				error("function threw unexpected error: " .. tostring(actual), 2)
			end
		end,
	},
})
