--[[

	ComputerCraft GUI
	Page

--]]

local FlowContainer		= require "ccgui.FlowContainer"
local PaintLayer		= require "ccgui.PaintLayer"

local Page = FlowContainer:subclass("ccgui.Page")
function Page:initialize(opts)
	super.initialize(self, opts)

	-- Paint layer
	self.layer = PaintLayer:new{
		output = self.output or term
	}

	self:on("beforepaint", self.pageLayout, self)
	self:on("afterpaint", self.drawLayer, self)
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

function Page:drawLayer()
	self.layer:paint()
end

function Page:reset()
	self.layer:clear()
end

-- Exports
return Page