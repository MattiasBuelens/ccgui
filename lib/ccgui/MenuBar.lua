--[[

	ComputerCraft GUI
	Menu bar

--]]

local Menu			= require "ccgui.Menu"
local SubMenuButton	= require "ccgui.SubMenuButton"
local Margins		= require "ccgui.geom.Margins"

local MenuBarButton = SubMenuButton:subclass("ccgui.MenuBarButton")
function MenuBarButton:initialize(opts)
	opts.padding = opts.padding or Margins:new(0, 1, 0, 1)

	super.initialize(self, opts)
end
function MenuBarButton:openMenu()
	assert(self.bbox ~= nil, "menu bar button missing layout")
	-- Open relative to button
	local bbox = self.bbox
	local x, y, up = 0, 0, self.parent.menuUp
	if up then
		x, y = bbox.x, bbox.y - 1
	else
		x, y = bbox.x, bbox.y + bbox.h
	end
	return super.openMenu(self, x, y, up)
end
function MenuBarButton:drawArrow(ctxt)
	-- Don't draw arrow
end

local MenuBar = Menu:subclass("ccgui.MenuBar")
function MenuBar:initialize(opts)
	-- Default style
	opts.horizontal = true
	opts.absolute = false
	opts.visible = (opts.visible == nil) or (not not opts.visible)
	opts.foreground = opts.foreground or colours.grey
	opts.background = opts.background or colours.lightGrey
	
	super.initialize(self, opts)
	
	-- Menu direction
	self.menuUp = opts.menuUp or false
end

function MenuBar:addMenu(button, menu)
	-- Create button
	if type(button) == "string" then
		button = MenuBarButton:new{
			text = button,
			menu = menu or Menu:new{},
			menuUp = self.menuUp
		}
	end
	return super.addSubMenu(self, button, menu)
end

function MenuBar:closeMenu(cascade)
	-- Ignore
end

function MenuBar:menuBeforeMeasure(spec)
	return spec
end
function MenuBar:menuBeforeLayout(bbox)
	return bbox
end

-- Exports
return MenuBar