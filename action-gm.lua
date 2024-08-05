-- Module: gn32/action-gm
-- Description: Adds an `action`-driven GM menu
--[[
	For details of the menu item format, see `action`.

	Target arguments: (none)
	Differences from `action` docs:
		- 'info' entries are not fully supported; they will be displayed as buttons with a '*' prefix.

	To add a GM button:
		gmMenu:add {
			button = "Button Name",
			action = function(reopen) ... end,
		}
]]

require "gn32/lang"

require "gn32/action"
require "gn32/hook-sys"

-- Menu implementation

local data = {
	currentEntries = {},
}

G.gmMenu = ActionBase {
	_dataFor = function(self)
		return data
	end,
	_startMenu = function(self)
		for _, e in ipairs(data.currentEntries) do
			removeGMFunction(e)
		end
		data.currentEntries = {}
	end,
	_finishMenu = function(self) end,
	_addButton = function(self, button, order, act)
		addGMFunction(button, act)
		table.insert(data.currentEntries, button)
	end,
	_addInfo = function(self, info, order)
		addGMFunction("*" .. info, function() local _ = print end)
		table.insert(data.currentEntries, "*" .. info)
	end,
}()

hook.every[1] = function()
	gmMenu:refreshMenu()
end

-- Predefined entries

local function onoff(t)
	if t == true then
		return "On"
	elseif t == false then
		return "Off"
	else
		return "Default"
	end
end

gmMenu:add {
	button = "Debug Toggles",
	action = function(reopen)
		local menu = {
			{
				button = "Global: " .. onoff(debug.global),
				action = function() debug.global = not debug.global; return false end,
			}
		}

		local cats = {}
		for cat in pairs(debug.cats) do
			table.insert(cats, cat)
		end
		table.sort(cats)

		for _, cat in ipairs(cats) do
			table.insert(menu, {
				button = cat .. ": " .. onoff(rawget(debug.enabled, cat)),
				action = function()
					local cur = rawget(debug.enabled, cat)
					if cur == true then
						debug.enabled[cat] = false
					elseif cur == false then
						debug.enabled[cat] = nil
					else
						debug.enabled[cat] = true
					end
					return false
				end,
			})
		end

		return menu
	end
}
