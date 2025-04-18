require "gn32/test/test"
require "gn32/stdext"

require "gn32/track"

local function getEnts(tracker)
	local t1 = {}
	tracker:each(function(e) table.insert(t1, e) end)

	local t2 = {}
	for e in pairs(tracker) do table.insert(t2, e) end

	assert.equivalent(t1, t2)

	return t1
end

test("track", function()
	local foo = Tracker()
	local bar = Tracker()
	local baz = Tracker()

	local e1 = Entity():setCallSign("e1")
	local e2 = Entity():setCallSign("e2")

	foo:set(e1, "e1f")
	foo:set(e2, "e2f")
	bar:set(e1, "e1b")

	assert(foo:get(e1) == "e1f")
	assert(foo:get(e2) == "e2f")
	assert(bar:get(e1) == "e1b")
	assert(bar:get(e2) == nil)

	assert(table.equals(getEnts(foo), {e1, e2}))
	assert(table.equals(getEnts(bar), {e1}))
	assert(table.equals(getEnts(baz), {}))

	local visited = {}
	foo:each(function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {e1, e2}))

	local visited = {}
	bar:each(function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {e1}))

	local visited = {}
	baz:each(function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {}))

	e1:destroy()

	assert(foo:get(e1) == nil)
	assert(foo:get(e2) == "e2f")
	assert(bar:get(e1) == nil)
	assert(bar:get(e2) == nil)

	local visited = {}
	foo:each(function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {e2}))

	local visited = {}
	bar:each(function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {}))

	local visited = {}
	baz:each(function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {}))

	e1 = Entity():setCallSign("e1")

	local list = {[e1]=1, [e2]=2}
	local N = 10
	foo:set(e1)
	foo:set(e2)
	for i = 3, N do
		local e = Entity():setCallSign("e" .. tostring(i))
		list[e] = i
		foo:set(e)
	end

	assert.equal(N, #getEnts(foo))

	foo:each(function(e) e:destroy() end)

	assert.equal(0, #getEnts(foo))
end)
