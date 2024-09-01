--- Provide `require` behaviour closer to standard Lua.
-- Differences from standard EE `require`:
--
-- - Modules do not require a `.lua` suffix; the suffix is still permitted.
-- - Modules that are `require`d multiple times will only be executed the first time.

if _LOADED then return end
_LOADED = {}
local modules = {}
local orig_require = require
function require(lib)
	if _LOADED[lib] then return modules[lib] end
	_LOADED[lib] = true

	if not string.find(lib, ".lua", -4) then
		lib = lib .. ".lua"
	end
	modules[lib] = orig_require(lib)
	return modules[lib]
end
