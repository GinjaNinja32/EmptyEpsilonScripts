require "gn32/test/test"

require "gn32/debug"

test("debug", function()
	-- nil
	assert.equal(debug.dump(nil), "nil")
	-- number
	assert.equal(debug.dump(42), "42")
	assert.equal(debug.dump(-3), "-3")
	assert.equal(debug.dump(3.14), "3.14")
	assert.equal(debug.dump(1/0), "inf")
	-- boolean
	assert.equal(debug.dump(false), "false")
	assert.equal(debug.dump(true), "true")
	-- string
	assert.equal(debug.dump("foo"), "\"foo\"")
	assert.equal(debug.dump("foo\"bar"), "\"foo\"bar\"")
	-- table
	assert.equal(debug.dump({}), "{}")
	assert.equal(debug.dump({1, 2, 3}), "{1, 2, 3}")
	assert.equal(debug.dump({1, 2, 3}, true), "{\n    1,\n    2,\n    3,\n}")
	assert.equal(debug.dump({1, 2, [4]=4, a=5, b=6, ["c "]=7}), "{1, 2, [\"c \"]=7, [4]=4, a=5, b=6}")
end)
