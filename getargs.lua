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
	for i, defid in ipairs(defids) do
		if i ~= 1 or defid ~= "self" then
			table.insert(expect, defid)
		end
	end

	return ("%s(%s)"):format(fname, table.concat(expect, ", "))
end

local function formatActual(defids, args)
	local lenN = #args
	for i = 20, 1, -1 do
		if lenN >= i then
			break
		elseif args[i] ~= nil then
			lenN = i
			break
		end
	end

	local off = 0
	if defids[1] == "self" then
		off = 1
	end

	local strs = {}
	for i = 1, lenN - off do
		strs[i] = tostring(args[i + off])
	end
	return ("(%s)"):format(table.concat(strs, ", "))
end

local function parse(fname, defids, defs, err_n, ...)
	local args = {...}
	local nargs = #args
	local res = {}
	local rcur = 1

	local ncur = 1
	local noff = 0
	if defids[1] == "self" then
		noff = 1
	end
	for _, def in ipairs(defs) do
		local r = {def(ncur, args)}
		if not r[1] then
			error(("%s: bad args %s: at argument %d: %s"):format(formatExpected(fname, defids), formatActual(defids, args), ncur-noff, r[2]), err_n)
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
		error(("%s: bad args %s: at argument %d: too many arguments"):format(formatExpected(fname, defids), formatActual(defids, args), ncur-noff), err_n)
	end

	return table.unpack(res, 1, rcur)
end

local function makeParser(fname, defids, defids_err_n, err_n)
	local defs = {}
	for i, def in ipairs(defids) do
		if not argtypes[def] then
			error(("no argument type %s defined"):format(def), defids_err_n+1)
		end
		defs[i] = argtypes[def]
	end

	return function(...)
		return parse(fname, defids, defs, err_n, ...)
	end
end

--- Get an argument parsing function for a set of argument types.
-- @function getargs
-- @tparam string fname The name of the function to parse arguments for.
-- @param ... The names of the argument types to parse.
-- @treturn function(...) A function to parse the arguments.
G.getargs = function(fname, ...)
	local p = makeParser(fname, {...}, 2, 3)
	return p
end

--- Get a function that parses its args then calls f.
-- `withargs(fname, args, fn)` is equivalent to `function(...) return fn(getargs(fname, table.unpack(args))(...)) end`
-- @function withargs
-- @tparam string fname The name of the function to parse arguments for.
-- @tparam table args The list of argument types to parse.
-- @treturn function(...) A function that parses its arguments then calls f with the parsed arguments.
G.withargs = function(fname, args, fn)
	local p = makeParser(fname, args, 2, 3)
	return function(...) return fn(p(...)) end
end
function G.withargsn(fname, args, err_n, fn)
	local p = makeParser(fname, args, 2, err_n+1)
	return function(...) return fn(p(...)) end
end

--- Argument Types
-- @section argtypes

--- Any value.
-- @table any
argtypes.any = function(n, args)
	return 1, 1, args[n]
end

--- Any non-nil value. If this argument type is the first entry in an argument list, it is counted as argument zero and hidden from standard display.
-- @table self
argtypes.self = function(n, args)
	if args[n] == nil then
		return nil, "missing self argument"
	end
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

		return nil, ("expected a %s"):format(ty)
	end
end

--- Any non-destroyed entity. On master, this is a SpaceObject; on ECS, an Entity.
-- @table entity
function argtypes.entity(n, args)
	if (type(args[n]) == "table" or type(args[n]) == "userdata") and args[n].isValid then
		if not args[n]:isValid() then
			return nil, "got a destroyed object"
		end
		return 1, 1, args[n]
	end

	return nil, "expected an entity"
end
