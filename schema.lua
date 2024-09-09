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
-- @field[opt] _ge Value must be greater than or equal to this value: `val >= _ge`
-- @field[opt] _gt Value must be greater than this value: `val > _gt`
-- @field[opt] _le Value must be less than or equal to this value: `val <= _le`
-- @field[opt] _lt Value must be less than this value: `val < _lt`
-- @field[opt] _check A function to check each value: `local v = _check(val); v == nil or v == true`
-- @field[opt] _fields A `tableSchema` for the value, if it is a table.
-- @field[opt] _keys A `valueSchema` for the keys of the value, if it is a table.
-- @field[opt] _values A `valueSchema` for the values of the value, if it is a table.
-- @table valueSchema
local _ = {}

require "gn32/lang"

G.schema = {}

-- Unique tables only used to index schema table instances.
local dataIndex = {}
local pathIndex = {}

--- Functions.
-- @section functions

local function describeValueBounds(sch)
	local min, max, minEq, maxEq

	if sch._ge ~= nil and (sch._gt == nil or sch._gt < sch._ge) then
		min = tostring(sch._ge)
		minEq = "="
	elseif sch._gt ~= nil then
		min = tostring(sch._gt)
		minEq = ""
	end

	if sch._le ~= nil and (sch._lt == nil or sch._lt > sch._le) then
		max = tostring(sch._le)
		maxEq = "="
	elseif sch._lt ~= nil then
		max = tostring(sch._lt)
		maxEq = ""
	end

	if max and min then
		return ("%s <%s value <%s %s"):format(min, minEq, maxEq, max)
	elseif max then
		return ("value <%s %s"):format(maxEq, max)
	elseif min then
		return ("value >%s %s"):format(minEq, min)
	else
		return "any value"
	end
end

--- Check that a value satisfies a `schema`.
-- @param val The value to check.
-- @param sch The `schema` to validate against.
function schema.checkValue(val, sch)
	if val == nil then
		val = sch._default
		if type(val) == "function" then
			val = val()
		end
	end

	if sch._type ~= nil and sch._type ~= type(val) then
		if val == nil then
			return ("field is required, expected %s"):format(sch._type)
		end

		return ("bad type %s: expected %s"):format(type(val), sch._type)
	end

	if sch._ge ~= nil and not (val >= sch._ge) then
		return ("bad value %s: expected %s"):format(tostring(val), describeValueBounds(sch))
	end

	if sch._gt ~= nil and not (val > sch._gt) then
		return ("bad value %s: expected %s"):format(tostring(val), describeValueBounds(sch))
	end

	if sch._le ~= nil and not (val <= sch._le) then
		return ("bad value %s: expected %s"):format(tostring(val), describeValueBounds(sch))
	end

	if sch._lt ~= nil and not (val < sch._lt) then
		return ("bad value %s: expected %s"):format(tostring(val), describeValueBounds(sch))
	end

	if sch._check ~= nil then
		local e = sch._check(val)
		if e ~= true and e ~= nil then
			return ("bad value %s: %s"):format(tostring(val), tostring(e))
		end
	end

	if type(val) == "table" then
		if sch._fields then
			for key in pairs(val) do
				if not sch._fields[key] then
					return key .. ": field not defined"
				end
			end

			for key, field in pairs(sch._fields) do
				local err = schema.checkValue(val[key], field)
				if err then
					return key .. ": " .. err
				end
			end
		elseif sch._keys or sch._values then
			for k, v in pairs(val) do
				if sch._keys then
					local e = schema.checkValue(k, sch._keys)
					if e ~= nil then return ("%s (key): %s"):format(k, e) end
				end
				if sch._values then
					local e = schema.checkValue(v, sch._values)
					if e ~= nil then return ("%s: %s"):format(tostring(k), e) end
				end
			end
		end
	end
end

local mtCache = setmetatable({}, {__type="k"})

local function getSchemaMetatable(sch)
	if not mtCache[sch] then
		mtCache[sch] = {
			__index = function(tbl, k)
				if sch._fields and not sch._fields[k] then
					error(("%s%s: field not defined"):format(tbl[pathIndex], k), 2)
				end

				local v = tbl[dataIndex][k]

				if v == nil and sch._values and sch._values._default then
					v = sch._values._default
					if type(v) == "function" then
						v = v()
					end
				end

				return v
			end,
			__newindex = function(tbl, k, v)
				if sch._fields and not sch._fields[k] then
					error(("%s%s: field not defined"):format(tbl[pathIndex], k), 2)
				end

				if sch._keys then
					local e = schema.checkValue(k, sch._keys)
					if e ~= nil then error(("%s%s (key): %s"):format(tbl[pathIndex], tostring(k), e), 2) end
				end
				if sch._values then
					local e = schema.checkValue(v, sch._values)
					if e ~= nil then error(("%s%s: %s"):format(tbl[pathIndex], tostring(k), e), 2) end
				end

				if type(v) == "table" then
					local subsch
					if sch._fields then
						subsch = sch._fields[k]
					else
						subsch = sch._values
					end

					if subsch._fields or subsch._keys or subsch._values then
						local t = schema.makeTable(subsch, ("%s%s."):format(tbl[pathIndex], k))

						local ok, e = pcall(function()
							for vk, vv in pairs(v) do
								t[vk] = vv
							end
						end)
						if not ok then
							error(e:gsub("^.?/?gn32/schema.lua:%d+: ", ""),  2)
						end

						v = t
					end
				end

				if sch._fields then
					local s = sch._fields[k]
					local e = schema.checkValue(v, s)
					if e ~= nil then
						error(("%s%s: %s"):format(tbl[pathIndex], k, e), 2)
					end
				end

				tbl[dataIndex][k] = v
			end,
			__pairs = function(tbl)
				if sch._fields then
					return next, {}, nil
				end
				local n = function(_, k)
					return next(tbl[dataIndex], k)
				end
				return n, {}, nil
			end,
			__metatable = "schema",
		}
	end

	return mtCache[sch]
end

--- Make a table that enforces the given `valueSchema` on edits.
-- The table may or may not initially satisfy the schema, depending on the default field values specified by the schema.
-- @param sch The `valueSchema` to enforce.
-- @param path The path to this table, for error messages. Empty or `nil` if this is a top-level table.
function schema.makeTable(sch, path)
	local data = {}

	-- if there's nothing to enforce, just give a regular table back
	if not sch or not sch._fields and not sch._keys and not sch._values then
		return {}
	end

	if sch._fields then
		for k, s in pairs(sch._fields) do
			if s._default then
				local v = s._default
				if type(v) == "function" then
					v = v()
				end
				if type(v) == "table" and s._fields then
					local t = schema.makeTable(s, ("%s%s."):format(path, k))
					for vk, vv in pairs(v) do
						t[vk] = vv
					end

					data[k] = t
				else
					data[k] = v
				end
			end
		end
	end

	return setmetatable({
		[dataIndex] = data,
		[pathIndex] = path or "",
	}, getSchemaMetatable(sch))
end
