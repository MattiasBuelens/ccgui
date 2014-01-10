--[[

	ComputerCraft GUI
	Terminal drawing to an element

--]]

local Object			= require "objectlua.Object"
local BufferedScreen	= require "ccgui.paint.BufferedScreen"

-- Terminal which draws on an element
local ElementTerminal = Object:subclass("ccgui.paint.ElementTerminal")
function ElementTerminal:initialize(element)
	-- Target element
	self.element = element
	-- Screen
	self.screen = BufferedScreen:new(0, 0)
	-- Terminal state
	self.curX, self.curY = 1, 1
	self.text = colours.white
	self.back = colours.black
	self.blink = false
	-- Export as term API
	self.term = {}
	for k,v in pairs(term) do
		if self[k] == nil then
			-- Delegate to terminal
			self.term[k] = function(self, ...)
				f(...)
			end
		else
			-- Redirect to own method
			self.term[k] = function(...)
				return self[k](self, ...)
			end
		end
	end
end

function ElementTerminal:asTerm()
	return self.term
end

function ElementTerminal:draw(bbox, repaint)
	-- Draw each strip in the screen
	for lineY,line in ipairs(self.screen.strips) do
		for i,strip in ipairs(line) do
			if repaint or strip.dirty then
				local x = bbox.x + strip:left() - 1
				local y = bbox.y + lineY - 1
				self.element:draw(x, y, strip.str, strip.text, strip.back, bbox)
			end
		end
	end
end
function ElementTerminal:updateSize(bbox)
	self.screen:updateSize(bbox.w, bbox.h, self.back, true)
end
function ElementTerminal:getBlinkState(bbox)
	local x = bbox.x + self.curX - 1
	local y = bbox.y + self.curY - 1
	if bbox:contains(x, y) then
		return self.blink, x, y, self.text
	else
		return false
	end
end

function ElementTerminal:write(str)
	local len = math.min(#str, math.max(0, self:getWidth() - self.curX + 1))
	local strip = self.screen:write(str, self.curX, self.curY, self.text, self.back)
	self.curX = self.curX + len
	self.element:markPaint()
end
function ElementTerminal:getWidth()
	return self.screen.width
end
function ElementTerminal:getHeight()
	return self.screen.height
end
function ElementTerminal:getSize()
	return self:getWidth(), self:getHeight()
end
function ElementTerminal:getCursorPos()
	return self.curX, self.curY
end
function ElementTerminal:isColor()
	return true
end
function ElementTerminal:isColour()
	return self:isColor()
end
function ElementTerminal:setCursorPos(x, y)
	self.curX, self.curY = math.floor(x), math.floor(y)
	self.element:markPaint()
end
function ElementTerminal:setTextColor(text)
	self.text = text
	self.element:markPaint()
end
function ElementTerminal:setTextColour(text)
	return self:setTextColor(text)
end
function ElementTerminal:setBackgroundColor(back)
	self.back = back
	self.element:markPaint()
end
function ElementTerminal:setBackgroundColour(back)
	return self:setBackgroundColor(back)
end
function ElementTerminal:setCursorBlink(blink)
	self.blink = blink or false
	self.element:markPaint()
end
function ElementTerminal:clearLine()
	self.screen:clearLine(self.curY, self.back, true)
	self.element:markPaint()
end
function ElementTerminal:clear()
	self.screen:clear(self.back, true)
	self.element:markPaint()
end
function ElementTerminal:scroll(n)
	self.screen:scroll(n, self.back, true)
	self.element:markPaint()
end

-- Exports
return ElementTerminal