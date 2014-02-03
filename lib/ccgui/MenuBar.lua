--[[

	ComputerCraft GUI
	Menu bar

--]]

local Menu			= require "ccgui.Menu"
local MenuBarButton	= require "ccgui.MenuBarButton"

local MenuBar = Menu:subclass("ccgui.MenuBar")
function MenuBar:initialize(opts)
	-- Default style
	opts.horizontal = true
	opts.absolute = false
	opts.visible = (opts.visible == nil) or (not not opts.visible)
	opts.zIndex = opts.zIndex or 100
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