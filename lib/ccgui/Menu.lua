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
	opts.padding = opts.padding or Margins:new(0, 1)

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
	opts.padding = opts.padding or Margins:new(0, 2, 0, 1)
	opts.menu = opts.menu or Menu:new()

	super.initialize(self, opts)

	self:forwardEvent("menuopen")
	self:forwardEvent("menuclose")
	self:on("buttonpress", self.toggleOnClick, self)
	self:on("paint", self.drawArrow, self)
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
function SubMenuButton:openMenu(x, y, up)
	assert(self.bbox ~= nil, "submenu button missing layout")
	if not x then
		-- Open next to button
		local bbox, pbox = self.bbox, self.parent.bbox
		x = pbox.x + pbox.w
		y = bbox.y
		up = false
	end
	return self:getMenu():openMenu(x, y, up)
end
function SubMenuButton:closeMenu(...)
	return self:getMenu():closeMenu(...)
end
function SubMenuButton:closeParentMenu(cascade)
	if self.parent and self.parent.closeMenu then
		self.parent:closeMenu(cascade)
	end
end
function SubMenuButton:drawArrow()
	-- Draw arrow
	self:draw(self.bbox:tr(), ">")
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
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

	self.menuPos = vector.new(1, 1)
	self.menuUp = false

	self.subMenus = {}
	self.openSubMenu = nil

	self:bubbleEvent("menuopen")
	self:on("menuopen", self.handleMenuOpen, self)
	self:on("menuclose", self.handleMenuClose, self)
end

function Menu:addButton(label)
	local button = MenuButton:new{
		text = label
	}
	self:add(button)
	return button
end
function Menu:addSubMenu(label, menu)
	local button = SubMenuButton:new{
		text = label,
		menu = menu
	}
	menu = button:getMenu()
	-- Store menu
	self.subMenus[menu] = true
	-- Add both button and menu
	self:add(button)
	self:add(menu)
	return button
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
		self:markRepaint()
	else
		-- Not our menu
		self:closeMenu()
	end
end
function Menu:handleMenuClose()
	-- Close opened child menu
	if self.openedSubMenu then
		self.openedSubMenu:closeMenu()
		self.openedSubMenu = nil
	end
	-- Hide menu
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