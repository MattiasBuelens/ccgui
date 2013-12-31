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

	self:on("key", self.pageKey, self)
	self:on("beforepaint", self.pageLayout, self)
	self:on("afterpaint", self.pagePaint, self)
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

function Page:pagePaint()
	self.term:paint()
end

-- TODO DEBUG
function Page:pageKey(key)
	if key == keys.leftShift then
		-- Dump terminal to file
		local buffer = self.term:dump()
		local fh = fs.open("/buffer.dmp", "w")
		fh.write(buffer)
		fh.close()
	end
end

function Page:reset()
	self.term:setBackgroundColor(colours.black)
	self.term:clear()
	self.term:setCursorPos(1, 1)
end

-- Exports
return Page