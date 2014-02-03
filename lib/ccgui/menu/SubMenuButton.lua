--[[

	ComputerCraft GUI
	Sub menu button

--]]

local Button		= require "ccgui.Button"
local Margins		= require "ccgui.geom.Margins"

local SubMenuButton	= Button:subclass("ccgui.menu.SubMenuButton")
function SubMenuButton:initialize(opts)
	opts.padding = opts.padding or Margins:new(0, 2, 0, 1)

	super.initialize(self, opts)

	-- Sub menu
	self.menu = opts.menu

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
		up = self.parent.menuUp
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
function SubMenuButton:drawArrow(ctxt)
	-- Draw arrow
	ctxt:draw(self.bbox:tr(), ">", self:getForeground(), self:getBackground())
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

-- Exports
return SubMenuButton