--- Utility for creating class-like objects with separate sets of static and instance functions.
-- @alias G

require "gn32/lang"

--- Create a new class type.
-- @return A table for static class methods.
-- @return A table for class instance methods.
-- @return The metatable for class instances.
function G.makeClass()
	local static = {}
	local instance = {}
	local instance_mt = {
		__index = instance
	}

	local static_mt = {
		__call = function(_, ...)
			local obj = setmetatable({}, instance_mt)

			if type(obj._init) == "function" then
				obj:_init(...)
			end

			return obj
		end,
	}

	setmetatable(static, static_mt)

	static._instance = instance

	return static, instance, instance_mt
end

--- Create a new class type derived from another type.
-- @param parent The static method table for the parent type.
-- @return A table for static class methods.
-- @return A table for class instance methods.
-- @return The metatable for class instances.
function G.deriveClass(parent)
	local s, i, imt = makeClass()

	getmetatable(s).__index = parent
	setmetatable(i, {
		__index = parent._instance
	})

	return s, i, imt
end
