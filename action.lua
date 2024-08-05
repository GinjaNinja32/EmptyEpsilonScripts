-- Module: gn32/action
-- Description: Generic menu system for EE, flexible enough to handle GM buttons, comms menus, and custom station button menus.
--[[
	Any `...` function argument in examples below refers to the target arguments of the menu, which should be specified in implementations.

	Supported menu item list fields:
		{
			allowHome = true, -- Whether to allow returning directly to the top-level menu from this menu. Default true.
			allowBack = true, -- Whether to allow returning to the parent menu. Default true.
			allowSticky = true, -- Whether to allow sticky menu items to display with this menu. Default true.

			{...},
			{...},
			...
		}

	Supported menu item fields:
		{
			-- Exactly one of the following three fields must be present.
			button = "Button Name", -- Name of button, or function(...) returning same.
			info = "Info Text", -- Text for info panel/comms message, or function(...) returning same. Only partially supported in GM menu.
			expand = {}, -- List of menu items to substitute for this item if shown, or function(...) returning same.

			action = ..., -- The action to perform when the button is pressed, or a function returning same. Only valid on `button` items. See below for valid values.
			allowBack = true, -- Whether to allow returning to the current menu after this submenu is entered. Only valid on `button` items. Default true.

			isDebug = false, -- Whether the item is a debug item that should only be displayed when the 'menuOptions' debug toggle is enabled. Default false.
			order = 42, -- Order the item relative to other items.
			when = function(...) ... end, -- Function defining when to show the menu item. If no function is provided, the item is always shown.
			otherwise = {}, -- Menu item to replace this item with if the function provided in `when` returns false.

			sticky = false, -- Top-level items only. If true, the item is 'sticky' and will display regardless of which menu is open. Default false.
		}

	Supported menu item `action` values:
		`nil`: return to top-level menu.
		`false`: re-display current menu.
		menu list: display these items.
]]

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

local actionbase = {
	-- Menu impl hooks
	_dataFor = function(self, ...) error("action: _dataFor unimpl") end,
	_startMenu = function(self, ...) error("action: _startMenu unimpl") end,
	_finishMenu = function(self, ...) error("action: _finishMenu unimpl") end,
	_addButton = function(self, button, order, act, ...) error("action: _addButton unimpl") end,
	_addInfo = function(self, info, order, ...) error("action: _addInfo unimpl") end,
	_shouldShow = function(self, item, ...) return true end,

	_onReset = function(self, ...) end,
	_onPush = function(self, ...) end,
	_onPop = function(self, ...) end,
	-- end impl hooks

	_init = function(self)
		self.root = {}
	end,

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

	_resolveMenu = function(self, menu, reopen, ...)
		self:callDebug("_resolveMenu", {menu, reopen}, ...)
		while type(menu) == "function" do
			menu = safecall(errhandler, menu, reopen, ...)
		end

		return menu
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

			self:_addButton(self:_resolveLabel(item.button, ...), item.order, function(...)
				local targetAndExtra = {}
				for _, t in ipairs(target) do table.insert(targetAndExtra, t) end
				for _, t in ipairs{...} do table.insert(targetAndExtra, t) end

				if item.action and item.allowBack ~= false then
					self:_pushMenu(item.action, table.unpack(targetAndExtra))
				else
					self:setMenu(item.action, table.unpack(targetAndExtra))
				end
			end, ...)
		elseif item.expand then
			local expand = self:_resolveExpand(item.expand, ...)
			if expand then
				self:_addItems(expand, ...)
			end
		else
			print("Menu error: item has no info or button? " .. debug.dump(item))
		end
	end,

	_addItems = function(self, items, ...)
		self:callDebug("_addItems", {items}, ...)
		for _, act in ipairs(items) do
			self:_addItem(act, ...)
		end
	end,

	_setMenu = function(self, menu, reopen, push, ...)
		self:callDebug("_setMenu", {menu, reopen, push}, ...)
		local items = self:_resolveMenu(menu, reopen, ...)
		local data = self:_dataFor(...)

		if push and items then
			self:_onPush(...)
		end
		if push and items and data.currentMenu then
			if data.stack == nil then data.stack = {} end
			table.insert(data.stack, data.currentMenu)
		end

		if items == false then
			menu = data.currentMenu

			items = self:_resolveMenu(menu, true, ...)
		end

		data.currentMenu = menu
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
				self:_addButton("Home", nil, function() self:setMenu(nil, table.unpack(target)) end, ...)
			end
			if #data.stack > 0 and items.allowBack ~= false then
				self:_addButton("Back", nil, function() self:_popMenu(table.unpack(target)) end, ...)
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

	_pushMenu = function(self, menu, ...)
		self:callDebug("_pushMenu", {menu}, ...)
		local data = self:_dataFor(...)
		self:_setMenu(menu, false, true, ...)
	end,

	_popMenu = function(self, ...)
		self:callDebug("_popMenu", {}, ...)
		local data = self:_dataFor(...)
		if data.stack == nil or #data.stack == 0 then
			self:_setMenu(nil, false, false, ...)
			return
		end

		self:_onPop(...)
		local menu = data.stack[#data.stack]
		table.remove(data.stack, #data.stack)

		self:_setMenu(menu, false, false, ...)
	end,

	setMenu = function(self, menu, ...)
		self:callDebug("setMenu", {menu}, ...)
		local data = self:_dataFor(...)
		self:_onReset(...)
		data.stack = {}
		self:_setMenu(menu, false, false, ...)
	end,

	refreshMenu = function(self, ...)
		self:callDebug("refreshMenu", {}, ...)
		local data = self:_dataFor(...)
		self:_setMenu(data.currentMenu, true, false, ...)
	end,
}

G.ActionBase = function(provider)
	local base = setmetatable(provider, {__index = actionbase})
	return function()
		local v = setmetatable({}, {__index = base})
		actionbase._init(v)
		return v
	end
end
