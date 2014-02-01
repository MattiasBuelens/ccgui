--[[

	ComputerCraft GUI
	Child draw context

--]]

local DrawContext	= require "ccgui.paint.DrawContext"

local ChildDrawContext = DrawContext:subclass("ccgui.paint.ChildDrawContext")
function ChildDrawContext:initialize(parent, x, y, clip)
	super.initialize(self, x, y, clip)
	-- Parent context
	self.parent = assert(parent)
end

function ChildDrawContext:rawDraw(x, y, text, fgColor, bgColor)
	-- Draw on parent
	self.parent:draw(x, y, text, fgColor, bgColor)
end

-- Exports
return ChildDrawContext