--- Vector/coordinate utilities.
-- @pragma nostrip

require "gn32/lang"
require "gn32/getargs"

G.vector = {}

--- A point in a polar coordinate space.
-- Valid argument forms:
--
-- - two numbers `r, theta`
-- - a table of two numbers `{r, theta}`
-- @within Argument Types
-- @table rtheta
function argtypes.rtheta(n, args, ent)
	if type(args[n]) == "table" and #args[n] == 2 and type(args[n][1]) == "number" and type(args[n][2]) == "number" then
		return 1, args[n]
	end

	if type(args[n]) == "number" and type(args[n+1]) == "number" then
		return 2, 2, args[n], args[n+1]
	end

	local orEnt = ""
	if ent then
		orEnt = ", an entity"
	end
	return nil, ("expected two numbers%s, or a table containing two numbers"):format(orEnt)
end

--- A point in a Cartesian coordinate space.
-- Valid argument forms:
--
-- - two numbers `x, y`
-- - a table of two numbers `{x, y}`
-- - an entity `ent`
-- @within Argument Types
-- @table xy
function argtypes.xy(n, args)
	if (type(args[n]) == "table" or type(args[n]) == "userdata") and args[n].getPosition then
		if args[n].isValid and not args[n]:isValid() then
			return nil, ("argument %d is a destroyed entity"):format(n)
		end

		local x, y = args[n]:getPosition()
		if not x then -- TODO ECS internal docking
			if args[n]:getDockedWith() then
				x, y = args[n]:getDockedWith():getPosition()
			end
		end

		return 1, 2, x, y
	end

	return argtypes.rtheta(n, args, true)
end

--- Convert an angle (deg) to its canonical value.
-- By default, this places the angle in the range [0, 360).
-- If `half` is true, the angle is instead placed in (-180, 180].
-- @tparam number deg The angle to canonicalise.
-- @tparam[opt] boolean half Whether to canonicalise to half-turn from centre.
function vector.canonicalDeg(deg, half)
	deg = deg % 360 -- get it close
	deg = deg + 360 -- ensure it's positive
	deg = deg % 360 -- wrap it down again if needed

	if half and deg > 180 then
		deg = deg - 360
	end

	return deg
end

do -- Angle unit conversions

	--- Convert an angle in degrees to radians.
	-- @tparam number deg The angle (deg) to convert.
	-- @treturn number The converted angle (rad).
	function vector.radFromDeg(deg)
		return math.pi * deg / 180
	end
	--- Convert a heading to radians clockwise from East.
	-- @tparam number heading The heading to convert.
	-- @treturn number The converted angle (rad).
	function vector.radFromHeading(heading)
		return math.pi * (heading - 90) / 180
	end
	--- Convert an angle in radians to degrees.
	-- @tparam number rad The angle (rad) to convert.
	-- @treturn number The converted angle (deg).
	function vector.degFromRad(rad)
		return 180 * rad / math.pi
	end
	--- Convert a heading to degrees clockwise from East.
	-- @tparam number heading The heading to convert.
	-- @treturn number The converted angle (deg).
	function vector.degFromHeading(heading)
		return heading - 90
	end

	--- Convert an angle clockwise from East in degrees to a heading.
	-- @tparam number deg The angle (deg) to convert.
	-- @treturn number The converted heading.
	function vector.headingFromDeg(deg)
		return vector.canonicalDeg(90 + deg)
	end
	--- Convert an angle clockwise from East in radians to a heading.
	-- @tparam number rad The angle (rad) to convert.
	-- @treturn number The converted heading.
	function vector.headingFromRad(rad)
		return vector.canonicalDeg(90 + vector.degFromRad(rad))
	end
end

