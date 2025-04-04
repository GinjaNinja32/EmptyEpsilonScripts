--- Standard library extensions.
-- @alias G

--- table.
-- @section table

--- Create a defaulting table, which returns a default value when indexed with a key that does not exist.
-- @param f The function to default values in the table to.
-- @param nostore Optional; if true, the constructed value is only returned from the index operation, and not stored in the table.
-- @return The constructed table.
function table.defaulting(f, nostore)
	return setmetatable({}, {
		__index = function(tbl, idx)
			if idx == nil then error("nil index", 2) end
			local v = f()
			if not nostore then
				tbl[idx] = v
			end
			return v
		end
	})
end

--- Check whether a table contains an entry.
-- @param tbl The table to check for.
-- @param entry The entry to check for.
-- @return `true` if there is some index `i` between 1 and `#tbl` such that `tbl[i] == entry`, otherwise `false`.
function table.contains(tbl, entry)
	return table.indexOf(tbl, entry) ~= nil
end

--- Find the index of an entry in a table.
-- @tparam table tbl The table to search.
-- @param entry The entry to find.
-- @return The index of `entry` in `table`, or nil if it is not present.
function table.indexOf(tbl, entry)
	for i = 1, #tbl do
		if tbl[i] == entry then
			return i
		end
	end
end

--- Merge multiple list-like tables into one new table.
-- @param ... The tables to merge.
-- @treturn table The merged table.
function table.mergeLists(...)
	local out = {}
	local i = 1
	for _, t in ipairs{...} do
		local l = #t
		table.move(t, 1, l, i, out)
		i = i + l
	end
	return out
end

--- global.
-- @section global

--- Call a function, or call an error handler with the raised error.
-- @param errorhandler The function to call if `f` throws an error. Errors in this function are not caught.
-- @param f The function to call.
-- @param ... The arguments to pass to the function.
-- @return `f(...)` if that call does not throw an error, otherwise `errorhandler(err, ...)`.
function G.safecall(errorhandler, f, ...)
	local args = {...}
	local ret
	local ok, err = pcall(function()
		ret = table.pack(f(table.unpack(args)))
	end)
	if ok then
		return table.unpack(ret)
	else
		return errorhandler(err, ...)
	end
end

--- string.
-- @section string

--- The options accepted by `string.title`.
-- @table titleopts
-- @tfield[opt="^%p%s"] string wchar The set of characters to consider as word characters; the default is any non-punctuation non-space character. See [the Lua manual's patterns section](https://www.lua.org/manual/5.4/manual.html#6.4.1) for details on character sets; the value will be placed in `[]` for use as a character class.
-- @tfield[opt=string.lower] function lower The function to lowercase the input.
-- @tfield[opt=string.upper] function upper The function to uppercase the input.

--- Return a copy of the input string with all words changed to title case.
-- Word characters immediately preceded by a non-word character or the start of the string will be uppercased; all other characters will be lowercased.
-- @tparam string s The string to titlecase.
-- @tparam[opt] titleopts opts The options to use.
-- @treturn string The string with all words changed to title case.
function string.title(s, opts)
	opts = opts or {}
	local wchar = opts.wchar or "^%p%s"
	local upper = opts.upper or string.upper
	local lower = opts.lower or string.lower

	return (
		string.gsub(
			upper(string.sub(s, 1, 1)) -- Uppercase first char.
			.. lower(string.sub(s, 2)), -- Lowercase the rest.
			"%f["..wchar.."]["..wchar.."]", -- Word after non-word...
			upper -- get uppercased if applicable.
		)
	)
end

--- Split a string by a separator.
-- @tparam string s The string to split.
-- @tparam string sep The pattern to split on.
-- @tparam[opt] integer n The maximum number of times to split the string, or zero/nil for unlimited.
-- @treturn table A list of all substrings between the separators, including leading/trailing empty strings if the original string contained leading/trailing separators.
function string.split(s, sep, n)
	n = n or 0

	local t = {}
	local i = 1
	repeat
		local start, _end = string.find(s, sep, i)

		if start then
			table.insert(t, string.sub(s, i, start-1))
			i = _end+1
			n = n - 1
		end
	until not start or n == 0
	table.insert(t, string.sub(s, i))
	return t
end
