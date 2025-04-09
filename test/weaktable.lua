require "gn32/test/test"

require "gn32/weaktable"

local function copy(t)
	local res = {}
	for k, v in pairs(t) do
		res[k] = v
	end
	return res
end

local function wt_test(mode, wk, wv)
	test("weaktable/"..mode, function()
		local t = newWeakEntityTable(mode)
		local exp = {}

		local e1 = Entity():setCallSign("e1")
		local e2 = Entity():setCallSign("e2")
		local e3 = Entity():setCallSign("e3")
		local e4 = Entity():setCallSign("e4")
		local e5 = Entity():setCallSign("e5")

		t[e1] = e2
		exp[e1] = e2

		t[e2] = e1
		exp[e2] = e1

		t[e3] = e3
		exp[e3] = e3

		t[e4] = e5
		exp[e4] = e5

		assert.equivalent(copy(t), exp)

		e1:destroy()
		if wk then exp[e1] = nil end
		if wv then exp[e2] = nil end

		assert.equivalent(copy(t), exp)

		e2:destroy()
		if wk then exp[e2] = nil end
		if wv then exp[e1] = nil end

		assert.equivalent(copy(t), exp)

		e3:destroy()
		exp[e3] = nil

		assert.equivalent(copy(t), exp)

		e4:destroy()
		if wk then exp[e4] = nil end

		assert.equivalent(copy(t), exp)

		e5:destroy()
		if wv then exp[e4] = nil end

		assert.equivalent(copy(t), exp)
	end)
end

wt_test("k", true, false)
wt_test("v", false, true)
wt_test("kv", true, true)
