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
