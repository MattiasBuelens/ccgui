--[[

	ComputerCraft GUI
	Element terminal

--]]

local Object			= require "objectlua.Object"
local BufferedScreen	= require "ccgui.paint.BufferedScreen"

local ElementTerminal = Object:subclass("ccgui.paint.ElementTerminal")
function ElementTerminal:initialize(element)
	-- Output element
	self.element = element
	-- Screen
	self.screen = BufferedScreen:new(self:getSize())
	-- Terminal state
	self.curX, self.curY = 1, 1
	self.text = colours.white
	self.back = colours.black
	self.blink = true
	-- Delegate terminal methods
	for k,f in pairs(term) do
		if self[k] == nil then
			self[k] = function(self, ...)
				return f(...)
			end
		end
	end
end

function ElementTerminal:export()
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

function ElementTerminal:getWidth()
	local size = self.element.size
	return size and size.w or 0
end
function ElementTerminal:getHeight()
	local size = self.element.size
	return size and size.h or 0
end
function ElementTerminal:getSize()
	local size = self.element.size
	if size then
		return size.w, size.h
	else
		return 0, 0
	end
end
function ElementTerminal:updateSize()
	self.screen:updateSize(self:getWidth(), self:getHeight())
end

function ElementTerminal:paint()
	self:draw(false)
end
function ElementTerminal:repaint()
	self:draw(true)
end

-- Draw screen
function ElementTerminal:draw(redraw)
	redraw = not not redraw
	local bbox = self.element.bbox
	-- Draw each strip in the screen
	for lineY,line in ipairs(self.screen.strips) do
		for i,strip in ipairs(line) do
			if redraw or strip.dirty then
				local x = bbox.x + strip:left() - 1
				local y = bbox.y + lineY - 1
				self.element:draw(x, y, strip.str, strip.text, strip.back, bbox)
			end
		end
	end
	-- Update cursor blink
	self.element:setCursorBlink(self.blink, self.curX, self.curY, self.text)
end

-- Delegated methods to capture changes
function ElementTerminal:write(str)
	local len = math.min(#str, math.max(0, self:getWidth() - self.curX))
	local strip = self.screen:write(str, self.curX, self.curY, self.text, self.back)
	self.curX = self.curX + len
end
function ElementTerminal:setCursorPos(x, y)
	self.curX, self.curY = x, y
end
function ElementTerminal:setTextColor(text)
	self.text = text
end
ElementTerminal.setTextColour = ElementTerminal.setTextColor
function ElementTerminal:setBackgroundColor(back)
	self.back = back
end
ElementTerminal.setBackgroundColour = ElementTerminal.setBackgroundColor
function ElementTerminal:setCursorBlink(blink)
	self.blink = blink or false
end
function ElementTerminal:clearLine(y)
	self.screen:clearLine(y, self.back, false)
end
function ElementTerminal:clear()
	self.screen:clear(self.back, false)
end
function ElementTerminal:scroll(n)
	self.screen:scroll(n, self.back, false)
end

-- Exports
return ElementTerminal