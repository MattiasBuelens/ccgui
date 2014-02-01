--[[

	ComputerCraft GUI
	Terminal draw context

--]]

local DrawContext	= require "ccgui.paint.DrawContext"

local TerminalDrawContext = DrawContext:subclass("ccgui.TerminalDrawContext")
function TerminalDrawContext:initialize(term, x, y, clip)
	super.initialize(self, x, y, clip)
	-- Terminal
	self.term = assert(term)
end

function TerminalDrawContext:rawDraw(x, y, text, fgColor, bgColor)
	-- Remove colors when not supported
	fgColor = self.term:isColor() and fgColor or colours.white
	bgColor = self.term:isColor() and bgColor or colours.black
	-- Draw on terminal
	self.term:writeBuffer(text, x, y, fgColor, bgColor)
end

-- Exports
return TerminalDrawContext