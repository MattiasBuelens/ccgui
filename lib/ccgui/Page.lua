--[[

	ComputerCraft GUI
	Page

--]]

local FlowContainer		= require "ccgui.FlowContainer"
local BufferedTerminal	= require "ccgui.BufferedTerminal"
local Rectangle			= require "ccgui.geom.Rectangle"

local Page = FlowContainer:subclass("ccgui.Page")
function Page:initialize(opts)
	opts.background = colors.white
	super.initialize(self, opts)

	self.term = BufferedTerminal:new(self.output)
	-- Frames per second
	self.fps = opts.fps or 8
	-- Identifier of frame timer
	self.frameTimer = nil

	self:on("beforepaint", self.pageLayout, self)
	self:on("afterpaint", self.pagePaint, self)
	self:on("timer", self.pageFrameTimer, self)

	-- Start frame timer
	self:startFrameTimer()
end

function Page:getOutput()
	return self.term:asTerm()
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
	self.term:paint()
end

function Page:reset()
	self:stopFrameTimer()
	self.term:setBackgroundColor(colours.black)
	self.term:clear()
	self.term:setCursorPos(1, 1)
end

-- Exports
return Page