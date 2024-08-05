require "gn32/test/test"

require "gn32/hook"

test("hook/global", function()
	-- custom

	local args1
	function hook.on.foo(a, b, c) args1 = {a, b, c} end

	local args2
	function hook.on.foo(a, b, c) args2 = {a, b, c} end

	hook.trigger.foo(1)
	assert.equivalent(args1, {1})
	assert.equivalent(args2, {1})

	hook.trigger.foo(1, 2, 3)
	assert.equivalent(args1, {1, 2, 3})
	assert.equivalent(args2, {1, 2, 3})

	-- init

	local called = {}
	function hook.on.init() called.a = true end
	function hook.on.init() called.b = true end
	function hook.on.init() called.c = true end

	init()
	assert.equivalent(called, {a=true, b=true, c=true})

	-- update

	local called = {}
	function hook.on.update(delta) called.a = delta end
	function hook.on.update(delta) called.b = delta end
	function hook.on.update(delta) called.c = delta end

	update(42)
	assert.equivalent(called, {a=42, b=42, c=42})

	-- newPlayerShip

	local called = {}
	hook.on.newPlayerShip(function(ship) called.a = ship end)
	hook.on.newPlayerShip(function(ship) called.b = ship end)
	hook.on.newPlayerShip(function(ship) called.c = ship end)

	local s1 = PlayerShip()
	newPlayerShip(s1)
	assert.equivalent(called, {a=s1, b=s1, c=s1})

	-- probeLaunch

	local called = {}
	hook.on.probeLaunch(function(s, p) called.a = {s, p} end)
	hook.on.probeLaunch(function(s, p) called.b = {s, p} end)
	hook.on.probeLaunch(function(s, p) called.c = {s, p} end)

	local p1 = Entity()
	s1:probeLaunch(p1)
	assert.equivalent(called, {a={s1,p1}, b={s1,p1}, c={s1,p1}})
end)

test("hook/entity", function()
	-- custom

	local e1 = Entity()

	local called = {}
	hook.entity[e1].on.foo(function(e, x, y, z) called.a = {e, x, y, z} end)
	hook.entity[e1].on.foo(function(e, x, y, z) called.b = {e, x, y, z} end)
	hook.entity[e1].on.foo(function(e, x, y, z) called.c = {e, x, y, z} end)

	hook.entity[e1].trigger.foo(1, 2, 3)
	assert.equivalent(called, {a={e1, 1, 2, 3}, b={e1, 1, 2, 3}, c={e1, 1, 2, 3}})

	-- destroy

	local e1 = Entity()

	local called = {}
	hook.entity[e1].on.destroyed(function(e) called.a = e end)
	hook.entity[e1].on.destroyed(function(e) called.b = e end)
	hook.entity[e1].on.destroyed(function(e) called.c = e end)

	e1:destroy()
	assert.equivalent(called, {a=e1, b=e1, c=e1})

	-- destruction

	local e1 = Entity()

	local called = {}
	hook.entity[e1].on.destruction(function(e) called.a = e end)
	hook.entity[e1].on.destruction(function(e) called.b = e end)
	hook.entity[e1].on.destruction(function(e) called.c = e end)

	e1:destruct()
	assert.equivalent(called, {a=e1, b=e1, c=e1})

	-- expiration

	local e1 = Entity()

	local called = {}
	hook.entity[e1].on.expiration(function(e) called.a = e end)
	hook.entity[e1].on.expiration(function(e) called.b = e end)
	hook.entity[e1].on.expiration(function(e) called.c = e end)

	e1:expire()
	assert.equivalent(called, {a=e1, b=e1, c=e1})
end)
