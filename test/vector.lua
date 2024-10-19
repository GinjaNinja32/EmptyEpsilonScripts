require "gn32/test/test"

require "gn32/vector"

--[[
	NOTES
		+x, +y is southeast
		angles are always positive=CW
]]

local epsilon = 1e-10

test("vector/angle-conversion", function()
	local function assertCloseAngle(a, b, sys)
		local n = math.abs(a - b) % (2 * sys)
		if n > sys then
			n = n - 2 * sys
		end
		if math.abs(n) > epsilon then
			error(("angles not close (%s): %s <> %s"):format(n, a, b), 2)
		end
	end

	for deg = -360, 720 do
		local cdeg = (deg + 360) % 360
		local rad = (deg % 360) * math.pi / 180
		local hdg = (deg + 360 + 90) % 360

		assertCloseAngle(vector.radFromDeg(deg), rad, math.pi)
		assertCloseAngle(vector.radFromHeading(hdg), rad, math.pi)

		assertCloseAngle(vector.degFromRad(rad), deg, 180)
		assertCloseAngle(vector.degFromHeading(hdg), cdeg, 180)

		assert.equal(vector.headingFromDeg(deg), hdg, epsilon)
		assert.equal(vector.headingFromRad(rad), hdg, epsilon)

		assert.equal(vector.canonicalDeg(deg), cdeg, epsilon)
	end
end)

test("vector/coordinate-conversion", function()
	-- ASSUME: vector/angle-conversion OK

	local d345 = 53.130102354156

	for _, case in ipairs{
		{x=   0, y=   0, r=   0,            td=  0,            },
		{x=1000, y=   0, r=1000,            td=  0,            },
		{x=1000, y= 500, r=1118.0339887499, td= 26.565051177078},
		{x=1000, y=-500, r=1118.0339887499, td=-26.565051177078},

		{x= 3000, y= 4000, r=5000, td=d345,    },
		{x=-3000, y= 4000, r=5000, td= 180-d345},
		{x= 3000, y=-4000, r=5000, td=    -d345},
		{x=-3000, y=-4000, r=5000, td=d345- 180},
	} do
		-- xy => deg, separate args
		local r, thetaDeg = vector.radialDegFromXY(case.x, case.y)
		assert.equal(r, case.r, epsilon)
		assert.equal(thetaDeg, case.td, epsilon)

		-- xy => deg, table
		local r, thetaDeg = vector.radialDegFromXY({case.x, case.y})
		assert.equal(r, case.r, epsilon)
		assert.equal(thetaDeg, case.td, epsilon)

		-- xy => deg, entity
		local r, thetaDeg = vector.radialDegFromXY(Entity():setPosition(case.x, case.y))
		assert.equal(r, case.r, epsilon)
		assert.equal(thetaDeg, case.td, epsilon)

		-- xy => rad, separate args
		local r, thetaRad = vector.radialRadFromXY(case.x, case.y)
		assert.equal(r, case.r, epsilon)
		assert.equal(thetaRad, vector.radFromDeg(case.td), epsilon)

		-- xy => rad, table
		local r, thetaRad = vector.radialRadFromXY({case.x, case.y})
		assert.equal(r, case.r, epsilon)
		assert.equal(thetaRad, vector.radFromDeg(case.td), epsilon)

		-- xy => rad, entity
		local r, thetaRad = vector.radialRadFromXY(Entity():setPosition(case.x, case.y))
		assert.equal(r, case.r, epsilon)
		assert.equal(thetaRad, vector.radFromDeg(case.td), epsilon)

		-- r-deg => xy, separate args
		local x, y = vector.xyFromRadialDeg(case.r, case.td)
		assert.equal(x, case.x, epsilon)
		assert.equal(y, case.y, epsilon)

		-- r-deg => xy, table
		local x, y = vector.xyFromRadialDeg({case.r, case.td})
		assert.equal(x, case.x, epsilon)
		assert.equal(y, case.y, epsilon)

		-- r-rad => xy, separate args
		local x, y = vector.xyFromRadialRad(case.r, vector.radFromDeg(case.td))
		assert.equal(x, case.x, epsilon)
		assert.equal(y, case.y, epsilon)

		-- r-rad => xy, table
		local x, y = vector.xyFromRadialRad({case.r, vector.radFromDeg(case.td)})
		assert.equal(x, case.x, epsilon)
		assert.equal(y, case.y, epsilon)

		-- xy => r-hdg
		local r, heading = vector.radialHeadingFromXY(case.x, case.y)
		assert.equal(r, case.r, epsilon)
		assert.equal(heading, vector.canonicalDeg(case.td + 90), epsilon)

		-- r-hdg => xy
		local x, y = vector.xyFromRadialHeading(case.r, case.td + 90)
		assert.equal(x, case.x, epsilon)
		assert.equal(y, case.y, epsilon)
	end
end)

