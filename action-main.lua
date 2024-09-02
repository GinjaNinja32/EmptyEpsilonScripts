--- [`hook-sys`] Adds an `action`-driven crew position menu.
-- Required hooks: `update`, `newPlayerShip`.
-- This module uses `batteries/sort`.
--
-- For details of the menu item format, see `action`.
--
-- Target arguments: ship, station  
-- Differences from `action` docs:
--
-- - Menu items support a `stations` list; items will only be displayed on stations contained in the list. Items without a list will show on all stations.
-- - Menu items support a `requiredTaskState` bool; if set, the item will only display when there is (`true`) or is not (`false`) a task in progress.
-- 
-- To add a station button menu item:
--	mainMenu:add {
--		info = "Info Text",
--	}
--	mainMenu:add {
--		button = "Button Name",
--		action = function(reopen, ship, station) ... end,
--	}
--
-- To set the task that a station is working on:
--	mainMenu:setTask(task, ship, station)
--
-- Task structure:
--	{
--		-- Exactly one of the following two fields should be set.
--		-- The scenario time that the task will be complete at.
--		completionAt = 42,
--		-- The time that the task takes, in seconds.
--		duration = 42,
--
--		-- Update the task. This field is optional.
--		-- If `update` returns a non-nil value, it will be treated
--		-- as a failure to complete the task and displayed to the user.
--		update = function(ship, station) ... end,
--
--		-- Complete the task. This field is optional.
--		-- If `complete` returns a menu list, it will be used for
--		-- the 'task complete' menu.
--		complete = function(ship, station) ... end,
--	}
-- @alias G

require "gn32/lang"

require "gn32/action"
require "gn32/hook-sys"
require "gn32/position"
require "gn32/stdext"
require("batteries/sort"):export()

