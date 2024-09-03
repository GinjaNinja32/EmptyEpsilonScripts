require "gn32/test/test"

require "gn32/ecs"

test("ecs", function()
	Comp("name")
		:setSchema({
			name = {_type="string"},
		})

	Comp("foo")
		:setSchema({
			bar = {_default=0, _type="number", _min=0, _max=100},
		})

	local seenEnts = {}

	local asdf = System("asdf")
		:addRequiredComps("foo", "name")
		:onUpdateGlobal(function(delta, ents)
			for ent, comps in pairs(ents) do
				seenEnts[comps.name.name] = comps.foo.bar
			end
		end)

	local function doRun()
		seenEnts = {}
		System.update(0.02)
		return seenEnts
	end

	assert.equivalent(doRun(), {})

	local e1 = Entity():setCallSign("CSe1")
	comps(e1).foo = {bar = 42}
	comps(e1).name = {name = "e1"}

	local e2 = Entity():setCallSign("CSe2")
	comps(e2).foo = {bar = 100}
	comps(e2).name = {name = "e2"}
	comps(e2).foo.bar = 50

	local e3 = Entity():setCallSign("CSe3")
	comps(e3).name = {name = "e3"}

	assert.equivalent(doRun(), { e1 = 42, e2 = 50 })

	comps(e3).foo = {}
	comps(e2).foo = nil

	assert.equivalent(doRun(), { e1 = 42, e3 = 0 })

	collectgarbage()

	assert.equivalent(doRun(), { e1 = 42, e3 = 0 })

	e3:destroy()

	assert.equivalent(doRun(), { e1 = 42 })

	local e3b = Entity():setCallSign("CSe3b")
	comps(e3b).name = {name = "e3b"}
	comps(e3b).foo = {}

	assert.equivalent(doRun(), { e1 = 42, e3b = 0 })

	e3b = nil
	collectgarbage()

	assert.equivalent(doRun(), { e1 = 42 })

	assert.error(function()
		comps(e1).name = {}
	end, "./gn32/test/ecs.lua:%d+: comps.name.name: bad type nil: expected string")

	assert.error(function()
		comps(e1).foo.stuff = 1234
	end, "./gn32/test/ecs.lua:%d+: comps.foo.stuff: field not defined")

	assert.error(function()
		comps(e1).foo = {stuff = 1234}
	end, "./gn32/test/ecs.lua:%d+: comps.foo.stuff: field not defined")

	assert.error(function()
		comps(e1).foo.bar = 1234
	end, "./gn32/test/ecs.lua:%d+: comps.foo.bar: bad value 1234: expected value <= 100")

	assert.error(function()
		comps(e1).foo = {bar = 1234}
	end, "./gn32/test/ecs.lua:%d+: comps.foo.bar: bad value 1234: expected value <= 100")

	assert.error(function()
		comps(e1).bar = {}
	end, "./gn32/test/ecs.lua:%d+: comp bar is not defined")

	local systemOrder = {}

	System("d"):runBefore("p")              :onUpdateGlobal(function() table.insert(systemOrder, "d") end)
	System("e"):runAfter("c"):runAfter("q") :onUpdateGlobal(function() table.insert(systemOrder, "e") end)
	System("b"):runAfter("a")               :onUpdateGlobal(function() table.insert(systemOrder, "b") end)
	System("c"):runAfter("a"):runBefore("d"):onUpdateGlobal(function() table.insert(systemOrder, "c") end)
	System("a")                             :onUpdateGlobal(function() table.insert(systemOrder, "a") end)

	assert.equal(System.update(0.02), 3)
	assert.equivalent(systemOrder, {"a", "b", "c", "d", "e"})

	systemOrder = {}
	assert.equal(System.update(0.02), 1)
	assert.equivalent(systemOrder, {"a", "b", "c", "d", "e"})

	System("f"):runAfter("e"):runBefore("c")

	assert.error(function()
		System.update(0.02)
	end, "./gn32/ecs.lua:%d+: unsolvable constraints:\n"
		.. "system c should run after a, f\n"
		.. "system d should run after c\n"
		.. "system e should run after c\n"
		.. "system f should run after e\n")
end)