do -- Point coordinate conversions

	--- Convert r-theta coordinates (rad) to the equivalent x-y coordinates.
	-- @tparam rtheta rtheta The coordinate (rad) to convert.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyFromRadialRad(...)
		local r, thetaRad = getargs("xyFromRadialRad", "rtheta")(...)
		return r * math.cos(thetaRad), r * math.sin(thetaRad)
	end
	--- Convert r-theta coordinates (deg) to the equivalent x-y coordinates.
	-- @tparam rtheta rtheta The coordinate (deg) to convert.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyFromRadialDeg(...)
		local r, thetaDeg = getargs("xyFromRadialDeg", "rtheta")(...)
		local thetaRad = vector.radFromDeg(thetaDeg)
		return r * math.cos(thetaRad), r * math.sin(thetaRad)
	end
	--- Convert r-theta coordinates (heading) to the equivalent x-y coordinates.
	-- @tparam rtheta rtheta The coordinate (heading) to convert.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyFromRadialHeading(...)
		local r, thetaHeading = getargs("xyFromRadialHeading", "rtheta")(...)
		local thetaRad = vector.radFromHeading(thetaHeading)
		return r * math.cos(thetaRad), r * math.sin(thetaRad)
	end

	--- Convert x-y coordinates to the equivalent r-theta coordinates (rad).
	-- @tparam xy xy The coordinate to convert.
	-- @treturn number The r coordinate of the result.
	-- @treturn number The theta coordinate (rad) of the result.
	function vector.radialRadFromXY(...)
		local x, y = getargs("radialRadFromXY", "xy")(...)
		return math.sqrt(x^2 + y^2), math.atan(y, x)
	end
	--- Convert x-y coordinates to the equivalent r-theta coordinates (deg).
	-- @tparam xy xy The coordinate to convert.
	-- @treturn number The r coordinate of the result.
	-- @treturn number The theta coordinate (deg) of the result.
	function vector.radialDegFromXY(...)
		local x, y = getargs("radialDegFromXY", "xy")(...)
		return math.sqrt(x^2 + y^2), vector.degFromRad(math.atan(y, x))
	end
	--- Convert x-y coordinates to the equivalent r-theta coordinates (heading).
	-- @tparam xy xy The coordinate to convert.
	-- @treturn number The r coordinate of the result.
	-- @treturn number The theta coordinate (heading) of the result.
	function vector.radialHeadingFromXY(...)
		local x, y = getargs("radialHeadingFromXY", "xy")(...)
		return math.sqrt(x^2 + y^2), vector.canonicalDeg(90 + vector.degFromRad(math.atan(y, x)))
	end
end

do -- Point/vector operations

	--- Rotate a vector clockwise by an angle.
	-- @tparam xy xy The vector to rotate.
	-- @tparam number rad The angle (rad) to rotate by.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyRotateRad(...)
		local x, y, thetaRad = getargs("xyRotateRad", "xy", "number")(...)
		return x * math.cos(thetaRad) + y * math.sin(thetaRad),
		       y * math.cos(thetaRad) - x * math.sin(thetaRad)
	end
	--- Rotate a vector clockwise by an angle.
	-- @tparam xy xy The vector to rotate.
	-- @tparam number deg The angle (deg) to rotate by.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyRotateDeg(...)
		local x, y, thetaDeg = getargs("xyRotateDeg", "xy", "number")(...)
		local thetaRad = vector.radFromDeg(thetaDeg)
		return x * math.cos(thetaRad) + y * math.sin(thetaRad),
		       y * math.cos(thetaRad) - x * math.sin(thetaRad)
	end

	--- Add two vectors.
	-- @tparam xy v1 The first vector.
	-- @tparam xy v2 The second vector.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyAdd(...)
		local x1, y1, x2, y2 = getargs("xyAdd", "xy", "xy")(...)
		return x1 + x2, y1 + y2
	end

	--- Multiply a vector by a scalar.
	-- @tparam xy v The vector.
	-- @tparam number s The number to multiply by.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyMul(...)
		local x, y, s = getargs("xyAdd", "xy", "number")(...)
		return x * s, y * s
	end

	--- Normalise a vector.
	-- @tparam xy v The vector.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xyNormalise(...)
		local x, y = getargs("xyNormalise", "xy")(...)
		local m = math.sqrt(x^2 + y^2)
		if m == 0 then
			error("zero-length vector passed to normalise()", 2)
		end
		return x / m, y / m
	end

	--- Calculate the length of a vector.
	-- @tparam xy v The vector.
	-- @treturn number The length of the vector.
	function vector.xyLength(...)
		local x, y = getargs("xyLength", "xy")(...)
		return math.sqrt(x^2 + y^2)
	end

	--- Subtract a vector from another, or find the vector between two points.
	-- @tparam xy v1 The vector to subtract from, or the target point.
	-- @tparam xy v2 The vector to subtract, or the start point.
	-- @treturn number The x coordinate of the result.
	-- @treturn number The y coordinate of the result.
	function vector.xySub(...)
		local x1, y1, x2, y2 = getargs("xySub", "xy", "xy")(...)
		return x1 - x2, y1 - y2
	end

	--- Get the distance between two points.
	-- @tparam xy p1 The first point.
	-- @tparam xy p2 The second point.
	-- @treturn number The distance between the points.
	function vector.distance(...)
		local x1, y1, x2, y2 = getargs("distance", "xy", "xy")(...)

		return math.sqrt((x1-x2)^2 + (y1-y2)^2)
	end

	--- Floor the elements of a vector.
	-- @tparam xy xy The vector to floor.
	-- @treturn integer The x coordinate of the result.
	-- @treturn integer The y coordinate of the result.
	function vector.xyFloor(...)
		local x, y = getargs("xyFloor", "xy")(...)
		return math.floor(x), math.floor(y)
	end
end
