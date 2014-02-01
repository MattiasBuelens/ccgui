--[[

	ComputerCraft GUI OS
	Task bar

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local Button		= require "ccgui.Button"
local Margins		= require "ccgui.geom.Margins"
local StartMenu		= require "ccgui.os.StartMenu"
local ClockDisplay	= require "ccgui.os.ClockDisplay"

local TaskBar = FlowContainer:subclass("ccgui.os.TaskBar")
function TaskBar:initialize(opts)
	opts.horizontal = true
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

	-- Target window container
	self.windows = opts.windows

	self.startForeground = opts.startForeground or colours.white
	self.startBackground = opts.startBackground or colours.grey
	self.barForeground = opts.barForeground or self.foreground
	self.barBackground = opts.barBackground or 0
	self.clockForeground = opts.clockForeground or colours.grey
	self.clockBackground = opts.clockBackground or self.barBackground
	
	self.startButton = Button:new{
		text = "Start",
		padding = Margins:new(0, 1),
		foreground = self.startForeground,
		background = self.startBackground
	}
	self.bar = FlowContainer:new{
		stretch = true,
		horizontal = true,
		foreground = self.barForeground,
		background = self.barBackground
	}
	self.clockText = ClockDisplay:new{
		foreground = self.clockForeground,
		background = self.clockBackground
	}
	self:add(self.startButton, self.bar, self.clockText)
	
	self.menu = StartMenu:new{
		windows = self.windows
	}
	self:add(self.menu)

	self.startButton:on("buttonpress", self.toggleMenu, self)
	self:on("window_background", self.closeMenu, self)
	self:on("mouse_click", self.foregroundOnClick, self)
end

function TaskBar:isMenuOpen()
	return self.menu:isMenuOpen()
end
function TaskBar:openMenu()
	assert(self.bbox ~= nil, "taskbar missing layout")
	self.menu:openMenu(self.bbox.x, self.bbox.y - 1, true)
end
function TaskBar:closeMenu()
	self.menu:closeMenu()
end
function TaskBar:toggleMenu()
	if not self:isMenuOpen() then
		self:openMenu()
	else
		self:closeMenu()
	end
end

function TaskBar:layout(bbox)
	-- Clip to bottom of parent container
	if self.parent then
		local pbox = self.parent:inner(self.parent.bbox)
		bbox.y = pbox.y + pbox.h - bbox.h
	end
	super.layout(self, bbox)
end
function TaskBar:contains(x, y)
	return super.contains(self, x, y) or (self:isMenuOpen() and self.menu:contains(x, y))
end

-- Window-like behaviour
function TaskBar:isForeground()
	if not self:isVisible() then
		return false
	end
	if self.parent then
		return self == self.parent:getForegroundWindow()
	end
	return true
end
function TaskBar:bringToForeground()
	self.parent:bringToForeground(self)
end
function TaskBar:markRepaint()
	if not self.needsRepaint then
		-- Repaint parent window container
		if self.parent ~= nil then
			self.parent:markRepaint()
		end
	end
	super.markRepaint(self)
end
function TaskBar:foregroundOnClick(button, x, y)
	-- Bring to foreground on click
	if button == 1 and self:isVisible() and self:contains(x, y) then
		self:bringToForeground()
	end
end

-- Exports
return TaskBar