--- Utility for adding hooks to functions.
-- @pragma nostrip

require "gn32/lang"

--- Assign a function to `fnhook.<name>` to hook the existing function `<name>`.
-- The assigned function will be called with the return values of the existing function, then those same return values will be returned to the caller.
-- @table fnhook
G.fnhook = setmetatable({}, {
	__newindex = function(_, key, fn)
		if type(G[key]) ~= "function" then
			error(key .. " is not a function", 2)
		end

		local old = _G[key]
		_G[key] = function()
			local e = {old()}

			fn(table.unpack(e))

			return table.unpack(e)
		end
	end,
})
