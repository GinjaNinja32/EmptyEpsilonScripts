--- Generic menu system for EE, flexible enough to handle [GM buttons](action-gm.html), [comms menus](action-comms.html), and [custom station button menus](action-main.html).
-- Any `...` function argument in examples below refers to the target arguments of the menu, which should be specified in implementations.
--
-- Supported menu item list fields:
--
-- - `allowHome`: Whether to allow returning directly to the top-level menu from this menu. Default true.
-- - `allowBack`:  Whether to allow returning to the parent menu. Default true.
-- - `allowSticky`: Whether to allow sticky menu items to display with this menu. Default true.
--
-- Supported menu item fields:
--
-- Any entry with a description starting with `[F]` may be replaced with a `function(...)` returning the described value.
--
--	{
--		-- Exactly one of the following three fields must be present.
--		-- [F] Name of button.
--		button = "Button Name",
--		-- [F] Text for info panel/comms message.
--		info = "Info Text",
--		-- [F] List of menu items to substitute for this item if shown.
--		expand = {},
--
--		-- [F] The action to perform when the button is pressed.
--		-- Only valid on `button` items. See below for valid values.
--		action = ...,
--		-- Whether to allow returning to the current menu after this
--		-- submenu is entered. Only valid on `button` items. Default true.
--		allowBack = true,
--
--		-- Whether the item is a debug item that should only be displayed
--		-- when the 'menuOptions' debug toggle is enabled. Default false.
--		isDebug = false,
--		-- Order the item relative to other items.
--		order = 42,
--		-- Function defining when to show the menu item. If no function is
--		-- provided, the item is always shown.
--		when = function(...) ... end,
--		-- Menu item to replace this item with if the function provided in
--		-- `when` returns false.
--		otherwise = {},
--
--		-- Top-level items only. If true, the item is 'sticky' and will
--		-- display regardless of which menu is open. Default false.
--		sticky = false,
--	}
-- 
-- Supported menu item `action` values:
--
-- - `nil`: return to top-level menu.
-- - `false`: re-display current menu.
-- - number: go back N menus. Zero is equivalent to `false`. Values greater than the number of preceding menus are equivalent to `nil`.
-- - menu list: display these items.
-- @alias G

require "gn32/lang"

require "gn32/debug"
require "gn32/stdext"

local errhandler = function(err)
	print("Menu error: " .. tostring(err))
	return {
		allowBack = false,
		{
			info = "[Menu Error]",
		},
		{
			info = tostring(err),
		},
	}
end

local errhandler_false = function(err)
	print("Menu error: " .. tostring(err))
	return false
end

local errhandler_nil = function(err)
	print("Menu error: " .. tostring(err))
	return nil
end

--- MenuSet.
-- @section MenuSet

--- Create a new MenuSet, which can be used like a menu list but has an add method for ease of use.
G.MenuSet = function()
	return setmetatable({}, {
		__index = {
			--- Add an entry to this MenuSet.
			-- @function menuSet:add
			-- @param entry The entry to add.
			add = function(self, entry)
				table.insert(self, entry)
			end
		}
	})
end

--- ActionBase.
-- @section ActionBase

local actionbase = {}

--- Create a new ActionBase-derived type, using the given provider implementation.
-- @param provider The provider to use for this instance.
-- @return A constructor function for the new type.
G.ActionBase = function(provider)
	local base = setmetatable(provider, {__index = actionbase})
	return function()
		local v = setmetatable({}, {__index = base})
		actionbase._init(v)
		return v
	end
end

--- Provider.
-- This is the interface that specific implementations must provide to `ActionBase` as `provider`.
-- @section Provider

