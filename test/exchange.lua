require "gn32/test/test"

require "gn32/exchange"

test("exchange/format", function()
	assert.equal(exchange.formatString({energy = 1}), "1 energy")
	assert.equal(exchange.formatString({energy = 2}), "2 energy")
	assert.equal(exchange.formatString({hull = 3}), "3 hull")
	assert.equal(exchange.formatString({coolant = 4}), "40% coolant")
	assert.equal(exchange.formatString({probe = 5}), "5 probes")
	assert.equal(exchange.formatString({w_hvli = 6}), "6 HVLIs")
	assert.equal(exchange.formatString({w_homing = 7}), "7 homings")
	assert.equal(exchange.formatString({w_mine = 8}), "8 mines")
	assert.equal(exchange.formatString({w_emp = 9}), "9 EMPs")
	assert.equal(exchange.formatString({w_nuke = 10}), "10 nukes")

	assert.equal(exchange.formatString({custom = {format = function() return "foo" end}}), "foo")
	assert.equal(exchange.formatString({custom = {}}), "")

	assert.equivalent(exchange.format({
		custom = {format = function() return "foo" end},
		energy = 1,
		hull = 3,
		w_hvli = 6,
	}), {"foo", "1 energy", "3 hull", "6 HVLIs"})
	assert.equal(exchange.formatString({
		custom = {format = function() return "foo" end},
		energy = 1,
		hull = 3,
		w_hvli = 6,
	}), "foo, 1 energy, 3 hull, 6 HVLIs")

	assert.equivalent(exchange.format({
		custom = {},
		energy = 1,
		hull = 3,
		w_hvli = 6,
	}), {"1 energy", "3 hull", "6 HVLIs"})
	assert.equal(exchange.formatString({
		custom = {},
		energy = 1,
		hull = 3,
		w_hvli = 6,
	}), "1 energy, 3 hull, 6 HVLIs")
end)

test("exchange/take", function()
	local ship = PlayerSpaceship():setMaxEnergy(100):setEnergy(50)

	assert.equal(exchange.canTake(ship, {energy = 45}), true)
	assert.equal(exchange.canTake(ship, {energy = 55}), false)

	exchange.take(ship, {energy = 45})

	assert.equal(ship:getEnergy(), 5)
end)

test("exchange/add", function()
	local ship = PlayerSpaceship():setMaxEnergy(100):setEnergy(50)

	assert.equal(exchange.canAdd(ship, {energy = 45}), true)
	assert.equal(exchange.canAdd(ship, {energy = 55}), false)

	exchange.add(ship, {energy = 45})

	assert.equal(ship:getEnergy(), 95)
end)

test("exchange/swap", function()
	local ship = PlayerSpaceship()
		:setMaxEnergy(100):setEnergy(50)
		:setMaxScanProbeCount(20):setScanProbeCount(10)

	assert.equal(exchange.canSwap(ship, {energy = 45}, {probe = 5}), true)
	assert.equal(exchange.canSwap(ship, {energy = 55}, {probe = 5}), false)
	assert.equal(exchange.canSwap(ship, {energy = 45}, {probe = 11}), false)

	exchange.swap(ship, {energy = 45}, {probe = 5})

	assert.equal(ship:getEnergy(), 5)
	assert.equal(ship:getScanProbeCount(), 15)
end)
