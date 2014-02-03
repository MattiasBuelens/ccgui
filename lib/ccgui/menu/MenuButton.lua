--[[

	ComputerCraft GUI
	Menu button

--]]

local Button		= require "ccgui.Button"
local Margins		= require "ccgui.geom.Margins"

local MenuButton = Button:subclass("ccgui.menu.MenuButton")
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

-- Exports
return MenuButton