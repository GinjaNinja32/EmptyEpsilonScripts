require "gn32/test/test"

require "gn32/getargs"

test("getargs", function()
	local a, b, c = getargs("foo", "number", "string", "boolean")(1, "asdf", true)
	assert.equal(a, 1)
	assert.equal(b, "asdf")
	assert.equal(c, true)

	assert.error(function()
		getargs("foo", "number", "string", "boolean")(1, "asdf")
	end, "foo%(number, string, boolean%): bad args: expected argument 3 to be a boolean")

	assert.error(function()
		getargs("foo", "number", "string", "boolean")(1, "asdf", true, 42)
	end, "foo%(number, string, boolean%): too many arguments")

	assert.error(function()
		getargs("foo", "number", "string", "boolean")(1, "asdf", 42)
	end, "foo%(number, string, boolean%): bad args: expected argument 3 to be a boolean")

	local a, b, c = getargs("foo", "number", "any", "number")(1, nil, 2)
	assert.equal(a, 1)
	assert.equal(b, nil)
	assert.equal(c, 2)

	local a, b, c = getargs("foo", "number", "any", "any")(1, nil, nil)
	assert.equal(a, 1)
	assert.equal(b, nil)
	assert.equal(c, nil)
end)
