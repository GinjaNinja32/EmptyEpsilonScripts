require "gn32/test/test"

require "gn32/persistence_entity"

test("persistence.entity", function()
	do
		local e = STBO()
			:setPosition(42, 1)
			:setRotation(123)
			:setHullMax(100)
			:setHull(100)
			:setSystemHealth("reactor", 0.5)
			:setSystemHealth("missilesystem", 0.8)
			:setSystemHealthMax("warp", 0.9)
			:setSystemHealth("warp", 0.9)

		assert.equivalent(
			persistence.entity.save(e, {"position"}),
			{p={42, 1, 123}}
		)
		assert.equivalent(
			persistence.entity.save(e, {"hull"}),
			{}
		)
		assert.equivalent(
			persistence.entity.save(e, {"hullMax"}),
			{H=100}
		)
		assert.equivalent(
			persistence.entity.save(e, {"position", "hullMax", "hull"}),
			{p={42, 1, 123}, H=100}
		)
		e:setHull(75)
		assert.equivalent(
			persistence.entity.save(e, {"position", "hullMax", "hull"}),
			{p={42, 1, 123}, H=100, h=75}
		)

		assert.equivalent(
			persistence.entity.save(e, {"sysHealth"}),
			{sh={0.5, nil, 0.8}}
		)
		assert.equivalent(
			persistence.entity.save(e, {"sysHealthMax"}),
			{sH={[6]=0.9}}
		)
		assert.equivalent(
			persistence.entity.save(e, {"sysHealthMax", "sysHealth"}),
			{sH={[6]=0.9}, sh={0.5, nil, 0.8}}
		)
	end

	do -- Load position
		local e2 = STBO()
		persistence.entity.load(e2, {"position"}, {p={2, 3, 4}, H=100})
		assert.equivalent({e2:getPosition()}, {2, 3})
		assert.equal(e2:getRotation(), 4)
		assert.equal(e2:getHullMax(), 0)
		assert.equal(e2:getHull(), 0)
	end
	do -- Load hullMax
		local e2 = STBO()
		persistence.entity.load(e2, {"hullMax"}, {p={2, 3, 4}, H=100})
		assert.equivalent({e2:getPosition()}, {0, 0})
		assert.equal(e2:getRotation(), 0)
		assert.equal(e2:getHullMax(), 100)
		assert.equal(e2:getHull(), 0)
	end
	do -- Load hullMax, hull
		local e2 = STBO()
		persistence.entity.load(e2, {"hullMax", "hull"}, {p={2, 3, 4}, H=100})
		assert.equivalent({e2:getPosition()}, {0, 0})
		assert.equal(e2:getRotation(), 0)
		assert.equal(e2:getHullMax(), 100)
		assert.equal(e2:getHull(), 100)
	end
	do -- Load hullMax, hull
		local e2 = STBO()
		persistence.entity.load(e2, {"hullMax", "hull"}, {p={2, 3, 4}, H=100, h=75})
		assert.equivalent({e2:getPosition()}, {0, 0})
		assert.equal(e2:getRotation(), 0)
		assert.equal(e2:getHullMax(), 100)
		assert.equal(e2:getHull(), 75)
	end
	do -- Load position, hullMax, hull
		local e2 = STBO()
		persistence.entity.load(e2, {"position", "hullMax", "hull"}, {p={2, 3, 4}, H=100})
		assert.equivalent({e2:getPosition()}, {2, 3})
		assert.equal(e2:getRotation(), 4)
		assert.equal(e2:getHullMax(), 100)
		assert.equal(e2:getHull(), 100)
	end
	do -- Load sysHealth
		local e2 = STBO()
		persistence.entity.load(e2, {"sysHealth"}, {sH={[6]=0.9}, sh={0.5, nil, 0.8}})
		assert.equivalent(e2.systemData, {
			reactor       = { cur = 0.5 },
			beamweapons   = { cur = 1.0 },
			missilesystem = { cur = 0.8 },
			maneuver      = { cur = 1.0 },
			impulse       = { cur = 1.0 },
			warp          = { cur = 1.0 },
			jumpdrive     = { cur = 1.0 },
			frontshield   = { cur = 1.0 },
			rearshield    = { cur = 1.0 },
		})
	end
	do -- Load sysHealthMax
		local e2 = STBO()
		persistence.entity.load(e2, {"sysHealthMax"}, {sH={[6]=0.9}, sh={0.5, nil, 0.8}})
		assert.equivalent(e2.systemData, {
			reactor       = { max = 1.0 },
			beamweapons   = { max = 1.0 },
			missilesystem = { max = 1.0 },
			maneuver      = { max = 1.0 },
			impulse       = { max = 1.0 },
			warp          = { max = 0.9 },
			jumpdrive     = { max = 1.0 },
			frontshield   = { max = 1.0 },
			rearshield    = { max = 1.0 },
		})
	end
	do -- Load sysHealthMax, sysHealth
		local e2 = STBO()
		persistence.entity.load(e2, {"sysHealthMax", "sysHealth"}, {sH={[6]=0.9}, sh={0.5, nil, 0.8}})
		assert.equivalent(e2.systemData, {
			reactor       = { max = 1.0, cur = 0.5 },
			beamweapons   = { max = 1.0, cur = 1.0 },
			missilesystem = { max = 1.0, cur = 0.8 },
			maneuver      = { max = 1.0, cur = 1.0 },
			impulse       = { max = 1.0, cur = 1.0 },
			warp          = { max = 0.9, cur = 0.9 },
			jumpdrive     = { max = 1.0, cur = 1.0 },
			frontshield   = { max = 1.0, cur = 1.0 },
			rearshield    = { max = 1.0, cur = 1.0 },
		})
	end
end)
