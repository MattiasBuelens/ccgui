--[[

	ComputerCraft GUI
	Menu

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local Margins		= require "ccgui.geom.Margins"
local Rectangle		= require "ccgui.geom.Rectangle"
local MenuButton	= require "ccgui.MenuButton"
local SubMenuButton	= require "ccgui.SubMenuButton"

local Menu = FlowContainer:subclass("ccgui.Menu")
function Menu:initialize(opts)
	opts.horizontal = false
	opts.visible = false
	opts.absolute = true
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

	self.menuPos = vector.new(1, 1)
	self.menuUp = false

	self.subMenus = {}
	self.openSubMenu = nil

	self:on("menuopen", self.handleMenuOpen, self)
	self:on("menuclose", self.handleMenuClose, self)
end

function Menu:addButton(button)
	-- Create button
	if type(button) == "string" then
		button = MenuButton:new{
			text = button
		}
	end
	-- Add button
	self:add(button)
	return button
end
function Menu:addSubMenu(button, menu)
	-- Create button
	if type(button) == "string" then
		button = SubMenuButton:new{
			text = button,
			menu = menu or Menu:new()
		}
	end
	-- Store menu
	menu = button:getMenu()
	self.subMenus[menu] = true
	-- Add both button and menu
	self:add(button)
	self:add(menu)
	return button
end

function Menu:isMenuOpen()
	return self:isVisible()
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
		-- Bubble up to parent
		if self.parent then
			self.parent:trigger("menuopen", self)
		end
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

function Menu:markRepaint()
	if not self.needsRepaint then
		-- Repaint parent menu
		if self.parent ~= nil then
			self.parent:markRepaint()
		end
	end
	super.markRepaint(self)
end
function Menu:calcSize(size)
	-- Calculate with unlimited space
	size = Rectangle:new(size:tl(), math.huge, math.huge)
	return super.calcSize(self, size)
end
function Menu:calcLayout(bbox)
	-- Open at menu position
	if self.menuUp then
		bbox.x, bbox.y = self.menuPos.x, self.menuPos.y - bbox.h + 1
	else
		bbox.x, bbox.y = self.menuPos.x, self.menuPos.y
	end
	return super.calcLayout(self, bbox)
end
function Menu:contains(x, y)
	return super.contains(self, x, y) or (self.openedSubMenu and self.openedSubMenu:contains(x, y))
end

-- Exports
return Menu