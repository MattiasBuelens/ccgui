--[[

	ComputerCraft GUI
	Page

--]]

local FlowContainer		= require "ccgui.FlowContainer"
local BufferedTerminal	= require "ccgui.BufferedTerminal"

local Page = FlowContainer:subclass("ccgui.Page")
function Page:initialize(opts)
	opts.background = colors.white
	super.initialize(self, opts)

	self.term = BufferedTerminal.new(self.output)

	self:on("beforepaint", self.pageLayout, self)
	self:on("afterpaint", self.drawLayer, self)
end

function Page:getOutput()
	return self.term
end

function Page:pageLayout()
	-- Fill whole screen
	self:updateLayout(self.term.getBounds())
end

function Page:drawUnsafe(x, y, text, fgColor, bgColor)
	-- Fill in transparency
	fgColor = (fgColor ~= 0 and fgColor) or self.foreground
	bgColor = (bgColor ~= 0 and bgColor) or self.background
	-- Remove colors when not supported
	fgColor = self.term.isColor() and fgColor or colours.white
	bgColor = self.term.isColor() and bgColor or colours.black
	-- Draw on terminal
	self.term.write(text, x, y, fgColor, bgColor)
end

function Page:drawLayer()
	self.term.draw()
end

function Page:reset()
	self.term.clear()
	self.term.setCursorPos(1, 1)
end

-- Exports
return Page