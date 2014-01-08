--[[

	ComputerCraft GUI
	Terminal element

--]]

local Element			= require "ccgui.Element"
local BufferedScreen	= require "ccgui.paint.BufferedScreen"

local TerminalElement = Element:subclass("ccgui.TerminalElement")
function TerminalElement:initialize(opts)
	super.initialize(self, opts)
	-- Screen
	self.screen = BufferedScreen:new(0, 0)
	-- Terminal state
	self.curX, self.curY = 1, 1
	self.text = colours.white
	self.back = colours.black
	self.blink = false
	-- Delegate terminal methods
	for k,f in pairs(term) do
		if self[k] == nil then
			self[k] = function(self, ...)
				return f(...)
			end
		end
	end
	self:on("beforepaint", self.terminalResize, self)
	self:on("paint", self.terminalPaint, self)
end

function TerminalElement:asTerm()
	-- Create delegate which matches the term API
	local exported = {}
	for k,v in pairs(term) do
		-- Redirect to own method
		exported[k] = function(...)
			return self[k](self, ...)
		end
	end
	return exported
end

function TerminalElement:getWidth()
	return self.screen.width
end
function TerminalElement:getHeight()
	return self.screen.height
end

-- Draw screen
function TerminalElement:terminalPaint()
	local bbox = self:inner(self.bbox)
	-- Draw each strip in the screen
	for lineY,line in ipairs(self.screen.strips) do
		for i,strip in ipairs(line) do
			if self.needsRepaint or strip.dirty then
				local x = bbox.x + strip:left() - 1
				local y = bbox.y + lineY - 1
				self:draw(x, y, strip.str, strip.text, strip.back, bbox)
			end
		end
	end
	-- Update cursor blink
	self:terminalUpdateBlink()
end
function TerminalElement:terminalResize()
	local bbox = self:inner(self.bbox)
	self.screen:updateSize(bbox.w, bbox.h, self.back)
end
function TerminalElement:terminalUpdateBlink()
	super:setCursorBlink(self.blink, self.curX, self.curY, self.text)
end

-- Delegated methods to capture changes
function TerminalElement:write(str)
	--local len = math.min(#str, math.max(0, self:getWidth() - self.curX + 1))
	local len = #str
	local strip = self.screen:write(str, self.curX, self.curY, self.text, self.back)
	self.curX = self.curX + len
	self:markPaint()
end
function TerminalElement:getSize()
	return self:getWidth(), self:getHeight()
end
function TerminalElement:getCursorPos()
	return self.curX, self.curY
end
function TerminalElement:isColor()
	return true
end
TerminalElement.isColour = TerminalElement.isColour
function TerminalElement:setCursorPos(x, y)
	self.curX, self.curY = x, y
	self:terminalUpdateBlink()
end
function TerminalElement:setTextColor(text)
	self.text = text
	self:terminalUpdateBlink()
end
TerminalElement.setTextColour = TerminalElement.setTextColor
function TerminalElement:setBackgroundColor(back)
	self.back = back
	self:terminalUpdateBlink()
end
TerminalElement.setBackgroundColour = TerminalElement.setBackgroundColor
function TerminalElement:setCursorBlink(blink)
	self.blink = blink or false
	self:terminalUpdateBlink()
end
function TerminalElement:clearLine()
	self.screen:clearLine(self.curY, self.back, false)
	self:markPaint()
end
function TerminalElement:clear()
	self.screen:clear(self.back, false)
	self:markPaint()
end
function TerminalElement:scroll(n)
	self.screen:scroll(n, self.back, false)
	self:markPaint()
end

-- Exports
return TerminalElement