--[[

	ComputerCraft GUI
	Menu

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local Button		= require "ccgui.Button"
local Margins		= require "ccgui.geom.Margins"

local MenuButton	= Button:subclass("ccgui.MenuButton")
local SubMenuButton	= Button:subclass("ccgui.SubMenuButton")
local Menu			= FlowContainer:subclass("ccgui.Menu")

--[[

	Menu button

]]--
function MenuButton:initialize(opts)
	opts.padding = opts.padding or 0

	super.initialize(self, opts)

	self:on("buttonpress", self.closeOnClick, self)
end
function MenuButton:closeParentMenu(cascade)
	if self.parent and self.parent.closeMenu then
		self.parent:closeMenu(cascade)
	end
end
function MenuButton:closeOnClick()
	self:closeParentMenu(true)
end

--[[

	Sub menu button

]]--
function SubMenuButton:initialize(opts)
	opts.padding = opts.padding or 0
	opts.menu = opts.menu or Menu:new()

	super.initialize(self, opts)

	self:forwardEvent("menuopen")
	self:forwardEvent("menuclose")
	self:on("buttonpress", self.toggleOnClick, self)
end
function SubMenuButton:getMenu()
	return self.menu
end
function SubMenuButton:addButton(...)
	return self:getMenu():addButton(...)
end
function SubMenuButton:addSubMenu(...)
	return self:getMenu():addSubMenu(...)
end
function SubMenuButton:isMenuOpen()
	return self:getMenu():isMenuOpen()
end
function SubMenuButton:openMenu(x, y)
	assert(self.bbox ~= nil, "submenu button missing layout")
	if not x then
		-- Open next to button
		local corner = self.bbox:tr()
		x, y = corner.x, corner.y
	end
	return self:getMenu():openMenu(x, y)
end
function SubMenuButton:closeMenu(...)
	return self:getMenu():closeMenu(...)
end
function SubMenuButton:closeParentMenu(cascade)
	if self.parent and self.parent.closeMenu then
		self.parent:closeMenu(cascade)
	end
end

function SubMenuButton:toggleOnClick()
	if not self:isMenuOpen() then
		self:openMenu()
	else
		self:closeMenu()
	end
end
function SubMenuButton:forwardEvent(event)
	self:on(event, function(self, ...)
		self:getMenu():trigger(event, ...)
	end, self)
end

--[[

	Menu

]]--
function Menu:initialize(opts)
	opts.horizontal = false
	opts.isVisible = false
	opts.absolute = true
	opts.padding = opts.padding or Margins:new(0, 1)
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

	self.menuPos = vector.new(1, 1)
	self.menuUp = false

	self.subMenus = {}
	self.openSubMenu = nil

	self:sinkEvent("menuclose")
	self:on("menuopen", self.handleMenuOpen, self)
	self:on("menuclose", self.handleMenuClose, self)
end

function Menu:addButton(label)
	local item = MenuButton:new{
		text = label
	}
	self:add(item)
	return item
end
function Menu:addSubMenu(label, menu)
	local subMenu = SubMenuButton:new{
		text = label,
		menu = menu
	}
	self:add(subMenu)
	-- Store menu
	self.subMenus[subMenu:getMenu()] = true
	return subMenu
end

function Menu:isMenuOpen()
	return self:visible()
end
function Menu:openMenu(x, y, up)
	self.menuPos = vector.new(x, y)
	self.menuUp = not not up
	self:trigger("menuopen", self)
end
function Menu:closeMenu(cascade)
	if cascade and self.parent and self.parent.closeMenu then
		self.parent:closeMenu(cascade)
	else
		self:trigger("menuclose")
	end
end

function Menu:handleMenuOpen(openedMenu)
	if self == openedMenu then
		-- Show menu
		self:show()
	elseif self.subMenus[openedMenu] then
		-- Close previously opened child menu
		if self.openedSubMenu and self.openedSubMenu ~= openedMenu then
			self.openedSubMenu:closeMenu()
		end
		-- Store currently opened menu
		self.openedSubMenu = openedMenu
	else
		-- Not our menu
		self:closeMenu()
	end
end
function Menu:handleMenuClose()
	-- Hide menu
	self.openedSubMenu = nil
	self:hide()
end

function Menu:calcLayout(bbox)
	-- Open at menu position
	if self.menuUp then
		bbox.x, bbox.y = self.menuPos.x, self.menuPos.y - bbox.h
	else
		bbox.x, bbox.y = self.menuPos.x, self.menuPos.y
	end
	super.calcLayout(self, bbox)
end
function Menu:contains(x, y)
	return super.contains(self, x, y) or (self.openedSubMenu and self.openedSubMenu:contains(x, y))
end

-- Exports
return Menu