actionbase = {
	-- Menu impl hooks
	
	--- Get the data table for the given target.
	-- @function provider:_dataFor
	-- @param ... The target to get data for.
	-- @return A unique table corresponding to the given set of target parameters.
	_dataFor = function(self, ...) error("action: _dataFor unimpl") end,
	--- Start showing a menu for the given target.
	-- @function provider:_startMenu
	-- @param ... The target to start showing a menu for.
	_startMenu = function(self, ...) error("action: _startMenu unimpl") end,
	--- Finish showing a menu for the given target.
	-- @function provider:_finishMenu
	-- @param ... The target to finish showing a menu for.
	_finishMenu = function(self, ...) error("action: _finishMenu unimpl") end,
	--- Add a button to the menu for the given target.
	-- @function provider:_addButton
	-- @param button The name of the button.
	-- @param order The ordering of the button.
	-- @param act A callback to call when the button is clicked.
	-- @param ... The target to add a button for.
	_addButton = function(self, button, order, act, ...) error("action: _addButton unimpl") end,
	--- Add an info entry to the menu for the given target.
	-- @function provider:_addInfo
	-- @param info The text of the info entry.
	-- @param order The ordering of the info entry.
	-- @param ... The target to add an info entry for.
	_addInfo = function(self, info, order, ...) error("action: _addInfo unimpl") end,
	--- Return whether the given item should show for the given target.  
	-- This method is optional. If not provided, defaults to showing all items.
	-- @function provider:_shouldShow
	-- @param item The item to check, in standard `action` format.
	-- @param ... The target to check.
	-- @return Whether the item should show.
	_shouldShow = function(self, item, ...) return true end,

	--- Called whenever the menu state is reset. This happens when the user returns to the top-level menu, or by an explicit setMenu call.  
	-- This method is optional.
	-- @function provider:_onReset
	-- @param ... The target of the menu.
	_onReset = function(self, ...) end,
	--- Called whenever the user enters a sub-menu.  
	-- This method is optional.
	-- @function provider:_onPush
	-- @param ... The target of the menu.
	_onPush = function(self, ...) end,
	--- Called whenever the user exits a sub-menu.  
	-- This method is optional.
	-- @function provider:_onPop
	-- @param ... The target of the menu.
	_onPop = function(self, ...) end,
	-- end impl hooks

	_init = function(self)
		self.root = {}
	end,

	--- ActionBase.
	-- @section ActionBase

	--- Add a top-level entry to this Menu
	-- @function actionBase:add
	-- @param entry The entry to add.
	add = function(self, entry)
		table.insert(self.root, entry)
		return self
	end,

	callDebug = function(self, fn, args, ...)
		if debug.enabled.action then
			local sargs = {}
			local starget = {}
			for _, a in ipairs(args) do
				table.insert(sargs, tostring(a))
			end
			for _, t in ipairs{...} do
				table.insert(starget, tostring(t))
			end
			print(fn .. "(" .. table.concat(sargs, ", ") .. "|" .. table.concat(starget, ", ") .. ")")
		end
	end,

	_resolveMenu = function(self, menu, data, reopen, ...)
		self:callDebug("_resolveMenu", {menu, reopen}, ...)

		local base = menu
		local canPush = true

		while true do
			if type(menu) == "function" then
				menu = safecall(errhandler, menu, reopen, ...)

			elseif menu == false or menu == 0 then
				menu = data.currentMenu
				base = menu
				canPush = false
				reopen = true

			elseif type(menu) == "number" then
				if data.stack == nil or #data.stack + 1 <= menu then
					return nil
				end

				for i = 1, menu do
					self:_onPop(...)
					menu = data.stack[#data.stack]
					table.remove(data.stack, #data.stack)
				end
				base = menu
				canPush = false

			else
				return menu, base, canPush
			end
		end
	end,

	_resolveExpand = function(self, expand, ...)
		self:callDebug("_resolveExpand", {expand}, ...)
		while type(expand) == "function" do
			expand = safecall(errhandler_nil, expand, ...)
		end

		return expand
	end,

	_resolveLabel = function(self, label, ...)
		self:callDebug("_resolveLabel", {label}, ...)
		if type(label) == "function" then
			return safecall(
				function(err)
					print("Menu error: " .. tostring(err))
					return "<ERR: " .. tostring(err) .. ">"
				end,
				label,
				...)
		else
			return label
		end
	end,

	_addItem = function(self, item, ...)
		self:callDebug("_addItem", {item}, ...)
		if not self:_shouldShow(item, ...) then
			return
		end

		if item.isDebug and not debug.enabled.menuOptions then
			return
		end

		if item.when and not safecall(errhandler_false, item.when, ...) then
			if item.otherwise then
				item = item.otherwise
			else
				return
			end
		end

		if item.order ~= nil and type(item.order) ~= "number" then
			print("Menu error: order must be a number, got " .. type(item.order))
			item.order = nil
		end

		if item.info then
			self:_addInfo(self:_resolveLabel(item.info, ...), item.order, ...)
		elseif item.button then
			local target = {...}

			self:_addRawButton(self:_resolveLabel(item.button, ...), item.order, item.action, item.allowBack, ...)
		elseif item.expand then
			local expand = self:_resolveExpand(item.expand, ...)
			if expand then
				self:_addItems(expand, ...)
			end
		else
			print("Menu error: item has no info or button? " .. debug.dump(item))
		end
	end,

	_addRawButton = function(self, label, order, action, allowBack, ...)
		local target = {...}
		self:_addButton(label, order, function(...)
			local tx = {}
			for _, t in ipairs(target) do table.insert(tx, t) end
			for _, t in ipairs{ ...  } do table.insert(tx, t) end

			if allowBack ~= false then
				self:_setMenu(action, false, true, table.unpack(tx))
			else
				self:setMenu(action, table.unpack(tx))
			end
		end, ...)
	end,

	_addItems = function(self, items, ...)
		self:callDebug("_addItems", {items}, ...)
		for _, act in ipairs(items) do
			self:_addItem(act, ...)
		end
	end,

	_setMenu = function(self, menu, reopen, push, ...)
		self:callDebug("_setMenu", {menu, reopen, push}, ...)
		local data = self:_dataFor(...)
		local items, base, canPush = self:_resolveMenu(menu, data, reopen, ...)

		if canPush and push then
			self:_onPush(...)
			if data.currentMenu then
				if data.stack == nil then data.stack = {} end
				table.insert(data.stack, data.currentMenu)
			end
		end

		data.currentMenu = base
		if items == nil then
			if not reopen then
				self:_onReset(...)
			end
			data.stack = {}
			data.currentMenu = nil
		end

		local extra = self:_startMenu(...)
		if extra then
			self:_addItems(extra, ...)
		end
		if items then
			local target = {...}
			if items.allowHome ~= false then
				self:_addRawButton("Home", nil, nil, nil, ...)
			end
			if #data.stack > 0 and items.allowBack ~= false then
				self:_addRawButton("Back", nil, 1, nil, ...)
			end
			if items.allowSticky ~= false then
				for _, item in ipairs(self.root) do
					if item.sticky then
						self:_addItem(item, ...)
					end
				end
			end
			self:_addItems(items, ...)
		else
			self:_addItems(self.root, ...)
		end

		self:_finishMenu(...)
	end,

	--- Set the current menu to `menu` for the provided target.
	-- @function actionBase:setMenu
	-- @param menu The menu to set.
	-- @param ... The target to set the menu for.
	setMenu = function(self, menu, ...)
		self:callDebug("setMenu", {menu}, ...)
		local data = self:_dataFor(...)
		self:_onReset(...)
		data.stack = {}
		self:_setMenu(menu, false, false, ...)
	end,

	--- Refresh the currently-displayed menu for the provided target.
	-- @function actionBase:refreshMenu
	-- @param ... The target to refresh the menu for.
	refreshMenu = function(self, ...)
		self:callDebug("refreshMenu", {}, ...)
		local data = self:_dataFor(...)
		self:_setMenu(data.currentMenu, true, false, ...)
	end,
}
