require "gn32/test/test"

require "gn32/track"

test("track", function()
	local e1 = Entity():setCallSign("e1")
	local e2 = Entity():setCallSign("e2")

	track.set("foo", e1, "e1f")
	track.set("foo", e2, "e2f")
	track.set("bar", e1, "e1b")

	assert(track.get("foo", e1) == "e1f")
	assert(track.get("foo", e2) == "e2f")
	assert(track.get("bar", e1) == "e1b")
	assert(track.get("bar", e2) == nil)

	assert(table.equals(track.get("foo"), {e1, e2}))
	assert(table.equals(track.get("bar"), {e1}))
	assert(table.equals(track.get("baz"), {}))

	local visited = {}
	track.each("foo", function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {e1, e2}))

	local visited = {}
	track.each("bar", function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {e1}))

	local visited = {}
	track.each("baz", function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {}))

	e1:destroy()

	assert(track.get("foo", e1) == nil)
	assert(track.get("foo", e2) == "e2f")
	assert(track.get("bar", e1) == nil)
	assert(track.get("bar", e2) == nil)

	assert(table.equals(track.get("foo"), {e2}))
	assert(table.equals(track.get("bar"), {}))
	assert(table.equals(track.get("baz"), {}))

	local visited = {}
	track.each("foo", function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {e2}))

	local visited = {}
	track.each("bar", function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {}))

	local visited = {}
	track.each("baz", function(e) table.insert(visited, e) end)
	assert(table.equals(visited, {}))

	local list = {[e1]=1, [e2]=2}
	local N = 10
	track.set("foo", e1)
	track.set("foo", e2)
	for i = 3, N do
		local e = Entity():setCallSign("e" .. tostring(i))
		list[e] = i
		track.set("foo", e)
	end

	assert.equal(N, #track.get("foo"))

	track.each("foo", function(e) e:destroy() end)

	assert.equal(0, #track.get("foo"))
end)