--- An instance of `action.ActionBase` that displays on crew consoles.
G.mainMenu = ActionBase {
	-- hook push/pop/reset to keep a scroll stack
	_onPush = function(self, ship, station)
		local data = self:_dataFor(ship, station)
		table.insert(data.scrollstack, data.offset)
		data.offset = 0
	end,
	_onPop = function(self, ship, station)
		local data = self:_dataFor(ship, station)
		data.offset = data.scrollstack[#data.scrollstack]
		data.scrollstack[#data.scrollstack] = nil
	end,
	_onReset = function(self, ship, station)
		local data = self:_dataFor(ship, station)
		data.offset = 0
		data.scrollstack = {}
	end,

	_shouldShow = function(self, item, ship, station)
		local data = self:_dataFor(ship, station)

		if item.stations and not table.contains(item.stations, station) then
			return false
		end

		if item.requiredTaskState ~= nil then
			local doingTask = not not (data.task and not data.task.finished)
			if item.requiredTaskState ~= doingTask then
				return false
			end
		end

		return true
	end,
	_dataFor = function(self, ship, station)
		if ship.__menu == nil then ship.__menu = {} end
		if ship.__menu[station] == nil then ship.__menu[station] = {currentEntries={}} end
		return ship.__menu[station]
	end,
	_startMenu = function(self, ship, station)
		local data = self:_dataFor(ship, station)

		for _, e in ipairs(data.currentEntries) do
			ship:removeCustom(e)
		end
		ship:removeCustom(station .. "menu-up")
		ship:removeCustom(station .. "menu-down")

		data.currentEntries = {}
		data.lastRefresh = getScenarioTime()

		data.queuedCalls = {}
		if data.offset == nil then data.offset = 0 end
		if data.maxItems == nil then data.maxItems = 25 end

		return self:_doTaskMenu(ship, station)
	end,
	_finishMenu = function(self, ship, station)
		local data = self:_dataFor(ship, station)

		local function orderForCall(call)
			if call[1] == "addCustomButton" then
				return call[2][5]
			else
				return call[2][4]
			end
		end
		table.stable_sort(data.queuedCalls, function(a, b)
			local a_order = orderForCall(a) or 0
			local b_order = orderForCall(b) or 0

			return a_order < b_order
		end)

		if #data.queuedCalls <= data.maxItems then
			for _, call in ipairs(data.queuedCalls) do
				ship[call[1]](ship, table.unpack(call[2]))
			end
			return
		end

		if data.offset + data.maxItems - 1 > #data.queuedCalls then
			data.offset = #data.queuedCalls - data.maxItems
		end

		local start = data.offset
		local end_ = data.offset + data.maxItems - 1

		if data.offset > 0 then
			start = start + 2
			ship:addCustomButton(station, station .. "menu-up", "↑", function()
				data.offset = data.offset - 1
				self:refreshMenu(ship, station)
			end, -1000000000)
		end
		if #data.queuedCalls == end_ + 1 then
			end_ = end_ + 1
		end
		for i = start, end_ do
			local call = data.queuedCalls[i]
			if call ~= nil then
				ship[call[1]](ship, table.unpack(call[2]))
			end
		end
		if #data.queuedCalls > end_ then
			ship:addCustomButton(station, station .. "menu-down", "↓", function()
				data.offset = data.offset + 1
				self:refreshMenu(ship, station)
			end, 1000000000)
		end
	end,
	_addButton = function(self, button, order, act, ship, station)
		local data = self:_dataFor(ship, station)
		local key = "b" .. station .. #data.currentEntries
		table.insert(data.queuedCalls, {"addCustomButton", {station, key, button, act, order}})
		table.insert(data.currentEntries, key)
	end,
	_addInfo = function(self, info, order, ship, station)
		local data = self:_dataFor(ship, station)
		local key = "i" .. station .. #data.currentEntries
		table.insert(data.queuedCalls, {"addCustomInfo", {station, key, info, order}})
		table.insert(data.currentEntries, key)
	end,

	_doTaskMenu = function(self, ship, station)
		local data = self:_dataFor(ship, station)

		if data.task then
			if data.task.finished then
				return data.task.finished
			end

			local timeRemaining = data.task.completionAt - getScenarioTime()

			local extraMenu = {}
			if data.task.menu then
				local m = data.task.menu
				if type(m) == "function" then
					m = m(ship, station)
				end
				for _, e in ipairs(m) do
					table.insert(extraMenu, e)
				end
			else
				table.insert(extraMenu, {info = "Task In Progress"})
			end
			table.insert(extraMenu, {info = "Remaining: " .. math.ceil(timeRemaining) .. "s"})
			return extraMenu
		end
	end,
	_completeTask = function(self, ship, station)
		local data = self:_dataFor(ship, station)

		if not data.task or data.task.finished then
			self:refreshMenu(ship, station)
			return
		end

		if data.task.complete then
			data.task.finished = data.task.complete(ship, station)
		end
		if not data.task.finished or type(data.task.finished) ~= "table" then
			data.task.finished = {
				{info = "Task Complete"},
			}
		end
		table.insert(data.task.finished, {button = "Dismiss", action=function() self:setTask(nil, ship, station); return false end})
		self:refreshMenu(ship, station)
	end,
	_updateTasks = function(self, ship)
		local now = getScenarioTime()

		for station, data in pairs(ship.__menu) do
			if data.task and not data.task.finished then
				if data.task.completionAt <= now then
					self:_completeTask(ship, station)
				else
					if data.task.update then
						local res = data.task.update(ship, station)
						if res ~= nil then
							data.task.finished = {
								{info = "Task Failed"},
								{info = tostring(res)},
								{button = "Dismiss", action=function() self:setTask(nil, ship, station); return false end},
							}
							self:refreshMenu(ship, station)
						end
					end

					if data.lastRefresh + 1 < now then
						self:refreshMenu(ship, station)
					end
				end
			end
		end
	end,

	--- Set the current task that the operator at the given console is working on.
	-- @function mainMenu:setTask
	-- @param task The task to set.
	-- @param ship The ship to set the task on.
	-- @param station The console to set the task for.
	setTask = function(self, task, ship, station)
		local data = self:_dataFor(ship, station)

		if task ~= nil then
			if task.completionAt == nil then
				if task.duration == nil then
					error("setTask with no completionAt or duration", 2)
				end

				task.completionAt = getScenarioTime() + task.duration
			end
		end

		data.task = task
	end,
}()

G.mainMenuConfig = MenuSet()

mainMenu:add {
	button = "Menu config",
	action = mainMenuConfig,
}

mainMenuConfig:add {
	button = "Set menu size",
	action = function(reopen, ship, station)
		local data = mainMenu:_dataFor(ship, station)
		data.maxItems = 50
		local m = {
			allowBack = false,
			allowHome = false,
			allowSticky = false,
			{info = "Select a size for the menu"},
			{info = "Future menus will not"},
			{info = "go below the button"},
			{info = "you click."},
		}
		for i = 5, 50 do
			table.insert(m, {button = "Size: " .. i, action = function(reopen, ship, station)
				data.maxItems = i
				return nil
			end})
		end
		return m
	end,
}

mainMenu:add {
	button = "Debug: finish immediately",
	isDebug = true,
	requiredTaskState = true,
	action = function(reopen, ship, station)
		mainMenu:_completeTask(ship, station)
	end,
}

function hook.after.newPlayerShip(ship)
	for _, station in ipairs(position.all) do
		mainMenu:setMenu(nil, ship, station)
	end
end

function hook.on.update()
	for _, ship in ipairs(getActivePlayerShips()) do
		if ship.__menu == nil then ship.__menu = {} end
		mainMenu:_updateTasks(ship)
	end
end

hook.every[1] = function()
	for _, ship in ipairs(getActivePlayerShips()) do
		for _, station in ipairs(position.all) do
			mainMenu:refreshMenu(ship, station)
		end
	end
end
