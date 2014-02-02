--[[

	ComputerCraft GUI
	Element hosting a terminal

--]]

local Element			= require "ccgui.Element"
local ElementTerminal	= require "ccgui.paint.ElementTerminal"
local Rectangle			= require "ccgui.geom.Rectangle"

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
	return self.term:asTerm()
end

function TerminalElement:canFocus()
	return self:isVisible()
end

function TerminalElement:showTerminalBlink()
	local bbox = self:inner(self.bbox)
	self:setCursorBlink(self.term:getBlinkState(bbox))
end
function TerminalElement:hideTerminalBlink()
	self:setCursorBlink(false)
end
function TerminalElement:updateTerminalBlink()
	if self:hasFocus() then
		self:showTerminalBlink()
	else
		self:hideTerminalBlink()
	end
end

function TerminalElement:measure(spec)
	-- TODO Improve?
	assert(spec.w:isSpecified(), "terminal element width spec must be specified")
	assert(spec.h:isSpecified(), "terminal element height spec must be specified")
	self.size = Rectangle:new(1, 1, spec.w.value, spec.h.value)
end
function TerminalElement:terminalPaint(ctxt)
	local bbox = self:inner(self.bbox)
	-- Draw terminal
	self.term:draw(ctxt, bbox, self.needsRepaint)
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