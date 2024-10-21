--- Compatibility module to auto-import `lang-lax` if no provider of `lang` has been imported yet.

---

if G == nil then
	require "gn32/lang-lax"
end
