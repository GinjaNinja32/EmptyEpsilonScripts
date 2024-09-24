--- Vector/coordinate utilities.
-- @pragma nostrip

G.vector = {}

function vector.canonicalDeg(deg, half)
	deg = deg % 360
	deg = deg + 360
	deg = deg % 360

	if half and deg > 180 then
		deg = deg - 360
	end

	return deg
end

--- Convert an angle in degrees to radians.
function vector.radFromDeg(deg)
	return math.pi * deg / 180
end
--- Convert an angle in radians to degrees.
function vector.degFromRad(rad)
	return 180 * rad / math.pi
end

--- Convert r-theta coordinates to the equivalent x-y coordinates.
function vector.xyFromRadialRad(r, thetaRad)
	return r * math.cos(thetaRad), r * math.sin(thetaRad)
end
--- Convert r-theta coordinates to the equivalent x-y coordinates.
function vector.xyFromRadialDeg(r, thetaDeg)
	return vector.xyFromRadialRad(r, vector.radFromDeg(thetaDeg))
end

--- Convert x-y coordinates to the equivalent r-theta coordinates.
function vector.radialRadFromXY(x, y)
	return math.sqrt(x^2 + y^2), math.atan(y, x)
end
--- Convert x-y coordinates to the equivalent r-theta coordinates.
function vector.radialDegFromXY(x, y)
	return math.sqrt(x^2 + y^2), vector.degFromRad(math.atan(y, x))
end

local function twopoints(name, ...)
	local args = {...}

	for _, base in ipairs{1, 3} do
		local x, y
		if type(args[base]) == "table" and #args[base] == 2 then
			x, y = table.unpack(args[base])
		elseif type(args[base]) == "table" or type(args[base]) == "userdata" then
			x, y = args[base]:getPosition()

			if x == nil then
				-- TODO: internally docked ships on ECS have no position.
				-- get the position of the ship they're docked to instead
				local docked = args[base]:getDockedWith()
				if docked then
					x, y = docked:getPosition()
				end
			end
		end

		if x then
			table.insert(args, base+1, y)
			args[base] = x
		end
	end

	local x1, y1, x2, y2, z = table.unpack(args)
	if z ~= nil
		or type(x1) ~= "number"
		or type(y1) ~= "number"
		or type(x2) ~= "number"
		or type(y2) ~= "number"
		then
		error("bad args to " .. name .. ": (" .. type(x1) .. ", " .. type(x2) .. ", " .. type(x3) .. ", " .. type(x4) .. ")", 3)
	end

	return x1, y1, x2, y2
end

function vector.distance(...)
	local x1, y1, x2, y2 = twopoints("vector.distance", ...)

	return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end
