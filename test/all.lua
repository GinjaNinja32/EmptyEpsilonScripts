if _included then return end
_included = true

local tests = io.popen("ls gn32/test/*.lua")
for filename in tests:lines() do
	require(filename:sub(1, -5))
end

os.exit(testcode)
