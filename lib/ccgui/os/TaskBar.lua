--[[

	ComputerCraft GUI OS
	Task bar

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local MenuBar		= require "ccgui.menu.MenuBar"
local MenuBarButton	= require "ccgui.menu.MenuBarButton"
local Margins		= require "ccgui.geom.Margins"
local StartMenu		= require "ccgui.os.StartMenu"
local ClockDisplay	= require "ccgui.os.ClockDisplay"

local TaskBar = MenuBar:subclass("ccgui.os.TaskBar")
function TaskBar:initialize(opts)
	super.initialize(self, opts)

	-- Target window container
	self.windows = opts.windows

	self.startForeground = opts.startForeground or colours.white
	self.startBackground = opts.startBackground or colours.grey
	self.barForeground = opts.barForeground or self.foreground
	self.barBackground = opts.barBackground or 0
	self.clockForeground = opts.clockForeground or colours.grey
	self.clockBackground = opts.clockBackground or self.barBackground
	
	self.startMenu = StartMenu:new{
		windows = self.windows
	}
	self.startButton = MenuBarButton:new{
		text = "Start",
		menu = self.startMenu,
		menuUp = true,
		padding = Margins:new(0, 1),
		foreground = self.startForeground,
		background = self.startBackground
	}
	self:addMenu(self.startButton)
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
	self:add(self.bar, self.clockText)
end

-- Exports
return TaskBar