--- [`action-main`] Provides an `action-main`-driven menu for interacting with `cargo`.

require "gn32/action-main"
require "gn32/drag"
require "gn32/cargo"
require "gn32/vector"

mainMenu:add {
	sticky = true,
	when = function(ship, station) return ship.cargo and (ship.cargo.display or {})[station] end,
	expand = function(ship, station)
		if ship.cargo.items == nil then return {} end

		local m = {}
		for i, def in ipairs(cargo.items) do
			local amt = ship.cargo.items[def.id] or 0

			if amt > 0 then
				table.insert(m, {
					order = i - 1000,
					info = def.name .. " (" .. def.id .. "): " .. amt,
				})
			end
		end

		return m
	end,
}

local function cargoTransferAction(ship, target)
	return function()
		if not (ship:isDocked(target) or target:isDocked(ship)) then
			return
		end

		local menu = {}

		for i, def in ipairs(cargo.items) do
			local amt = (ship.cargo.items or {})[def.id] or 0

			if amt > 0 then
				table.insert(menu, {
					button = def.name .. " (" .. amt .. ")",
					action = function()
						if not (ship:isDocked(target) or target:isDocked(ship)) then
							return
						end

						if cargo.has(ship, {[def.id]=1}) then
							if cargo.adjust(target, {[def.id]=1}) then
								cargo.use(ship, {[def.id]=1})
							end
						end

						return false
					end
				})
			end
		end

		if #menu == 0 then
			return {
				{info = "No cargo found to transfer"}
			}
		end

		return menu
	end
end

mainMenu:add {
	button = "Cargo",
	when = function(ship, station) return not not ship.cargo end,
	action = {
		{
			button = "DEBUG",
			isDebug = true,
			action = function()
				local menu = {
					{
						button = function(ship, station)
							if ship.cargo.infinite then
								return "Infinite cargo: ON"
							else
								return "Infinite cargo: OFF"
							end
						end,
						action = function(_, ship, station)
							ship.cargo.infinite = not ship.cargo.infinite
							return false
						end,
					}
				}
				for _, item in ipairs(cargo.items) do
					table.insert(menu, {
						button = "Get 1" .. item.id,
						action = function(_, ship, station)
							cargo.adjust(ship, {[item.id]=1})
							return false
						end,
					})
					table.insert(menu, {
						button = "Get 10" .. item.id,
						action = function(_, ship, station)
							cargo.adjust(ship, {[item.id]=10})
							return false
						end,
					})
				end
				return menu
			end,
		},
		{
			stations = {"Relay", "Operations", "Single"},
			button = "Transfer Cargo...",
			action = function(reopen, ship, station)
				local menu = {}

				local docked = ship:getDockedWith()
				if docked then
					table.insert(menu, {button = "to " .. docked:getCallSign(), action = cargoTransferAction(ship, docked)})
				end

				for _, target in ipairs(getActivePlayerShips()) do
					if target:isDocked(ship) then
						table.insert(menu, {button = "to " .. target:getCallSign(), action = cargoTransferAction(ship, target)})
					end
				end

				if #menu == 0 then
					return {
						{info = "No suitable target."},
						{info = "Cargo transfer requires"},
						{info = "that ships are docked."},
					}
				end

				return menu
			end,
		},
		{
			stations = {"Relay", "Operations", "Single"},
			button = "Jettison Cargo...",
			action = function(reopen, ship, station)
				local menu = {}

				for i, def in ipairs(cargo.items) do
					local amt = (ship.cargo.items or {})[def.id] or 0

					if amt > 0 then
						table.insert(menu, {
							button = def.name .. " (" .. amt .. ")",
							action = function()
								if cargo.use(ship, {[def.id]=1}) then
									local vx, vy = ship:getVelocity()

									local fx, fy = vector.xyFromRadialDeg(400, ship:getRotation())

									vx = vx - fx + random(-100, 100)
									vy = vy - fy + random(-100, 100)

									local d = CargoDrop(def.id, 10)
										:setPosition(ship:getPosition())

									if G.createEntity then
										d:setVelocity(vx, vy)
									else
										comps(d).velocity = {x = vx, y = vy}
									end

									comps(d).drag = {}
								end

								return false
							end
						})
					end
				end

				if #menu == 0 then
					return {
						{info = "No cargo found to jettison."}
					}
				end

				return menu
			end,
		},
		{
			button = function(ship, station)
				if (ship.cargo.display or {})[station] then
					return "Cargo Display: ON"
				else
					return "Cargo Display: OFF"
				end
			end,
			action = function(reopen, ship, station)
				if ship.cargo.display == nil then ship.cargo.display = {} end
				ship.cargo.display[station] = not ship.cargo.display[station]

				return false
			end,
		},
		{
			button = "View Cargo Details",
			action = function(reopen, ship, station)
				local entries = {}

				if ship.cargo.items then
					for _, def in ipairs(cargo.items) do
						local amt = ship.cargo.items[def.id]
						if amt and amt > 0 then
							table.insert(entries, amt .. " " .. def.name .. " (" .. def.id .. ")\n" .. def.desc)
						end
					end
				end

				ship:addCustomMessage(station, "Cargo Details", table.concat(entries, "\n\n"))

				return false
			end,
		}
	}
}
