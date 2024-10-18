--- Provides utilities for allowing multiple systems to hook the same set of events without interfering with each other or requiring coordination.
-- Anywhere the text EVENT appears in the function documentation below, this should be substituted for the name of an event, such as `init` or `destroyed`.

require "gn32/lang"

G.hook = {}

local registered = {}
local registeredAfter = {}

hook.entityEventRegistrationName = {}

--- Entity.
-- @section Entity

--- Access hooks for an entity.
-- This table should be indexed with the entity you wish to set or trigger hooks for.
-- The remaining functions in this section are accessed on the table returned from this index operation.
-- @table hook.entity
hook.entity = setmetatable({}, {
	__index = function(t, entity)
		if entity.__hooks == nil then
			entity.__hooks = {}
		end
		local h = entity.__hooks

		local ehook = {}

		--- Register to receive a callback when an event happens on this entity.
		-- @function .on.EVENT
		-- @param callback The callback to register. Callbacks will receive a first parameter of the entity itself, followed by any arguments passed to `.trigger.EVENT`.
		ehook.on = setmetatable({}, {
			__index = function(t, event)
				return function(callback)
					if h[event] == nil then
						h[event] = {}
					end

					local methodName = hook.entityEventRegistrationName[event]
					if methodName then
						entity[methodName](entity, ehook.trigger[event])
					end

					table.insert(h[event], callback)

					return ehook
				end
			end,
			__newindex = function(t, event, callback)
				ehook.on[event](callback)
			end
		})

		--- Trigger an event on this entity.
		-- @function .trigger.EVENT
		-- @param ... The additional arguments to pass to each callback.
		ehook.trigger = setmetatable({}, {
			__index = function(t, event)
				return function(...)
					if h[event] == nil then
						return
					end

					local results = {}
					for _, c in ipairs(h[event]) do
						local ok, res = pcall(c, entity, ...)
						if not ok then
							print("Entity hook error:", entity, event, res)
						else
							table.insert(results, res)
						end
					end

					return results
				end
			end,
		})

		return ehook
	end
})

--- Global.
-- @section Global

--- Register to receive a callback when an event happens.
-- @function hook.on.EVENT
-- @param callback The callback to register.
hook.on = setmetatable({}, {
	__index = function(t, event)
		return function(callback)
			if registered[event] == nil then
				registered[event] = {}
			end

			table.insert(registered[event], callback)

			return hook
		end
	end,
	__newindex = function(t, event, callback)
		hook.on[event](callback)
	end
})

--- Register to receive a callback when an event happens, after all normal callbacks have been called.
-- @function hook.after.EVENT
-- @param callback The callback to register.
hook.after = setmetatable({}, {
	__index = function(t, event)
		return function(callback)
			if registeredAfter[event] == nil then
				registeredAfter[event] = {}
			end

			table.insert(registeredAfter[event], callback)

			return hook
		end
	end,
	__newindex = function(t, event, callback)
		hook.after[event](callback)
	end
})

--- Trigger an event.
-- @function hook.trigger.EVENT
-- @param ... The arguments to pass to each callback.
hook.trigger = setmetatable({}, {
	__index = function(t, event)
		return function(...)
			local results = {}
			if registered[event] then
				for _, c in ipairs(registered[event]) do
					local ok, res = pcall(c, ...)
					if not ok then
						print("Hook error:", event, res)
					else
						table.insert(results, res)
					end
				end
			end
			if registeredAfter[event] then
				for _, c in ipairs(registeredAfter[event]) do
					local ok, res = pcall(c, ...)
					if not ok then
						print("Hook error:", event, res)
					end
				end
			end

			return results
		end
	end,
})

local timers = {}

--- Register to receive a callback on an interval. This function depends on the `update` hook being triggered regularly.
-- @function hook.every
-- @tparam number interval The interval to call on.
-- @tparam function callback The callback to register.
local addTimer = function(_, time, fn)
	table.insert(timers, {
		interval = time,
		next = getScenarioTime(),
		fn = fn,
	})
end

hook.every = setmetatable({}, {
	__call = addTimer,
	__newindex = addTimer,
})

--- Register to receive a callback after a delay. This function depends on the `update` hook being triggered regularly.
-- @function hook.afterDelay
-- @tparam number time The delay after which to call the function.
-- @tparam function callback The callback to register.
hook.afterDelay = function(time, fn)
	table.insert(timers, {
		next = getScenarioTime() + time,
		fn = fn,
	})
end

function hook.on.update(delta)
	local now = getScenarioTime()
	for idx, timer in pairs(timers) do
		if timer.next <= now then
			if timer.interval then
				timer.next = timer.next + timer.interval
			else
				timers[idx] = nil
			end
			local ok, res = pcall(timer.fn)
			if not ok then
				print("Timer error:", res)
			end
		end
	end
end
