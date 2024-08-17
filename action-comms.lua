-- Module: gn32/action-comms
-- Description: Adds an `action`-driven comms menu system
--[[
	For details of the menu item format, see `action`.

	Target arguments: source, target
	Differences from `action` docs:
		- 'info' entries will be merged and used as the comms message.
		- Menu items support a `requiredDockState` bool; if set, the item will only display when the source is (true) or is not (false) docked with the target.

	To create a comms menu, add entries to it, and set it as an entity's comms function:
		local commsMenu = CommsMenu()
		commsMenu:add {
			info = "Comms Message",
		}
		commsMenu:add {
			button = "Button Name",
			action = function(reopen, source, target) ... end,
		}
		entity:setCommsFunction(commsMenu:getCommsFunction())
]]

require "gn32/lang"

require "gn32/action"

G.CommsMenu = ActionBase {
	_dataFor = function(self, source, target)
		if target.__comms == nil then target.__comms = {} end
		if target.__comms[source] == nil then target.__comms[source] = {} end
		return target.__comms[source]
	end,
	_startMenu = function(self, source, target)
		local data = self:_dataFor(source, target)
		data.message = nil
		data.button = nil
	end,
	_finishMenu = function(self, source, target)
		local data = self:_dataFor(source, target)
		if not data.button and not data.message then
			setCommsMessage("We have nothing for you.")
			return
		end
		setCommsMessage(data.message or "[Menu Error]\nno message set")
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
		if data.message then
			data.message = data.message .. "\n" .. info
		else
			data.message = info
		end
	end,

	getCommsFunction = function(self)
		return function(comms_source, comms_target)
			local _ = print -- give SeriousProton the environment reference it wants
			self:setMenu(nil, comms_source, comms_target)
		end
	end,
}
