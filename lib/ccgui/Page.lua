--[[

	ComputerCraft GUI
	Page

--]]

local FlowContainer		= require "ccgui.FlowContainer"
local BufferedTerminal	= require "ccgui.paint.BufferedTerminal"
local Rectangle			= require "ccgui.geom.Rectangle"
local Thread			= require "concurrent.Thread"
local Scheduler			= require "concurrent.Scheduler"

local Page = FlowContainer:subclass("ccgui.Page")
function Page:initialize(opts)
	super.initialize(self, opts)

	self.term = BufferedTerminal:new(self.output)
	-- Frames per second
	self.fps = opts.fps or 8
	-- Identifier of frame timer
	self.frameTimer = nil
	-- Thread
	self.scheduler = opts.scheduler or Scheduler:new()
	self.pageThread = Thread:new(function()
		self:loop()
	end)
	self.pageRunning = false

	self:on("beforepaint", self.pageLayout, self)
	self:on("afterpaint", self.pagePaint, self)
	self:on("timer", self.pageFrameTimer, self)
end

function Page:setCursorBlink(blink, x, y, color)
	if blink then
		color = self.term:isColor() and color or colours.white
		self.term:setCursorPos(x, y)
		self.term:setTextColor(color)
		self.term:setCursorBlink(true)
	else
		self.term:setCursorBlink(false)
	end
	return true
end

function Page:pageLayout()
	-- Fill whole screen
	local width, height = self.term:getSize()
	self:updateLayout(Rectangle:new(1, 1, width, height))
end

function Page:drawUnsafe(x, y, text, fgColor, bgColor)
	-- Fill in transparency
	fgColor = fgColor ~= 0 and fgColor or self.foreground
	bgColor = bgColor ~= 0 and bgColor or self.background
	-- Remove colors when not supported
	fgColor = self.term:isColor() and fgColor or colours.white
	bgColor = self.term:isColor() and bgColor or colours.black
	-- Draw on terminal
	self.term:writeBuffer(text, x, y, fgColor, bgColor)
end

function Page:show()
	if super.show(self) then
		self:startFrameTimer()
	end
end

function Page:hide()
	self:stopFrameTimer()
	super.hide(self)
end

function Page:startFrameTimer()
	if self.frameTimer == nil then
		self:restartFrameTimer()
	end
end

function Page:restartFrameTimer()
	self.frameTimer = os.startTimer(1 / self.fps)
end

function Page:stopFrameTimer()
	self.frameTimer = nil
end

function Page:pageFrameTimer(timerId)
	if timerId == self.frameTimer then
		self:paint()
		self:restartFrameTimer()
	end
end

function Page:pagePaint()
	if self.needsRepaint then
		self.term:repaint()
	else
		self.term:paint()
	end
end

function Page:reset()
	self:stopFrameTimer()
	self.term:setBackgroundColor(colours.black)
	self.term:clear()
	self.term:setCursorPos(1, 1)
end

function Page:isRunning()
	return self.pageThread:isAlive()
end
function Page:start()
	self.pageRunning = true
	if not self:isRunning() then
		self.pageThread:start(self:getScheduler())
	end
end
function Page:stop()
	self.pageRunning = false
end
function Page:run()
	self:start()
	self.scheduler:run()
	self:stop()
end
function Page:loop()
	-- Setup
	self:paint()
	self:startFrameTimer()
	-- Event loop
	while self.pageRunning do
		local eventData = { os.pullEventRaw() }
		self:trigger(unpack(eventData))
		if eventData[1] == "terminate" then
			error("Terminated", 0)
		end
	end
	-- Teardown
	self:stopFrameTimer()
end

-- Exports
return Page