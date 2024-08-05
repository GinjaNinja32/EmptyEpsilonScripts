-- Name: gn32/hook-sys
-- Description: Provides utilities for allowing multiple systems to hook the same set of events without interfering with each other or requiring coordination.
--[[
	To register to receive a global hook:
		hook.on.<event>(<callback>)
		hook.on.<event> = <callback>
		function hook.on.<event>(...) ... end

	To trigger a global hook:
		hook.trigger.<event>(<args>)

	To register to receive an entity hook:
		hook.entity[<ent>].on.<event>(<callback>)
		hook.entity[<ent>].on.<event> = <callback>

	To trigger an entity hook:
		hook.entity[<ent>].trigger.<event>(<args>)
]]

require "gn32/lang"

G.hook = {}

local registered = {}
local registeredAfter = {}

hook.entityEventRegistrationName = {}

hook.entity = setmetatable({}, {
	__index = function(t, entity)
		if entity.__hooks == nil then
			entity.__hooks = {}
		end
		local h = entity.__hooks

		local ehook = {}

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
hook.every = setmetatable({}, {
	__newindex = function(t, time, fn)
		table.insert(timers, {
			interval = time,
			next = getScenarioTime(),
			fn = fn,
		})
	end
})

function hook.on.update(delta)
	local now = getScenarioTime()
	for _, timer in ipairs(timers) do
		if timer.next <= now then
			timer.next = timer.next + timer.interval
			local ok, res = pcall(timer.fn)
			if not ok then
				print("Timer error:", res)
			end
		end
	end
end
