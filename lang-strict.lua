--- Makes language changes to make programming safer and easier.
-- Changes:
--
-- - Global variables must now be declared to be used. This is achieved by assigning to `G.<varname>` instead of just `<varname>`.
--   Once declared, the variable can be accessed by `<varname>` as normal, even if set to nil.

local declared = {}

local function ensuremetatable(tbl)
	local mt = getmetatable(tbl)
	if mt ~= nil then return mt end

	mt = {}
	setmetatable(tbl, mt)
	return mt
end

local mt = ensuremetatable(_G)
local old_idx = mt.__index
local get_old_idx = function(t, k)
	if type(old_idx) == "function" then
		return old_idx(t, k)
	else
		return old_idx[k]
	end
end

local _error = error
mt.__index = function(t, var)
	-- we're in the __index handler for _G. ensure we can't accidentally call ourselves
	local _G = nil
	local _ENV = nil

	if declared[var] then -- if the var was declared but we still ended up here, it was set to nil
		return nil
	end

	if old_idx then -- if we're running inside EE, check the parent environment and use its value if present
		local v = get_old_idx(t, var)
		if v ~= nil then return v end
	end
	_error("attempt to read undeclared variable "..var, 2)
end
mt.__newindex = function(t, var, value)
	if declared[var] then
		rawset(_G, var, value)
	else
		if old_idx then -- if we're running inside EE, we should allow overwriting EE's vars without specifying G.foo
			local v = get_old_idx(t, var)
			if v ~= nil then
				declared[var] = true
				rawset(_G, var, value)
				return
			end
		end
		error("attempt to write to undeclared variable "..var.."; to declare a new global, assign to G."..var.." instead", 2)
	end
end

rawset(_G, "G", setmetatable({}, {
	__index = function(t, var)
		local v = rawget(_G, var)
		if v ~= nil or declared[var] then
			return v
		end
		if old_idx then
			return get_old_idx(t, var)
		end
	end,
	__newindex = function(_, var, value)
		declared[var] = true -- in case it gets set to nil
		rawset(_G, var, value)
	end,
}))
