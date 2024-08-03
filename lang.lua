-- Module: gn32/lang
-- Description: Compatibility module to auto-import gn32/lang-lax if no provider of gn32/lang has been imported yet.

if G == nil then
	require "gn32/lang-lax"
end
