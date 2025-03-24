require "gn32/test/test"

require "gn32/getargs"

local function noTCO(...) return ... end
local function exec(f, ...) return noTCO(f(...)) end
local _, err_pfx = pcall(exec, error, "", 1)

local function argtest(t)
	local a, b, c = t("foo", {"number", "string", "boolean"}, {1, "asdf", true})
	assert.equal(a, 1)
	assert.equal(b, "asdf")
	assert.equal(c, true)

	assert.error(function()
		t("err_1", {"number", "string", "boolean"}, {1, "asdf"})
	end, err_pfx .. "err_1%(number, string, boolean%): bad args %(1, asdf%): at argument 3: expected a boolean")

	assert.error(function()
		t("err_2", {"number", "string", "boolean"}, {1, "asdf", true, 42})
	end, err_pfx .. "err_2%(number, string, boolean%): bad args %(1, asdf, true, 42%): at argument 4: too many arguments")

	assert.error(function()
		t("err_3", {"number", "string", "boolean"}, {1, "asdf", 42})
	end, err_pfx .. "err_3%(number, string, boolean%): bad args %(1, asdf, 42%): at argument 3: expected a boolean")

	local a, b, c = t("foo", {"number", "any", "number"}, {1, nil, 2})
	assert.equal(a, 1)
	assert.equal(b, nil)
	assert.equal(c, 2)

	local a, b, c = t("foo", {"number", "any", "any"}, {1, nil, nil})
	assert.equal(a, 1)
	assert.equal(b, nil)
	assert.equal(c, nil)
end

test("getargs", function()
	argtest(function(fname, fargs, args)
		return exec(function(...)
			local t = {getargs(fname, table.unpack(fargs))(...)}
			return table.unpack(t)
		end, table.unpack(args))
	end)
end)

test("withargs", function()
	argtest(function(fname, fargs, args)
		local res
		local capture = function(...) res = {...} end
		local f = withargs(fname, fargs, capture)
		exec(f, table.unpack(args))
		return table.unpack(res)
	end)
end)
