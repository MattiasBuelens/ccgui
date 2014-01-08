--[[

	ComputerCraft GUI
	Element hosting a terminal

--]]

local Element			= require "ccgui.Element"
local ElementTerminal	= require "ccgui.paint.ElementTerminal"

-- Element hosting a terminal
local TerminalElement = Element:subclass("ccgui.TerminalElement")
function TerminalElement:initialize(opts)
	super.initialize(self, opts)

	self.term = ElementTerminal:new(self)

	self:on("focus", self.showTerminalBlink, self)
	self:on("blur", self.hideTerminalBlink, self)

	self:on("beforepaint", self.terminalResize, self)
	self:on("paint", self.terminalPaint, self)
end

function TerminalElement:asTerm()
	return self.term:export()
end

function TerminalElement:canFocus()
	return self:visible()
end

function TerminalElement:showTerminalBlink()
	local bbox = self:inner(self.bbox)
	self:setCursorBlink(self.term:getBlinkState(bbox))
end
function TerminalElement:hideTerminalBlink()
	self:setCursorBlink(false)
end
function TerminalElement:updateTerminalBlink()
	if self.hasFocus then
		self:showTerminalBlink()
	else
		self:hideTerminalBlink()
	end
end

function TerminalElement:terminalPaint()
	local bbox = self:inner(self.bbox)
	-- Draw terminal
	self.term:draw(bbox, self.needsRepaint)
	-- Update cursor blink
	self:updateTerminalBlink()
end
function TerminalElement:terminalResize()
	local bbox = self:inner(self.bbox)
	-- Update terminal size
	self.term:updateSize(bbox)
end

-- Exports
return TerminalElement