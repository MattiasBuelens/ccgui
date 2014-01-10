--[[

	ComputerCraft GUI
	Buffered terminal

--]]

local Object			= require "objectlua.Object"
local BufferedScreen	= require "ccgui.paint.BufferedScreen"

local BufferedTerminal = Object:subclass("ccgui.paint.BufferedTerminal")
function BufferedTerminal:initialize(out)
	-- Output device
	self.out = out or term
	-- Screen
	self.screen = BufferedScreen:new(self.out.getSize())
	-- State to restore after draw
	self.curX, self.curY = self.out.getCursorPos()
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
	-- Export as term API
	self.term = {}
	for k,v in pairs(term) do
		self.term[k] = function(...)
			return self[k](self, ...)
		end
	end
end

function BufferedTerminal:asTerm()
	return self.term
end

function BufferedTerminal:getWidth()
	local width,_ = self.out.getSize()
	return width
end
function BufferedTerminal:getHeight()
	local _,height = self.out.getSize()
	return height
end

function BufferedTerminal:writeBuffer(str, x, y, text, back, dirty)
	return self.screen:write(str, math.floor(x), math.floor(y), text, back, dirty)
end

function BufferedTerminal:paint()
	self:draw(false)
end
function BufferedTerminal:repaint()
	self:draw(true)
end

-- Draw screen
function BufferedTerminal:draw(redraw)
	redraw = not not redraw
	-- Get current state
	local x, y = self.out.getCursorPos()
	local text, back = self.text, self.back
	self.out.setTextColor(text)
	self.out.setBackgroundColor(back)
	self.out.setCursorBlink(false)
	-- Draw each strip in the screen
	for lineY,line in ipairs(self.screen.strips) do
		for i,strip in ipairs(line) do
			if redraw or strip.dirty then
				if x ~= strip:left() or y ~= lineY then
					self.out.setCursorPos(strip:left(), lineY)
					x, y = strip:left(), lineY
				end
				if text ~= strip.text then
					self.out.setTextColor(strip.text)
					text = strip.text
				end
				if back ~= strip.back then
					self.out.setBackgroundColor(strip.back)
					back = strip.back
				end
				self.out.write(strip.str)
				strip.dirty = false
				x = strip:right()
			end
		end
	end
	-- Restore state
	if x ~= self.curX or y ~= self.curY then
		self.out.setCursorPos(self.curX, self.curY)
	end
	if text ~= self.text then
		self.out.setTextColor(self.text)
	end
	if back ~= self.back then
		self.out.setBackgroundColor(self.back)
	end
	self.out.setCursorBlink(self.blink)
end

-- Delegated methods to capture changes
function BufferedTerminal:write(str)
	local strip = self:writeBuffer(str, self.curX, self.curY, self.text, self.back, false)
	self.out.write(str)
	self.curX, self.curY = self.out.getCursorPos()
end
function BufferedTerminal:setCursorPos(x, y)
	self.curX, self.curY = math.floor(x), math.floor(y)
	self.out.setCursorPos(x, y)
end
function BufferedTerminal:setTextColor(text)
	self.text = text
	self.out.setTextColor(text)
end
function BufferedTerminal:setTextColour(text)
	return self:setTextColor(text)
end
function BufferedTerminal:setBackgroundColor(back)
	self.back = back
	self.out.setBackgroundColor(back)
end
function BufferedTerminal:setBackgroundColour(back)
	return self:setBackgroundColor(back)
end
function BufferedTerminal:setCursorBlink(blink)
	self.blink = blink or false
	self.out.setCursorBlink(blink)
end
function BufferedTerminal:clearLine()
	self.screen:clearLine(self.curY, self.back, false)
	self.out.clearLine()
end
function BufferedTerminal:clear()
	self.screen:clear(self.back, false)
	self.out.clear()
end
function BufferedTerminal:scroll(n)
	self.screen:scroll(n, self.back, false)
	self.out.scroll(n)
end

-- Exports
return BufferedTerminal