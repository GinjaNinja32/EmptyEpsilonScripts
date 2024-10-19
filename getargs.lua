--- Utility for parsing arguments in various ways.

require "gn32/lang"

--- A map of defined argument types. Assign a `function(n, args)` to `argtypes.NAME` to define a new type.
-- For details of the required API, see `argtypes.NAME`.
-- @table argtypes
G.argtypes = {}

--- Assign or read to set or get a defined argument type.
-- Replace "NAME" with the name of an argument type, such as `number` or `entity`.
-- The signature and definition here defines the API for functions assigned into the `argtypes` table.
-- @function argtypes.NAME
-- @tparam number n The current argument index to parse (`args[n]`).
-- @tparam table args The input arguments being parsed.
-- @return The number of arguments to consume from the input, or nil if there was an error.
-- @return The number of arguments to add to the output, a table containing the arguments to add to the output, or a string error message if there was an error.
-- @return ... The arguments to add to the output, if they were not returned in a table.

local function formatExpected(fname, defids)
	local expect = {}
	for _, defid in ipairs(defids) do
		table.insert(expect, defid)
	end

	return ("%s(%s)"):format(fname, table.concat(expect, ", "))
end

local function parse(fname, defids, ...)
	local args = {...}
	local nargs = #args
	local res = {}
	local rcur = 1

	local ncur = 1
	for _, defid in ipairs(defids) do
		if not argtypes[defid] then
			error(("no argument type %s defined"):format(defid), 2)
		end

		local r = {argtypes[defid](ncur, args)}
		if not r[1] then
			error(("%s: bad args: %s"):format(formatExpected(fname, defids), r[2]), 3)
		end
		ncur = ncur + r[1]

		local rcount = r[2]
		local rtbl = r
		local rbase = 2
		if type(rcount) ~= "number" then
			rcount = #rcount
			rtbl = r[2]
			rbase = 0
		end
		for i = 1, rcount do
			res[rcur] = rtbl[rbase + i]
			rcur = rcur + 1
		end
	end

	if ncur < nargs + 1 then
		error(("%s: too many arguments"):format(formatExpected(fname, defids)), 3)
	end

	return table.unpack(res, 1, rcur)
end

--- Get an argument parsing function for a set of argument types.
-- @function getargs
-- @tparam string fname The name of the function to parse arguments for.
-- @param ... The names of the argument types to parse.
-- @treturn function(...) A function to parse the arguments.
G.getargs = function(fname, ...)
	local args = {...}
	return function(...)
		return parse(fname, args, ...)
	end
end

--- Argument Types
-- @section argtypes

--- Any value.
-- @table any
argtypes.any = function(n, args)
	return 1, 1, args[n]
end

--- Any number value.
-- @table number

--- Any string value.
-- @table string

--- Any boolean value.
-- @table boolean

--- Any table value.
-- @table table

--- Any userdata value.
-- @table userdata

for _, ty in ipairs{"number", "string", "boolean", "table", "userdata"} do
	argtypes[ty] = function(n, args)
		if type(args[n]) == ty then
			return 1, 1, args[n]
		end

		return nil, ("expected argument %d to be a %s"):format(n, ty)
	end
end

--- Any non-destroyed entity. On master, this is a SpaceObject; on ECS, an Entity.
-- @table entity
function argtypes.entity(n, args)
	if (type(args[n]) == "table" or type(args[n]) == "userdata") and args[n].isValid then
		if not args[n]:isValid() then
			return nil, ("argument %d is a destroyed object"):format(n)
		end
		return 1, 1, args[n]
	end

	return nil, ("expected argument %d to be an entity"):format(n)
end
