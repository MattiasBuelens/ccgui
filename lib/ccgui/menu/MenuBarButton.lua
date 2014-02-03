--[[

	ComputerCraft GUI
	Menu bar button

--]]

local SubMenuButton	= require "ccgui.menu.SubMenuButton"
local Margins		= require "ccgui.geom.Margins"

local MenuBarButton = SubMenuButton:subclass("ccgui.menu.MenuBarButton")
function MenuBarButton:initialize(opts)
	opts.padding = opts.padding or Margins:new(0, 1, 0, 1)

	super.initialize(self, opts)
	
	self.menuUp = opts.menuUp or false
end
function MenuBarButton:openMenu()
	assert(self.bbox ~= nil, "menu bar button missing layout")
	-- Open relative to button
	local bbox = self.bbox
	local x, y = 0, 0
	if self.menuUp then
		x, y = bbox.x, bbox.y - 1
	else
		x, y = bbox.x, bbox.y + bbox.h
	end
	return super.openMenu(self, x, y, self.menuUp)
end
function MenuBarButton:drawArrow(ctxt)
	-- Don't draw arrow
end

-- Exports
return MenuBarButton