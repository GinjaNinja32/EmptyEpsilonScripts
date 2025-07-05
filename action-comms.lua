--- Adds an `action`-driven comms menu system.
-- This module uses `batteries/sort`.
-- For details of the menu item format, see `action`.
--
-- Target arguments: `source, target`  
-- Differences from `action` docs:
--
-- - `info` entries will be merged and used as the comms message.
-- - Menu items support a `requiredDockState` boolean; if set, the item will only display when the source is (`true`) or is not (`false`) docked with the target.
--
-- To create a comms menu, add entries to it, and set it as an entity's comms function:
--	local commsMenu = CommsMenu()
--	commsMenu:add {
--		info = "Comms Message",
--	}
--	commsMenu:add {
--		button = "Button Name",
--		action = function(reopen, source, target) ... end,
--	}
--	entity:setCommsFunction(commsMenu:getCommsFunction())

require "gn32/lang"

require "gn32/action"

require("batteries/sort"):export()

--- Create a new comms menu.  
-- CommsMenu is derived from `action.ActionBase` and inherits some instance functions from there.
-- @function CommsMenu
G.CommsMenu = ActionBase {
	_dataFor = function(self, source, target)
		if target.__comms == nil then target.__comms = {} end
		if target.__comms[source] == nil then target.__comms[source] = {} end
		return target.__comms[source]
	end,
	_startMenu = function(self, source, target)
		local data = self:_dataFor(source, target)
		data.message = {}
		data.button = nil
	end,
	_finishMenu = function(self, source, target)
		local data = self:_dataFor(source, target)
		if not data.button and not data.message then
			setCommsMessage("We have nothing for you.")
			return
		end
		if #data.message == 0 then
			setCommsMessage("[Menu Error]\nno message set")
			return
		end
		table.stable_sort(data.message, function(a, b) return a.order < b.order end)
		local s = {}
		for _, entry in ipairs(data.message) do
			table.insert(s, entry.msg)
		end
		setCommsMessage(table.concat(s, "\n"))
	end,
	_addButton = function(self, button, order, act, source, target)
		local data = self:_dataFor(source, target)
		data.button = true
		addCommsReply(button, act)
	end,
	_shouldShow = function(self, item, source, target)
		if item.requiredDockState ~= nil then
			local isDocked = source:isDocked(target)
			if item.requiredDockState ~= isDocked then
				return false
			end
		end

		return true
	end,
	_addInfo = function(self, info, order, source, target)
		local data = self:_dataFor(source, target)
		table.insert(data.message, {msg=info, order=order or 0})
	end,

	--- Get a comms function that will show this menu.
	-- @function commsMenu:getCommsFunction
	getCommsFunction = function(self)
		return function(comms_source, comms_target)
			local _ = print -- give SeriousProton the environment reference it wants
			self:setMenu(nil, comms_source, comms_target)
		end
	end,
}
