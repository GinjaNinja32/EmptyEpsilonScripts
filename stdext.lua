-- Module: gn32/stdext
-- Description: Standard library extensions


-- table.defaulting: returns a table which sets tbl[idx] = f() when indexed with a key that does not exist.
-- if `nostore` is true, the constructed value is only returned from the index operation, and not stored in the table.
function table.defaulting(f, nostore)
	return setmetatable({}, {
		__index = function(tbl, idx)
			local v = f()
			if not nostore then
				tbl[idx] = v
			end
			return v
		end
	})
end

-- table.contains: returns true if there is some index i between 1 and #tbl such that tbl[i] == entry, otherwise returns false.
function table.contains(tbl, entry)
	for i in 1, #tbl do
		if tbl[i] == entry then
			return true
		end
	end

	return false
end

-- safecall: return `f(...)` if it does not throw an error, otherwise return `errorhandler(err, ...)`.
-- errors in `errorhandler` are not caught.
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
