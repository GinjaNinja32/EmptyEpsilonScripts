G.vector = {}

function vector.radFromDeg(deg)
	return math.pi * deg / 180
end
function vector.degFromRad(rad)
	return 180 * rad / math.pi
end

function vector.xyFromRadial(r, theta)
	return r * math.cos(theta), r * math.sin(theta)
end
function vector.xyFromRadialDeg(r, theta)
	return vector.xyFromRadial(r, vector.radFromDeg(theta))
end

function vector.radialFromXY(x, y)
	return math.sqrt(x^2 + y^2), math.atan(y, x)
end
