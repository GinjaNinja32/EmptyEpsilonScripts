require "gn32/test/test"

require "gn32/stdext"

test("stdext/table.defaulting", function()
	local t = table.defaulting(function() return 0 end, true)

	assert.equal(t.x, 0)
	assert.equal(t.y, 0)
	assert.equal(t.z, 0)

	t.x = 42
	t.y = nil

	assert.equal(t.x, 42)
	assert.equal(t.y, 0)
	assert.equal(t.z, 0)

	local t = table.defaulting(function() return {} end)

	assert.equivalent(t.x, {})
	t.x.foo = 42
	assert.equivalent(t.x, {foo=42})
	assert.equal(t.x, t.x)
end)

test("stdext/table.contains", function()
	local t = {"a", "b", "c", "d", "e", "f", "g"}

	assert.equal(table.contains(t, "d"), true)
	assert.equal(table.contains(t, "h"), false)

	assert.equal(table.indexOf(t, "d"), 4)
	assert.equal(table.indexOf(t, "h"), nil)
end)

test("stdext/string.title", function()
	assert.equal(string.title("foo bar baz"), "Foo Bar Baz")
	assert.equal(string.title("FOO BaR bAZ"), "Foo Bar Baz")
	assert.equal(string.title("o'brien"), "O'Brien")

	assert.equal(string.title("foo bar baz", {upper=string.lower, lower=string.upper}), "fOO bAR bAZ")
end)

test("stdext/string.split", function()
	assert.equivalent(string.split("foo bar baz", " "), {"foo", "bar", "baz"})
	assert.equivalent(string.split("foo bar baz ", " "), {"foo", "bar", "baz", ""})
	assert.equivalent(string.split(" foo bar baz", " "), {"", "foo", "bar", "baz"})
	assert.equivalent(string.split(" foo bar baz ", " "), {"", "foo", "bar", "baz", ""})

	assert.equivalent(string.split("foo bar oooooh baz", "oo"), {"f", " bar ", "", "oh baz"})

	assert.equivalent(string.split("foo bar baz stuff", " ", 0), {"foo", "bar", "baz", "stuff"})
	assert.equivalent(string.split("foo bar baz stuff", " ", 3), {"foo", "bar", "baz", "stuff"})
	assert.equivalent(string.split("foo bar baz stuff", " ", 2), {"foo", "bar", "baz stuff"})
	assert.equivalent(string.split("foo bar baz stuff", " ", 1), {"foo", "bar baz stuff"})
end)
