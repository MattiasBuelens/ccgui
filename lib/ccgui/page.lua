--[[

	ComputerCraft GUI
	Page

--]]

local FlowContainer		= require "ccgui.FlowContainer"

local Page = FlowContainer.subclass("ccgui.Page")
function Page:initialize(opts)
	super.initialize(self, opts)

	-- Paint layer
	self.layer = ccgui.PaintLayer.new({
		output = self.output or term
	})
	-- Frames per second
	self.fps = opts.fps or 5
	-- Identifier of frame timer
	self.frameTimer = nil

	self:on("beforepaint", self.pageLayout, self)
	self:on("timer", self.pageTimer, self)

	-- Restart timer after drawing frame
	self:on("afterframe", self.restartFrameTimer, self)

	-- Start frame timer
	self:startFrameTimer()
end

function Page:getOutput()
	return self.layer.output
end

function Page:pageLayout()
	-- Fill whole screen
	self:updateLayout(self.layer:getBounds())
end

function Page:drawUnsafe(x, y, text, fgColor, bgColor)
	-- Draw on layer
	self.layer:write(x, y, text, fgColor, bgColor)
end

function Page:show()
	if ccgui.FlowContainer.show(self) then
		self:startFrameTimer()
	end
end

function Page:hide()
	self:stopFrameTimer()
	ccgui.FlowContainer.hide(self)
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

function Page:pageTimer(timerId)
	-- Handle frame timer
	if timerId == self.frameTimer then
		self:frame()
	end
end

function Page:frame()
	if not self.isVisible then return end

	-- Paint
	self:paint()

	-- Paint layer
	self:trigger("beforeframe")
	self.layer:paint()
	self:trigger("afterframe")
end

function Page:repaint()
	if not self.isVisible then return end

	-- Paint
	self:paint()

	-- Force repaint layer
	self:trigger("beforeframe")
	self.layer:repaint()
	self:trigger("afterframe")
end

function Page:reset()
	self.layer:clear()
end

-- Exports
return Page