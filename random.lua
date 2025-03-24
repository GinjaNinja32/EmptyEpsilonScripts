--- Seedable RNG and helper functions.
-- @pragma nostrip

require "gn32/lang"

--- Return a random integer between min and max, inclusive.
-- This function matches the behaviour of the standard EmptyEpsilon `irandom` function, but uses the seedable RNG provided by this module.
-- @function irandom
-- @tparam integer min The minimum value to generate.
-- @tparam integer max The maximum value to generate.
-- @return a random integer within the provided range.
G.irandom = math.random

--- Return a random number between min and max, inclusive.
-- This function matches the behaviour of the standard EmptyEpsilon `random` function, but uses the seedable RNG provided by this module.
-- @function random
-- @tparam number min The minimum value to generate.
-- @tparam number max The maximum value to generate.
-- @return a random number within the provided range.
local _ = {}

G.random = setmetatable({}, {
	__call = function(_, min, max)
		return min + math.random() * (max - min)
	end,
})

--- Seed the RNG.
-- @function random.seed
-- @tparam integer seed The seed to set.
random.seed = math.randomseed

--- Generate a random seed for the RNG.
-- @function random.genseed
-- @return A seed suitable for passing to `random.seed`.
function random.genseed()
	return math.random(0, 0x100000000)
end

--- Return `true` with probability `n`%, otherwise return `false`.
-- @tparam integer n The probability to return `true`.
-- @treturn boolean `true`, `n`% of the time; otherwise `false`.
function random.prob(n)
	return math.random(1, 100) <= n
end

--- Select one option uniformly from the provided list.
-- @param ... The options to select from, or a single table argument containing the options to select from.
-- @return a random entry from the provided list.
function random.choice(...)
	local opts = {...}
	if #opts == 1 then opts = opts[1] end

	return opts[irandom(1, #opts)]
end
--- Select and remove one option uniformly from the provided list.
-- @tparam table opts A table to select and remove an entry from.
-- @return a random entry from the provided list.
function random.removeChoice(opts)
	local n = irandom(1, #opts)
	local v = opts[n]
	table.remove(opts, n)
	return v
end

local function unpackComparator(a, b)
	local ta = type(a)
	local tb = type(b)

	if ta ~= tb then
		return ta < tb
	end

	if ta ~= "table" then
		return a < b
	end

	if #a ~= #b then
		return #a < #b
	end

	for i = 1, #a do
		if a[i] ~= b[i] then
			return unpackComparator(a[i], b[i])
		end
	end

	return false
end

--- Select one option from the keys of opts, with weight according to the values.
--
-- Passing `opts` = `{ x=1, y=2, [{"z", 42}]=4 }` will return:
--
-- - with probability 1/7, `"x"`
-- - with probability 2/7, `"y"`
-- - with probability 4/7, either `"z", 42` (raw=false) or `{"z", 42}` (raw=true)
-- @tparam table opts The options to select from.
-- @tparam[opt=false] boolean raw Whether to return table results without unpacking.
-- @return a random key from the provided list.
function random.weighted(opts, raw)
	local copts = {}
	local sum = 0

	local optsList = {}
	for opt in pairs(opts) do
		table.insert(optsList, opt)
	end
	table.sort(optsList, unpackComparator)

	if #optsList == 0 then
		error("no options", 2)
	end

	for _, opt in ipairs(optsList) do
		local weight = opts[opt]
		if type(weight) ~= "number" then error("non-number weight", 2) end
		sum = sum + weight
		table.insert(copts, {sum = sum, opt = opt})
	end

	local choice = math.random() * sum

	for _, e in ipairs(copts) do
		if e.sum >= choice then
			if raw or type(e.opt) ~= "table" then
				return e.opt
			end
			return table.unpack(e.opt)
		end
	end

	error("random.weighted failed to pick an option")
end
--- Select and remove one option from the keys of opts, with weight according to the values.
-- For the interpretation of `opts`, see `random.weighted`.
-- @tparam table opts The options to select from.
-- @tparam[opt=false] boolean raw Whether to unpack table results (false) or not (true).
-- @return a random key from the provided list.
function random.removeWeighted(opts, raw)
	local sel = random.weighted(opts, true)
	opts[sel] = nil
	if raw or type(sel) ~= "table" then
		return sel
	end
	return table.unpack(sel)
end

--- Select one option from opts, either as a list or as a table of value-weight pairs depending on opts.
-- If all keys in opts are consecutive integers, then this function behaves as `random.choice`.
-- Otherwise, it behaves as `random.weighted`.
function random.select(opts)
	local n = #opts
	for k in pairs(opts) do
		if type(k) ~= "number" or k > n then
			return random.weighted(opts)
		end
	end
	return random.choice(opts)
end

--- Combine a skew factor with a list of options to produce a weighted set of options.
-- @tparam number skew The skew amount to apply. Positive numbers bias the results towards higher indexes; negative numbers have the same effect towards lower ones.
-- @tparam table opts The list of options to apply the skew factor to.
-- @tparam[opt=0.0] number middle The middle-bias to apply. Positive numbers bias the results towards the middle of the list; negative numbers have the same effect towards the ends.
-- @treturn table A table suitable for passing to `random.weighted`.
function random.skewToWeights(skew, opts, middle)
	local spow = math.exp(skew)
	local mpow = math.exp(middle or 0.0)

	local bounds = {}
	for i = 2, #opts do
		table.insert(bounds, (i-1)/#opts)
	end

	for i, b in ipairs(bounds) do
		local q
		if spow > 1 then
			q = b ^ spow
		else
			q = 1 - (1 - b) ^ (1 / spow)
		end

		if q < 0.5 then
			q = (q*2)^mpow/2
		else
			q = 1-(((1-q)*2)^mpow/2)
		end

		bounds[i] = q
	end

	bounds[0] = 0
	bounds[#opts] = 1

	local w = {}

	for i, opt in ipairs(opts) do
		w[opt] = bounds[i] - bounds[i-1]
	end

	return w
end
