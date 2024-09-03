--- Enables writing schemas and enforcing their validity on tables.
-- @pragma nostrip

--- Schema Kinds.
-- Schemas are represented as tables. The permitted keys and values of these tables are documented in the specific schema kinds below.
-- @section schemas

--- A schema enforceable against a value of type `"table"`.
--
-- Keys in the table correspond to keys of the target table.  
-- Values in the table are [`valueSchemas`](#valueSchema).
-- @table tableSchema

--- A schema enforceable against a value of any type.
-- @field[opt] _default The default value if no value is provided. If a function, it will be invoked each time a default is required.
-- @field[opt] _type The type that the value must have: `type(val) == _type`
-- @field[opt] _min The minimum value: `val >= _min`
-- @field[opt] _max The maximum value: `val <= _max`
-- @field[opt] _check A function to check each value: `local v = _check(val); v == nil or v == true`
-- @field[opt] _fields A `tableSchema` for the value, if it is a table.
-- @table valueSchema
local _ = {}

require "gn32/lang"

G.schema = {}

-- Unique tables only used to index schema table instances.
local dataIndex = {}
local pathIndex = {}

--- Functions.
-- @section functions

--- Check that a table satisfies a `tableSchema`.
-- @param tbl The table to check.
-- @param sch The `tableSchema` to validate against.
function schema.checkTable(tbl, sch)
	for key in pairs(tbl) do
		if not sch[key] then
			return key .. ": field not defined"
		end
	end

	for key, field in pairs(sch) do
		local err = schema.checkValue(tbl[key], field)
		if err then
			return key .. ": " .. err
		end
	end
end

--- Check that a value satisfies a `valueSchema`.
-- @param val The value to check.
-- @param sch The `valueSchema` to validate against.
-- @param norecurse If set to true, ignore any `_fields` set in the schema.
function schema.checkValue(val, sch, norecurse)
	if val == nil then
		val = sch._default
		if type(val) == "function" then
			val = val()
		end
	end

	if sch._type ~= nil and sch._type ~= type(val) then
		return ("bad type %s: expected %s"):format(type(val), sch._type)
	end

	if sch._min ~= nil and sch._min > val then
		return ("bad value %s: expected value >= %s"):format(tostring(val), tostring(sch._min))
	end

	if sch._max ~= nil and sch._max < val then
		return ("bad value %s: expected value <= %s"):format(tostring(val), tostring(sch._max))
	end

	if sch._check ~= nil then
		local e = sch._check(val)
		if e ~= true and e ~= nil then
			return ("bad value %s: %s"):format(tostring(val), tostring(e))
		end
	end

	if not norecurse and sch._fields and type(val) == "table" then
		return schema.checkTable(val, sch._fields)
	end
end

local mtCache = setmetatable({}, {__type="k"})

local function getSchemaMetatable(sch)
	if not mtCache[sch] then
		mtCache[sch] = {
			__index = function(tbl, k)
				local s = sch[k]
				if s == nil then
					error(("%s%s: field not defined"):format(tbl[pathIndex], k), 2)
				end

				return tbl[dataIndex][k]
			end,
			__newindex = function(tbl, k, v)
				local s = sch[k]
				if s == nil then
					error(("%s%s: field not defined"):format(tbl[pathIndex], k), 2)
				end
				local e = schema.checkValue(v, s, true)
				if e ~= nil then
					error(("%s%s: %s"):format(tbl[pathIndex], k, e), 2)
				end

				if type(v) == "table" and s._fields then
					local t = schema.makeTable(s._fields, ("%s%s."):format(tbl[pathIndex], k))

					local ok, e = pcall(function()
						for vk, vv in pairs(v) do
							t[vk] = vv
						end
					end)
					if not ok then
						error(("%s%s: %s"):format(tbl[pathIndex], k, e), 2)
					end

					local e = schema.checkTable(t, s._fields)
					if e ~= nil then
						error(("%s%s: %s"):format(tbl[pathIndex], k, e), 2)
					end

					tbl[dataIndex][k] = t
				else
					tbl[dataIndex][k] = v
				end
			end,
			__pairs = function()
				return next, {}, nil
			end,
			__metatable = "schema",
		}
	end

	return mtCache[sch]
end

--- Make a table that enforces the given `tableSchema` on edits.
-- The table may or may not initially satisfy the schema, depending on the default field values specified by the schema.
-- @param sch The `tableSchema` to enforce.
-- @param path The path to this table, for error messages. Empty or `nil` if this is a top-level table.
function schema.makeTable(sch, path)
	local data = {}

	for k, s in pairs(sch) do
		if s._default then
			local v = s._default
			if type(v) == "function" then
				v = v()
			end
			if type(v) == "table" and s._fields then
				local t = schema.makeTable(s._fields, ("%s%s."):format(path, k))
				for vk, vv in pairs(v) do
					t[vk] = vv
				end

				data[k] = t
			else
				data[k] = v
			end
		end
	end

	return setmetatable({
		[dataIndex] = data,
		[pathIndex] = path or "",
	}, getSchemaMetatable(sch))
end
