-- Module: gn32/require
-- Description: Provide `require` behaviour closer to standard Lua

if _LOADED then return end
_LOADED = {}
local orig_require = require
function require(lib)
	if _LOADED[lib] then return end
	_LOADED[lib] = true

	if not string.find(lib, ".lua", -4) then
		lib = lib .. ".lua"
	end
	orig_require(lib)
end