test("vector/rotate", function()
	-- ASSUME: vector/coordinate-conversion OK

	for x = -5000, 5000, 1000 do
		for y = -5000, 5000, 1000 do
			for rotate = -180, 180, 10 do
				local r, theta = vector.radialDegFromXY(x, y)

				local rotx, roty = vector.xyRotateDeg(x, y, rotate)
				local rotr, rottheta = vector.radialDegFromXY(rotx, roty)

				assert.equal(rotr, r, epsilon)

				if r ~= 0 then
					assert.equal(0, vector.canonicalDeg(theta - rotate - rottheta, true), epsilon)
				end
			end
		end
	end
end)

test("vector/distance", function()
	local function e(x, y)
		return Entity():setPosition(x, y)
	end

	for _, case in ipairs{
		{d=0,       0,    0,     0,     0},
		{d=1000,    0, -500,     0,   500},
		{d=5000,  500,  500, -2500, -3500},
		{d=5000,  500, -500, -2500,  3500},
		{d=5000, -500,  500,  2500, -3500},
		{d=5000, -500, -500,  2500,  3500},

		{d=5000,   0, 0,    3000, 4000},
		{d=5000,   0, 0,   {3000, 4000}},
		{d=5000,   0, 0,  e(3000, 4000)},
		{d=5000,  {0, 0},   3000, 4000},
		{d=5000,  {0, 0},  {3000, 4000}},
		{d=5000,  {0, 0}, e(3000, 4000)},
		{d=5000, e(0, 0),   3000, 4000},
		{d=5000, e(0, 0),  {3000, 4000}},
		{d=5000, e(0, 0), e(3000, 4000)},
	} do
		assert.equal(vector.distance(table.unpack(case)), case.d, epsilon)
	end
end)

test("vector/badargs", function()
	assert.error(function()
		vector.xyFromRadialRad(42)
	end, "./gn32/test/vector.lua:%d+: xyFromRadialRad%(rtheta%): bad args: at argument 1: expected two numbers, or a table containing two numbers")

	assert.error(function()
		vector.xyFromRadialDeg(Entity():setPosition(200, 300))
	end, "./gn32/test/vector.lua:%d+: xyFromRadialDeg%(rtheta%): bad args: at argument 1: expected two numbers, or a table containing two numbers")

	assert.error(function()
		vector.radialRadFromXY(true, 2)
	end, "./gn32/test/vector.lua:%d+: radialRadFromXY%(xy%): bad args: at argument 1: expected two numbers, an entity, or a table containing two numbers")

	assert.error(function()
		vector.radialDegFromXY(1, 2, 3)
	end, "./gn32/test/vector.lua:%d+: radialDegFromXY%(xy%): too many arguments")

	assert.error(function()
		local e = Entity()
		e:destroy()
		vector.xyRotateRad(e, 3)
	end, "./gn32/test/vector.lua:%d+: xyRotateRad%(xy, number%): bad args: argument 1 is a destroyed entity")

	assert.error(function()
		vector.xyRotateDeg(1, nil, 3)
	end, "./gn32/test/vector.lua:%d+: xyRotateDeg%(xy, number%): bad args: at argument 1: expected two numbers, an entity, or a table containing two numbers")

	assert.error(function()
		vector.distance(1, 2, 3)
	end, "./gn32/test/vector.lua:%d+: distance%(xy, xy%): bad args: at argument 3: expected two numbers, an entity, or a table containing two numbers")
end)
