-- Module: gn32/lang-strict
-- Description: Makes language changes to make programming safer and easier.
--[[
	Changes:

	- Global variables must now be declared to be used. This is achieved by assigning to G.<varname> instead of just <varname>. Once declared, the variable can be accessed by <varname> as normal.
]]

local declared = {}

G = setmetatable({}, {
	__index = function(_, var)
		return rawget(_G, var)
	end,
	__newindex = function(_, var, value)
		declared[var] = true -- in case it gets set to nil
		rawset(_G, var, value)
	end,
})

local function ensuremetatable(tbl)
	local mt = getmetatable(tbl)
	if mt ~= nil then return mt end

	mt = {}
	setmetatable(tbl, mt)
	return mt
end

local mt = ensuremetatable(_G)
local old_idx = mt.__index
local _type = type
local _error = error
mt.__index = function(t, var)
	-- we're in the __index handler for _G. ensure we can't accidentally call ourselves
	local _G = nil
	local _ENV = nil

	if declared[var] then
		return nil
	end

	if old_idx then -- running inside EE
		local v
		if _type(old_idx) == "function" then
			v = old_idx(t, var)
		else
			v = old_idx[var]
		end
		if v ~= nil then return v end
	end
	_error("attempt to read undeclared variable "..var, 2)
end
mt.__newindex = function(_, var, value)
	if declared[var] then
		rawset(_G, var, value)
	else
		error("attempt to write to undeclared variable "..var.."; to declare a new global, assign to G."..var.." instead", 2)
	end
end
