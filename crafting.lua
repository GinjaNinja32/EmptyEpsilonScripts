--- [`action-main`] Adds functionality for player-facing crafting menus.
-- By default, adds a menu named "Build..." that fetches entries from `ship.buildable`.
-- @pragma nostrip

--- Recipe format.
-- @section recipeformat

--- Recipe table format.
-- @table recipe
-- @field[opt] stations A list of stations that can build the recipe. If not present, all stations can build the recipe.
-- @field[opt] action The displayed action to build the recipe. If not present, the default action for the menu is used.
-- @field name The name of the recipe.
-- @field[opt] take An `exchange` resource list containing the resources required to build the recipe.
-- @field[opt] add An `exchange` resource list containing the resources resulting from building the recipe.
-- @field[opt] time The time required to build the recipe.
-- @field[opt] multi Whether more than one of this recipe can be built at once.
local _ = {}

require "gn32/lang"

require "gn32/action-main"
require "gn32/exchange"

local function couldBuild(b, station) -- could this recipe be built at any point by this station?
	if b.stations and not table.contains(b.stations, station) then
		return false
	end

	return true
end

local function canBuild(ship, b, count) -- can this recipe be built right now? if not, why not?
	return exchange.canSwap(ship, b.take or {}, b.add or {}, count)
end

local function tryComplete(ship, b, count, action) -- build this recipe, or explain why it can't be; return a menu list
	local ok, reason = canBuild(ship, b, count)
	if not ok then
		return {allowBack = false, {info = action .. " failed"}, {info = reason}}
	end

	exchange.swap(ship, b.take or {}, b.add or {}, count)
	return {allowBack = false, {info = action .. " Complete"}}
end

G.crafting = {}

--- Functions.
-- @section functions

--- Add a crafting menu to the main menu.
-- @see action-main
-- @param menuName The name of the menu.
-- @param actionName The default action for the menu.
-- @param getEntries A `function(ship)` that returns a list of entries to use for the menu.
function crafting.addMenu(...) -- add a crafting menu to the main menu. arguments as crafting.buildMenu
	mainMenu:add(crafting.buildMenu(...))
end

--- Builds a crafting menu for the main menu.
-- @see action-main
-- @param menuName The name of the menu.
-- @param actionName The default action for the menu.
-- @param getEntries A `function(ship)` that returns a list of entries to use for the menu.
function crafting.buildMenu(menuName, actionName, getEntries) -- build a crafting menu
	return {
		button = menuName,
		requiredTaskState = false,
		when = function(ship, station)
			local entries = getEntries(ship)

			if not entries then
				return false
			end

			for _, b in ipairs(entries) do
				if couldBuild(b, station) then
					return true
				end
			end

			return false
		end,
		action = function(reopen, ship, station)
			local menu = {}
			local entries = getEntries(ship)

			for _, b in ipairs(entries) do
				local action = b.action or actionName

				if couldBuild(b, station) then
					local ok, reason = canBuild(ship, b, 1)
					if not ok then
						table.insert(menu, {info = (b.action and b.action .. " " or "") .. b.name .. " (" .. reason .. ")"})
					else
						table.insert(menu, {
							button = (b.action and b.action .. " " or "") .. b.name,
							action = function(reopen, ship, station)
								local menu = {}

								table.insert(menu, {info = action .. " " .. b.name})

								if b.take then
									for _, e in ipairs(exchange.format(b.take)) do
										table.insert(menu, {info = e})
									end
								end
								if b.time then
									table.insert(menu, {info = tostring(b.time) .. "s"})
								end

								local function addOption(name, count)
									table.insert(menu, {
										button = name,
										action = function(reopen, ship, station)
											local t = {
												duration = (b.time or 0) * count,

												update = function()
													local ok, reason = canBuild(ship, b, count)
													if not ok then
														return reason
													end
												end,
												complete = function()
													return tryComplete(ship, b, count, action)
												end,
											}

											mainMenu:setTask(t, ship, station)

											if not b.time then
												return false
											end
										end,
									})
								end

								if b.multi then
									local maxBuildable, minUnbuildable
									for _, n in ipairs{1, 2, 5, 10, 20, 50} do
										if canBuild(ship, b, n) then
											maxBuildable = n

											local name = action .. " " .. n
											if not canBuild(ship, b, n+1) then
												name = action .. " Max (" .. n .. ")"
											end
											addOption(name, n)
										else
											minUnbuildable = n
											break
										end
									end

									if maxBuildable and minUnbuildable then
										for n = minUnbuildable-1, maxBuildable+1, -1 do
											if canBuild(ship, b, n) then
												addOption(action .. " Max (" .. n .. ")", n)
												break
											end
										end
									end
								else
									if canBuild(ship, b, 1) then addOption(action, 1) end
								end

								return menu
							end,
						})
					end
				end
			end

			return menu
		end,
	}
end

crafting.addMenu("Build...", "Build", function(ship) return ship.buildable end)
