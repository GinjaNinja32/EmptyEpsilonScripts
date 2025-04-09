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
		assert.equivalent(e2.systems, {
			reactor       = { Health = 0.5 },
			beamweapons   = { Health = 1.0 },
			missilesystem = { Health = 0.8 },
			maneuver      = { Health = 1.0 },
			impulse       = { Health = 1.0 },
			warp          = { Health = 1.0 },
			jumpdrive     = { Health = 1.0 },
			frontshield   = { Health = 1.0 },
			rearshield    = { Health = 1.0 },
		})
	end
	do -- Load sysHealthMax
		local e2 = STBO()
		persistence.entity.load(e2, {"sysHealthMax"}, {sH={[6]=0.9}, sh={0.5, nil, 0.8}})
		assert.equivalent(e2.systems, {
			reactor       = { HealthMax = 1.0 },
			beamweapons   = { HealthMax = 1.0 },
			missilesystem = { HealthMax = 1.0 },
			maneuver      = { HealthMax = 1.0 },
			impulse       = { HealthMax = 1.0 },
			warp          = { HealthMax = 0.9 },
			jumpdrive     = { HealthMax = 1.0 },
			frontshield   = { HealthMax = 1.0 },
			rearshield    = { HealthMax = 1.0 },
		})
	end
	do -- Load sysHealthMax, sysHealth
		local e2 = STBO()
		persistence.entity.load(e2, {"sysHealthMax", "sysHealth"}, {sH={[6]=0.9}, sh={0.5, nil, 0.8}})
		assert.equivalent(e2.systems, {
			reactor       = { HealthMax = 1.0, Health = 0.5 },
			beamweapons   = { HealthMax = 1.0, Health = 1.0 },
			missilesystem = { HealthMax = 1.0, Health = 0.8 },
			maneuver      = { HealthMax = 1.0, Health = 1.0 },
			impulse       = { HealthMax = 1.0, Health = 1.0 },
			warp          = { HealthMax = 0.9, Health = 0.9 },
			jumpdrive     = { HealthMax = 1.0, Health = 1.0 },
			frontshield   = { HealthMax = 1.0, Health = 1.0 },
			rearshield    = { HealthMax = 1.0, Health = 1.0 },
		})
	end
end)
