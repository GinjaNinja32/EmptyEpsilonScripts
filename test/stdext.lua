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

test("stdext/table.mergeLists", function()
	local t1 = {1}
	local t2 = {2, 3}
	local t3 = {4, 5, 6}
	local t4 = {7, 8, 9, 10}

	assert.equivalent(table.mergeLists(), {})
	assert.equivalent(table.mergeLists({}, {}, {}, {}), {})

	assert.equivalent(table.mergeLists(t1), t1)
	assert.equivalent(table.mergeLists(t1, t2), {1, 2, 3})
	assert.equivalent(table.mergeLists(t1, t2, t3), {1, 2, 3, 4, 5, 6})
	assert.equivalent(table.mergeLists(t1, t2, t3, t4), {1, 2, 3, 4, 5, 6, 7, 8, 9, 10})
	assert.equivalent(table.mergeLists(t4, t2, t1, t3), {7, 8, 9, 10, 2, 3, 1, 4, 5, 6})
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

test("stdext/table.readonly", function()
	local t = {x=1, y=2, z=3}
	local t_ro = table.readonly(t)

	assert.equivalent(t, t_ro)

	assert.equal(t.x, t_ro.x)
	assert.equal(t.y, t_ro.y)
	assert.equal(t.z, t_ro.z)

	local copy = {}
	for k, v in pairs(t_ro) do
		copy[k] = v
	end
	assert.equivalent(t, copy)

	assert.errorat(function() t_ro.x = 2 end, "attempt to write to read%-only table")
	assert.equal(t_ro.x, 1)
	assert.equal(t.x, 1)

	assert.equal(getmetatable(t_ro), "table.readonly")
end)
