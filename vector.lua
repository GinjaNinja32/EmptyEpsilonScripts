--- Vector/coordinate utilities.
-- @pragma nostrip

G.vector = {}

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
