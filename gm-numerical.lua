--- Helper to expose a tweakable numerical value in the GM menu.

local function approxEqual(a, b)
	-- within 1% of each other
	return math.abs(a - b) < (math.abs(a) + math.abs(b)) / 200
end

local function getBase(n)
	return 10 ^ math.floor(math.log(n, 10))
end

-- Move up to next power of 10
local function incrementBig(n)
	return 10 * getBase(n)
end

-- If between 1eX and 2eX, increment by 0.1eX, otherwise by 1eX
local function incrementSmall(n)
	local base = getBase(n)
	if n < 2 * base then
		return n + base / 10
	end
	return n + base
end

-- If between 1eX and 2eX, decrement by 0.1eX, otherwise by 1eX
local function decrementSmall(n)
	local base = getBase(n)
	if approxEqual(n, base) then
		return 9/10 * base
	end
	if n <= 2 * base then
		return n - base / 10
	end
	return n - base
end

-- Move down to next power of 10
local function decrementBig(n)
	local base = getBase(n)
	if approxEqual(n, base) then
		return base / 10
	end
	return base
end

--- Make a menu entry list containing operations on the given value.
-- @function makeNumericalOperations
-- @string name The name of the value
-- @param getValue A `function()` returning the current value as a number.
-- @param textValue A `function()` returning the current value as a string formatted for display, or `nil` to use `getValue`.
-- @param setValue A `function(value)` to set the value.
-- @param[opt=name] opPrefix The prefix to place before the name of operations to be performed on the value.
-- @return A menu entry list suitable for `action-gm`.
function G.makeNumericalOperations(name, getValue, textValue, setValue, opPrefix)
	if not textValue then textValue = getValue end
	if not opPrefix then opPrefix = name end

	return {
		{
			button = opPrefix .. "++",
			action = function()
				return setValue(incrementBig(getValue()))
			end,
		},
		{
			button = opPrefix .. "+",
			action = function()
				return setValue(incrementSmall(getValue()))
			end,
		},
		{
			button = function() return name .. ": " .. textValue() end,
			action = false,
		},
		{
			button = opPrefix .. "-",
			action = function()
				return setValue(decrementSmall(getValue()))
			end,
		},
		{
			button = opPrefix .. "--",
			action = function()
				return setValue(decrementBig(getValue()))
			end,
		},
	}
end
