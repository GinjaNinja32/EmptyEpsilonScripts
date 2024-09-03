require "gn32/test/test"

require "gn32/action-comms"
require "gn32/action-gm"
require "gn32/action-main"

local function strerror(s)
	error(setmetatable({}, {__tostring=function() return s end}), 2)
end

test("action/comms", function()
	local entries = {
		{button = "Foo"},
		{info = "Bar"},
		{button = "Baz"},
	}

	local commsMenu = CommsMenu()

	commsMenu:add {
		info = "Test Info",
	}
	commsMenu:add {
		button = "Literal Action",
		action = {
			{info = "What Action?"},
			{button = "Nil", action = nil},
			{button = "False", action = false},
			{button = "Empty", action = {}},
			{button = "Entries", action = entries},
		},
	}
	commsMenu:add {
		button = "Function Action",
		action = {
			{info = "What Action?"},
			{button = "Nil", action = function() return nil end},
			{button = "False", action = function() return false end},
			{button = "Empty", action = function() return {} end},
			{button = "Entries", action = function() return entries end},
			{button = "Error", action = function() error(setmetatable({}, {__tostring=function() return "bang" end})) end},
		},
	}

	local source = Entity()
	local target = Entity()

	local function press(btn)
		for _, b in ipairs(commsData.replies) do
			if b.name == btn then
				resetCommsData()
				b.action(source, target)
			end
		end
	end

	local homeMenu = {
		message = "Test Info",
		replies = {
			{name="Literal Action", action=equivalentAny},
			{name="Function Action", action=equivalentAny},
		},
	}

	local literalMenu = {
		message = "What Action?",
		replies = {
			{name="Home", action=equivalentAny},
			{name="Nil", action=equivalentAny},
			{name="False", action=equivalentAny},
			{name="Empty", action=equivalentAny},
			{name="Entries", action=equivalentAny},
		},
	}

	local functionMenu = {
		message = "What Action?",
		replies = {
			{name="Home", action=equivalentAny},
			{name="Nil", action=equivalentAny},
			{name="False", action=equivalentAny},
			{name="Empty", action=equivalentAny},
			{name="Entries", action=equivalentAny},
			{name="Error", action=equivalentAny},
		},
	}

	local emptyMenu = {
		message = "[Menu Error]\nno message set",
		replies = {
			{name="Home", action=equivalentAny},
			{name="Back", action=equivalentAny},
		},
	}

	local errorMenu = {
		message = "[Menu Error]\nbang",
		replies = {
			{name="Home", action=equivalentAny},
		},
	}

	local entriesMenu = {
		message = "Bar",
		replies = {
			{name="Home", action=equivalentAny},
			{name="Back", action=equivalentAny},
			{name="Foo", action=equivalentAny},
			{name="Baz", action=equivalentAny},
		},
	}

	commsMenu:getCommsFunction()(source, target)
	assert.equivalent(commsData, homeMenu)

	press "Literal Action"
	assert.equivalent(commsData, literalMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Literal Action"
	assert.equivalent(commsData, literalMenu)
	press "Nil"
	assert.equivalent(commsData, homeMenu)

	press "Literal Action"
	assert.equivalent(commsData, literalMenu)
	press "False"
	assert.equivalent(commsData, literalMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Literal Action"
	assert.equivalent(commsData, literalMenu)
	press "Empty"
	assert.equivalent(commsData, emptyMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Literal Action"
	assert.equivalent(commsData, literalMenu)
	press "Entries"
	assert.equivalent(commsData, entriesMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Function Action"
	assert.equivalent(commsData, functionMenu)
	press "Nil"
	assert.equivalent(commsData, homeMenu)

	press "Function Action"
	assert.equivalent(commsData, functionMenu)
	press "False"
	assert.equivalent(commsData, functionMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Function Action"
	assert.equivalent(commsData, functionMenu)
	press "Empty"
	assert.equivalent(commsData, emptyMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Function Action"
	assert.equivalent(commsData, functionMenu)
	press "Entries"
	assert.equivalent(commsData, entriesMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	press "Function Action"
	assert.equivalent(commsData, functionMenu)
	press "Error"
	assert.equivalent(commsData, errorMenu)
	press "Home"
	assert.equivalent(commsData, homeMenu)

	resetCommsData()
end)

test("action/gm", function()
	local entries = {
		{button = "Foo"},
		{info = "Bar"},
		{button = "Baz"},
	}

	gmMenu:add {
		button = "Test Info",
	}
	gmMenu:add {
		button = "Literal Action",
		action = {
			{button = "Nil", action = nil},
			{button = "False", action = false},
			{button = "Empty", action = {}},
			{button = "Entries", action = entries},
		},
	}
	gmMenu:add {
		button = "Function Action",
		action = {
			{button = "Nil", action = function() return nil end},
			{button = "False", action = function() return false end},
			{button = "Empty", action = function() return {} end},
			{button = "Entries", action = function() return entries end},
			{button = "Error", action = function() error(setmetatable({}, {__tostring=function() return "bang" end})) end},
		},
	}

	local function press(btn)
		for _, v in ipairs(gmFunctions) do
			if v.name == btn then
				v.action()
			end
		end
	end

	local homeMenu = {
		{name="Debug Toggles", action=equivalentAny},
		{name="Test Info", action=equivalentAny},
		{name="Literal Action", action=equivalentAny},
		{name="Function Action", action=equivalentAny},
	}

	local literalMenu = {
		{name="Home", action=equivalentAny},
		{name="Nil", action=equivalentAny},
		{name="False", action=equivalentAny},
		{name="Empty", action=equivalentAny},
		{name="Entries", action=equivalentAny},
	}

	local functionMenu = {
		{name="Home", action=equivalentAny},
		{name="Nil", action=equivalentAny},
		{name="False", action=equivalentAny},
		{name="Empty", action=equivalentAny},
		{name="Entries", action=equivalentAny},
		{name="Error", action=equivalentAny},
	}

	local emptyMenu = {
		{name="Home", action=equivalentAny},
		{name="Back", action=equivalentAny},
	}

	local errorMenu = {
		{name="Home", action=equivalentAny},
		{name="*[Menu Error]", action=equivalentAny},
		{name="*bang", action=equivalentAny},
	}

	local entriesMenu = {
		{name="Home", action=equivalentAny},
		{name="Back", action=equivalentAny},
		{name="Foo", action=equivalentAny},
		{name="*Bar", action=equivalentAny},
		{name="Baz", action=equivalentAny},
	}

	gmMenu:setMenu(nil)
	assert.equivalent(gmFunctions, homeMenu)

	press "Literal Action"
	assert.equivalent(gmFunctions, literalMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Literal Action"
	assert.equivalent(gmFunctions, literalMenu)
	press "Nil"
	assert.equivalent(gmFunctions, homeMenu)

	press "Literal Action"
	assert.equivalent(gmFunctions, literalMenu)
	press "False"
	assert.equivalent(gmFunctions, literalMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Literal Action"
	assert.equivalent(gmFunctions, literalMenu)
	press "Empty"
	assert.equivalent(gmFunctions, emptyMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Literal Action"
	assert.equivalent(gmFunctions, literalMenu)
	press "Entries"
	assert.equivalent(gmFunctions, entriesMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Function Action"
	assert.equivalent(gmFunctions, functionMenu)
	press "Nil"
	assert.equivalent(gmFunctions, homeMenu)

	press "Function Action"
	assert.equivalent(gmFunctions, functionMenu)
	press "False"
	assert.equivalent(gmFunctions, functionMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Function Action"
	assert.equivalent(gmFunctions, functionMenu)
	press "Empty"
	assert.equivalent(gmFunctions, emptyMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Function Action"
	assert.equivalent(gmFunctions, functionMenu)
	press "Entries"
	assert.equivalent(gmFunctions, entriesMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)

	press "Function Action"
	assert.equivalent(gmFunctions, functionMenu)
	press "Error"
	assert.equivalent(gmFunctions, errorMenu)
	press "Home"
	assert.equivalent(gmFunctions, homeMenu)
end)

test("action/main", function()
	local entries = {
		{button = "Foo"},
		{info = "Bar"},
		{button = "Baz"},
	}

	mainMenu:add {
		info = "Test Info",
	}
	mainMenu:add {
		button = "Literal Action",
		action = {
			{button = "Nil", action = nil},
			{button = "False", action = false},
			{button = "Empty", action = {}},
			{button = "Entries", action = entries},
		},
	}
	mainMenu:add {
		button = "Function Action",
		action = {
			{button = "Nil", action = function() return nil end},
			{button = "False", action = function() return false end},
			{button = "Empty", action = function() return {} end},
			{button = "Entries", action = function() return entries end},
			{button = "Error", action = function() strerror("bang") end},
		},
	}
	mainMenu:add {
		button = "Restricted Navigation",
		action = {
			{button = "No Default Buttons", action = {
				allowHome = false,
				allowBack = false,
				{button = "Custom Home", action = nil},
			}},
			{button = "No Default Home", action = {
				allowHome = false,
				{button = "Custom Home", action = nil},
			}},
			{button = "Sub", action = {
				{button = "No Back Inner", action = {
					allowBack = false,
					{info = "Foo"},
				}},
				{button = "No Back Outer", allowBack = false, action = {
					{info = "Bar"},
				}},
				{button = "Regular", action = {
					{info = "Baz"},
				}},
			}},
		},
	}
	mainMenu:add {
		button = "Tasks",
		action = {
			{button = "Short Task", action = function(reopen, ship, station)
				if reopen then return end
				mainMenu:setTask({
					duration = 5,
					menu = {
						{info = "Short task in progress..."},
					},
				}, ship, station)
			end},
			{button = "Long Task", action = function(reopen, ship, station)
				if reopen then return end
				mainMenu:setTask({
					duration = 60,
					menu = {
						{info = "Long task in progress..."},
					},
				}, ship, station)
			end},
			{button = "Failing Task", action = function(reopen, ship, station)
				if reopen then return end
				mainMenu:setTask({
					duration = 60,
					menu = {
						{info = "Task started..."},
					},
					update = function()
						return "oh no"
					end,
				}, ship, station)
			end},
		},
	}
	mainMenu:add {
		button = "Long Submenu",
		action = {
			{button = "Option 1", action = nil},
			{button = "Option 2", action = nil},
			{button = "Option 3", action = nil},
			{button = "Option 4", action = nil},
			{button = "Option 5", action = nil},
			{button = "Option 6", action = nil},
			{button = "Option 7", action = nil},
			{button = "Option 8", action = nil},
			{button = "Option 9", action = nil},
			{button = "Option 10", action = nil},
			{button = "Option 11", action = nil},
			{button = "Option 12", action = nil},
			{button = "Option 13", action = nil},
			{button = "Option 14", action = nil},
			{button = "Option 15", action = nil},
			{button = "Option 16", action = nil},
			{button = "Option 17", action = nil},
			{button = "Option 18", action = nil},
			{button = "Option 19", action = nil},
			{button = "Option 20", action = nil},
			{button = "Option 21", action = nil},
			{button = "Option 22", action = nil},
			{button = "Option 23", action = nil},
			{button = "Option 24", action = nil},
			{button = "Option 25", action = nil},
		}
	}
	mainMenu:add {
		button = "Misbehaving Entries",
		action = {
			{},
			{ button = function() strerror("button bang") end },
			{ info = function() strerror("info bang") end },
			{ info = "when=>error", when = function() strerror("when bang") end },
			{ info = "order string", order = "a string" },
		}
	}

	local ship = PlayerSpaceship()

	local function press(btn)
		for _, v in ipairs(ship.customButtons) do
			if v.button == btn then
				v.action()
				return
			end
		end

		error("button '" .. btn .. "' not found", 2)
	end

	local homeMenu = {
		{ id="bEngineering0", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering1", station="Engineering", info="Test Info" },
		{ id="bEngineering2", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering4", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	}

	local literalMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Nil", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="False", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="Empty", action=equivalentAny },
		{ id="bEngineering4", station="Engineering", button="Entries", action=equivalentAny },
	}

	local functionMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Nil", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="False", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="Empty", action=equivalentAny },
		{ id="bEngineering4", station="Engineering", button="Entries", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Error", action=equivalentAny },
	}

	local emptyMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Back", action=equivalentAny },
	}

	local errorMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="iEngineering1", station="Engineering", info="[Menu Error]" },
		{ id="iEngineering2", station="Engineering", info="bang" },
	}

	local entriesMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Back", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="Foo", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Bar" },
		{ id="bEngineering4", station="Engineering", button="Baz", action=equivalentAny },
	}

	local restrictedMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="No Default Buttons", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="No Default Home", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="Sub", action=equivalentAny },
	}

	local restrictedNDBMenu = {
		{ id="bEngineering0", station="Engineering", button="Custom Home", action=equivalentAny },
	}

	local restrictedNDHMenu = {
		{ id="bEngineering0", station="Engineering", button="Back", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Custom Home", action=equivalentAny },
	}

	local restrictedSubMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Back", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="No Back Inner", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="No Back Outer", action=equivalentAny },
		{ id="bEngineering4", station="Engineering", button="Regular", action=equivalentAny },
	}

	local restrictedNBInnerMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="iEngineering1", station="Engineering", info="Foo" },
	}

	local restrictedNBOuterMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="iEngineering1", station="Engineering", info="Bar" },
	}

	local restrictedRegularMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Back", action=equivalentAny },
		{ id="iEngineering2", station="Engineering", info="Baz" },
	}

	local tasksMenu = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="Short Task", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="Long Task", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="Failing Task", action=equivalentAny },
	}

	do
		local data = mainMenu:_dataFor(ship, "Engineering")
		data.maxItems = 10
	end

	mainMenu:setMenu(nil, ship, "Engineering")
	assert.equivalent(ship.customButtons, homeMenu)

	press "Literal Action"
	assert.equivalent(ship.customButtons, literalMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Literal Action"
	assert.equivalent(ship.customButtons, literalMenu)
	press "Nil"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Literal Action"
	assert.equivalent(ship.customButtons, literalMenu)
	press "False"
	assert.equivalent(ship.customButtons, literalMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Literal Action"
	assert.equivalent(ship.customButtons, literalMenu)
	press "Empty"
	assert.equivalent(ship.customButtons, emptyMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Literal Action"
	assert.equivalent(ship.customButtons, literalMenu)
	press "Entries"
	assert.equivalent(ship.customButtons, entriesMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Function Action"
	assert.equivalent(ship.customButtons, functionMenu)
	press "Nil"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Function Action"
	assert.equivalent(ship.customButtons, functionMenu)
	press "False"
	assert.equivalent(ship.customButtons, functionMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Function Action"
	assert.equivalent(ship.customButtons, functionMenu)
	press "Empty"
	assert.equivalent(ship.customButtons, emptyMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Function Action"
	assert.equivalent(ship.customButtons, functionMenu)
	press "Entries"
	assert.equivalent(ship.customButtons, entriesMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Function Action"
	assert.equivalent(ship.customButtons, functionMenu)
	press "Error"
	assert.equivalent(ship.customButtons, errorMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Restricted Navigation"
	assert.equivalent(ship.customButtons, restrictedMenu)
	press "No Default Buttons"
	assert.equivalent(ship.customButtons, restrictedNDBMenu)
	press "Custom Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Restricted Navigation"
	assert.equivalent(ship.customButtons, restrictedMenu)
	press "No Default Home"
	assert.equivalent(ship.customButtons, restrictedNDHMenu)
	press "Custom Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Restricted Navigation"
	assert.equivalent(ship.customButtons, restrictedMenu)
	press "Sub"
	assert.equivalent(ship.customButtons, restrictedSubMenu)
	press "No Back Inner"
	assert.equivalent(ship.customButtons, restrictedNBInnerMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Restricted Navigation"
	assert.equivalent(ship.customButtons, restrictedMenu)
	press "Sub"
	assert.equivalent(ship.customButtons, restrictedSubMenu)
	press "No Back Outer"
	assert.equivalent(ship.customButtons, restrictedNBOuterMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Restricted Navigation"
	assert.equivalent(ship.customButtons, restrictedMenu)
	press "Sub"
	assert.equivalent(ship.customButtons, restrictedSubMenu)
	press "Regular"
	assert.equivalent(ship.customButtons, restrictedRegularMenu)
	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Tasks"
	assert.equivalent(ship.customButtons, tasksMenu)
	press "Short Task"
	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Short task in progress..." },
		{ id="iEngineering1", station="Engineering", info="Remaining: 5s" },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	scenarioTime = scenarioTime + 2
	mainMenu:_updateTasks(ship)

	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Short task in progress..." },
		{ id="iEngineering1", station="Engineering", info="Remaining: 3s" },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	scenarioTime = scenarioTime + 3
	mainMenu:_updateTasks(ship)

	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Task Complete" },
		{ id="bEngineering1", station="Engineering", button="Dismiss", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	press "Dismiss"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Tasks"
	assert.equivalent(ship.customButtons, tasksMenu)
	press "Long Task"
	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Long task in progress..." },
		{ id="iEngineering1", station="Engineering", info="Remaining: 60s" },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	scenarioTime = scenarioTime + 55
	mainMenu:_updateTasks(ship)

	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Long task in progress..." },
		{ id="iEngineering1", station="Engineering", info="Remaining: 5s" },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	scenarioTime = scenarioTime + 6
	mainMenu:_updateTasks(ship)

	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Task Complete" },
		{ id="bEngineering1", station="Engineering", button="Dismiss", action=equivalentAny },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	press "Dismiss"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Tasks"
	assert.equivalent(ship.customButtons, tasksMenu)
	press "Failing Task"
	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Task started..." },
		{ id="iEngineering1", station="Engineering", info="Remaining: 60s" },
		{ id="bEngineering2", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering3", station="Engineering", info="Test Info" },
		{ id="bEngineering4", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering5", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Long Submenu", action=equivalentAny },
		{ id="bEngineering9", station="Engineering", button="Misbehaving Entries", action=equivalentAny },
	})

	scenarioTime = scenarioTime + 55
	mainMenu:_updateTasks(ship)

	assert.equivalent(ship.customButtons, {
		{ id="iEngineering0", station="Engineering", info="Task Failed" },
		{ id="iEngineering1", station="Engineering", info="oh no" },
		{ id="bEngineering2", station="Engineering", button="Dismiss", action=equivalentAny },
		{ id="bEngineering3", station="Engineering", button="Menu config", action=equivalentAny },
		{ id="iEngineering4", station="Engineering", info="Test Info" },
		{ id="bEngineering5", station="Engineering", button="Literal Action", action=equivalentAny },
		{ id="bEngineering6", station="Engineering", button="Function Action", action=equivalentAny },
		{ id="bEngineering7", station="Engineering", button="Restricted Navigation", action=equivalentAny },
		{ id="bEngineering8", station="Engineering", button="Tasks", action=equivalentAny },
		{ id="Engineeringmenu-down", station="Engineering", button="↓", action=equivalentAny },
	})

	press "Dismiss"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Long Submenu"
	local items = {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
	}
	for i = 1, 25 do
		table.insert(items, { id="bEngineering"..i, station="Engineering", button="Option " .. i, action=equivalentAny })
	end

	local function genMenuSpan(up, start, end_, down)
		local m = {}
		if up then
			table.insert(m, { id="Engineeringmenu-up", station="Engineering", button="↑", action=equivalentAny })
		end
		local n = 0
		for i = start, end_ do
			table.insert(m, items[i])
			n = n + 1
		end
		if down then
			table.insert(m, { id="Engineeringmenu-down", station="Engineering", button="↓", action=equivalentAny })
		end
		return m
	end

	assert.equivalent(ship.customButtons, genMenuSpan(false, 1, 9, true))
	for i = 3, 17 do
		press("↓")
		assert.equivalent(ship.customButtons, genMenuSpan(true, i, i+7, true))
	end
	press "↓"
	assert.equivalent(ship.customButtons, genMenuSpan(true, 18, 26, false))
	for i = 17, 3, -1 do
		press("↑")
		assert.equivalent(ship.customButtons, genMenuSpan(true, i, i+7, true))
	end
	press "↑"
	assert.equivalent(ship.customButtons, genMenuSpan(false, 1, 9, true))

	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)

	press "Misbehaving Entries"
	assert.equivalent(ship.customButtons, {
		{ id="bEngineering0", station="Engineering", button="Home", action=equivalentAny },
		{ id="bEngineering1", station="Engineering", button="<ERR: button bang>", action=equivalentAny },
		{ id="iEngineering2", station="Engineering", info="<ERR: info bang>" },
		{ id="iEngineering3", station="Engineering", info="order string" },
	})

	press "Home"
	assert.equivalent(ship.customButtons, homeMenu)
end)
