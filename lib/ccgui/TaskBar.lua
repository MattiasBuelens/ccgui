--[[

	ComputerCraft GUI
	Task bar

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local Button		= require "ccgui.Button"
local TextElement	= require "ccgui.TextElement"
local Margins		= require "ccgui.geom.Margins"
local ClockDisplay	= require "ccgui.ClockDisplay"

local TaskMenuButton = Button:subclass("ccgui.TaskMenuButton")
function TaskMenuButton:initialize(opts)
	opts.padding = opts.padding or 0

	super.initialize(self, opts)

	--self:on("buttonpress", self.hideMenu, self, 1000)
end
function TaskMenuButton:hideMenu(bbox)
	-- Hide parent menu
	if self.parent then
		self.parent:hide()
	end
end

local TaskMenu = FlowContainer:subclass("ccgui.TaskMenu")
function TaskMenu:initialize(opts)
	opts.horizontal = false
	opts.padding = opts.padding or Margins:new(0, 1)
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

	self.shutdownButton = TaskMenuButton:new{
		text = "Shut down",
		foreground = colours.red
	}
	self.exitButton = TaskMenuButton:new{
		text = "Exit"
	}
	self:add(self.shutdownButton, self.exitButton)
	
	self.shutdownButton:on("buttonpress", function()
		os.shutdown()
	end)
end
function TaskMenu:markRepaint()
	if not self.needsRepaint then
		-- Repaint parent task bar
		if self.parent then
			self.parent:markRepaint()
		end
	end
	super.markRepaint(self)
end
function TaskMenu:calcLayout(bbox)
	-- Clip to top left of parent container
	if self.parent then
		local pbox = self.parent.bbox
		bbox.x = pbox.x
		bbox.y = pbox.y - bbox.h
	end
	super.calcLayout(self, bbox)
end

local TaskBar = FlowContainer:subclass("ccgui.TaskBar")
function TaskBar:initialize(opts)
	opts.horizontal = true
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

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
	
	self.menu = TaskMenu:new{
		parent = self,
		isVisible = false
	}

	self.startButton:on("buttonpress", self.toggleMenu, self)
	self:on("paint", self.menuPaint, self)
	self:on("window_background", self.hideMenu, self)
	self:on("mouse_click", self.foregroundOnClick, self)
end

function TaskBar:isMenuVisible()
	return self.menu:visible()
end
function TaskBar:showMenu()
	self.menu:show()
end
function TaskBar:hideMenu()
	self.menu:hide()
end
function TaskBar:toggleMenu()
	if not self:isMenuVisible() then
		self:showMenu()
	else
		self:hideMenu()
	end
end

function TaskBar:menuPaint()
	if self:isMenuVisible() then
		self.menu:paint()
	end
end

function TaskBar:calcLayout(bbox)
	if self.parent then
		local pbox = self.parent:inner(self.parent.bbox)
		-- Clip to bottom of parent container
		bbox.y = pbox.y + pbox.h - bbox.h
		-- Layout menu
		if self:isMenuVisible() then
			self.menu:updateLayout(pbox)
		end
	end
	super.calcLayout(self, bbox)
end
function TaskBar:contains(x, y)
	return super.contains(self, x, y) or (self:isMenuVisible() and self.menu:contains(x, y))
end

-- Window-like behaviour
function TaskBar:isForeground()
	if not self:visible() then
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
	if button == 1 and self:visible() and self:contains(x, y) then
		self:bringToForeground()
	end
end

-- Exports
return TaskBar