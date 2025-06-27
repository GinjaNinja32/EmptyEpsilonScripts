--- [`action-main`] Provides an `action-main`-driven menu for interacting with `cargo`.

require "gn32/action-main"
require "gn32/drag"
require "gn32/cargo"
require "gn32/vector"

--- Areas.
-- See `position` for details on areas, including how to override the default stations.
-- @section areas

--- Transfer and jettison cargo.  
-- Default stations: Relay, Operations, Single Pilot.
-- @table cargo
position.defineAreaDefault("cargo", "Relay", "Operations", "Single")

mainMenu:add {
	sticky = true,
	when = function(ship, station)
		return comps(ship).cargo and (ship.cargo_display or {})[station]
	end,
	expand = function(ship, station)
		local c = comps(ship).cargo

		local m = {}
		for i, def in ipairs(cargo.items) do
			local amt = c.items[def] or 0

			if amt > 0 then
				table.insert(m, {
					order = i - 1000,
					info = def.name .. " (" .. def.id .. "): " .. amt,
				})
			end
		end

		local n_other = 0
		for item, count in pairs(c.items) do
			if not item.id then
				n_other = n_other + count
			end
		end
		if n_other > 0 then
			table.insert(m, {
				order = #m - 1000,
				info = "Other items: " .. n_other,
			})
		end

		return m
	end,
}

local function cargoTransferAction(ship, target)
	return function()
		if not (ship:isDocked(target) or target:isDocked(ship)) then
			return
		end

		local c = comps(ship).cargo
		local menu = {}

		for i, def in ipairs(cargo.items) do
			local amt = c.items[def] or 0

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
	when = function(ship, station) return not not comps(ship).cargo end,
	action = {
		{
			button = "DEBUG",
			isDebug = true,
			action = function()
				local menu = {
					{
						button = function(ship, station)
							local c = comps(ship).cargo
							if c.infinite then
								return "Infinite cargo: ON"
							else
								return "Infinite cargo: OFF"
							end
						end,
						action = function(_, ship, station)
							local c = comps(ship).cargo
							c.infinite = not c.infinite
							return false
						end,
					}
				}

				local cats = {}
				local uncat = {}

				for _, item in ipairs(cargo.items) do
					if item.category then
						cats[item.category] = true
					else
						table.insert(uncat, {
							button = "Get 1" .. item.id,
							action = function(_, ship, station)
								cargo.adjust(ship, {[item.id]=1})
								return false
							end,
						})
						table.insert(uncat, {
							button = "Get 10" .. item.id,
							action = function(_, ship, station)
								cargo.adjust(ship, {[item.id]=10})
								return false
							end,
						})
					end
				end

				local catsL = {}
				for k in pairs(cats) do table.insert(catsL, k) end
				table.sort(catsL)
				for _, cat in ipairs(catsL) do
					table.insert(menu, {
						button = cat,
						action = function(_, ship, station)
							local menu = {}
							for _, item in ipairs(cargo.items) do
								if item.category == cat then
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
							end
							return menu
						end,
					})
				end

				table.insert(menu, {expand = uncat})

				return menu
			end,
		},
		{
			area = "cargo",
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
			area = "cargo",
			button = "Jettison Cargo...",
			action = function(reopen, ship, station)
				local c = comps(ship).cargo
				local menu = {}

				for i, def in ipairs(cargo.items) do
					local amt = c.items[def] or 0

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
										d.components.physics.velocity = {vx, vy}
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
				if (ship.cargo_display or {})[station] then
					return "Cargo Display: ON"
				else
					return "Cargo Display: OFF"
				end
			end,
			action = function(reopen, ship, station)
				if ship.cargo_display == nil then ship.cargo_display = {} end
				ship.cargo_display[station] = not ship.cargo_display[station]

				return false
			end,
		},
		{
			button = "View Cargo Details",
			action = function(reopen, ship, station)
				local c = comps(ship).cargo
				local entries = {}

				for _, def in ipairs(cargo.items) do
					local amt = c.items[def]
					if amt and amt > 0 then
						table.insert(entries, amt .. " " .. def.name .. " (" .. def.id .. ")\n" .. def.desc)
					end
				end

				local nf = {}
				for item, count in pairs(c.items) do
					if count > 0 and not item.id then
						table.insert(nf, (count > 1 and count .. " " or "") .. item.name .. "\n" .. item.desc)
					end
				end
				if nf[1] then
					table.sort(nf)
					table.insert(entries, table.concat(nf, "\n\n"))
				end

				ship:addCustomMessage(station, "Cargo Details", table.concat(entries, "\n\n"))

				return false
			end,
		}
	}
}
