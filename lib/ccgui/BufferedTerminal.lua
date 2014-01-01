--[[

	ComputerCraft GUI
	Buffered terminal

	IBuffer API, by Symmetryc
	https://github.com/Symmetryc/Buffer

--]]

local Object	= require "objectlua.Object"

local Strip = Object:subclass("ccgui.paint.Strip")
function Strip:initialize(str, x, text, back)
	self.str = str
	self.x = x
	self.text = text
	self.back = back
	self.dirty = true
end
function Strip:left()
	return self.x
end
function Strip:right()
	return self.x + #self.str
end
function Strip:intersects(other)
	return self:left() < other:right()
	   and self:right() > other:left()
end
function Strip:matchesColor(other)
	return self.text == other.text
	   and self.back == other.back
end
function Strip:canMerge(other)
	return self:left() <= other:right()
	   and self:right() >= other:left()
	   and self:matchesColor(other)
end
function Strip:merge(other)
	local start = math.max(0, other.x - self.x)
	local stop = start + #other.str
	local newStr = string.sub(self.str, 1, start) .. other.str .. string.sub(self.str, stop)
	if newStr ~= self.str then
		self.str = newStr
		self.dirty = true
	end
	local newX = math.min(self.x, other.x)
	if self.x ~= newX then
		self.x = newX
		self.dirty = true
	end
end

local Screen = Object:subclass("ccgui.paint.Screen")
function Screen:initialize()
	-- Paint strips, grouped by y and sorted by x
	self.strips = {}
end

function Screen:getLine(y)
	local line = self.strips[y]
	if line == nil then
		line = {}
		self.strips[y] = line
	end
	return line
end

-- Add to screen
function Screen:add(y, newStrip)
	-- Ignore empty strips
	if #newStrip.str == 0 then return end
	-- Split intersecting existing paints
	local line, i, pos = self:getLine(y), 1, nil
	while i <= #line do
		local strip = line[i]
		-- Find insert position
		if pos == nil and newStrip:left() <= strip:left() then
			pos = i
		end
		-- Resolve intersections
		if newStrip:intersects(strip) then
			local leftLen = math.max(0, newStrip:left() - strip:left())
			local rightLen = math.max(0, strip:right() - newStrip:right())
			local leftStr = string.sub(strip.str, 1, leftLen)
			local rightStr = string.sub(strip.str, -rightLen)
			local hasLeft, hasRight = leftLen > 0, rightLen > 0
			if hasLeft then
				-- Replace original strip with left strip
				strip.str = leftStr
				if hasRight then
					-- Also create right strip
					local rightStrip = Strip:new(rightStr, newStrip:right(), strip.text, strip.back)
					rightStrip.dirty = strip.dirty
					table.insert(line, i+1, rightStrip)
				end
			elseif hasRight then
				-- Replace original strip with right strip
				strip.str = rightStr
				strip.x = newStrip:right()
			else
				-- Original strip fully covered by new strip, remove it
				table.remove(line, i)
				i = i - 1
			end
		end
		i = i + 1
	end
	if pos == nil then pos = #line+1 end
	-- Merge with surrounding strips
	local merged = false
	if pos > 1 and line[pos-1]:canMerge(newStrip) then
		-- Merge with strip on left
		pos = pos-1
		line[pos]:merge(newStrip)
		newStrip = line[pos]
		merged = true
	end
	if pos < #line and line[pos+1]:canMerge(newStrip) then
		if merged then
			-- Already merged, merge and remove
			newStrip:merge(line[pos+1])
			table.remove(line, pos+1)
		else
			-- Not yet merged, merge with strip on right
			line[pos+1]:merge(newStrip)
			newStrip = line[pos+1]
		end
		merged = true
	end
	-- Insert if not yet merged
	if not merged then
		table.insert(line, pos, newStrip)
	end
	-- Return inserted or merged strip
	return newStrip
end

function Screen:clear()
	self.strips = {}
end

local BufferedTerminal = Object:subclass("ccgui.BufferedTerminal")
function BufferedTerminal:initialize(out)
	-- Output device
	self.out = out or term
	-- Screen
	self.screen = Screen:new()
	-- State to restore after draw
	self.curX, self.curY = self.out.getCursorPos()
	self.text = colours.white
	self.back = colours.black
	self.blink = false
	-- Delegate terminal methods
	for k,f in pairs(self.out) do
		if self[k] == nil then
			self[k] = function(self, ...)
				return f(...)
			end
		end
	end
	-- Create delegate which matches the term API
	self.term = {}
	local me = self
	for k,v in pairs(self.out) do
		-- Redirect to own method
		self.term[k] = function(...)
			return me[k](me, ...)
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

function BufferedTerminal:writeBuffer(str, x, y, text, back)
	return self.screen:add(y, Strip:new(str, x, text, back))
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
	local strip = self:writeBuffer(str, self.curX, self.curY, self.text, self.back)
	strip.dirty = false
	self.out.write(str)
	self.curX, self.curY = self.out.getCursorPos()
end
function BufferedTerminal:setCursorPos(x, y)
	self.curX, self.curY = x, y
	self.out.setCursorPos(x, y)
end
function BufferedTerminal:setTextColor(text)
	self.text = text
	self.out.setTextColor(text)
end
BufferedTerminal.setTextColour = BufferedTerminal.setTextColor
function BufferedTerminal:setBackgroundColor(back)
	self.back = back
	self.out.setBackgroundColor(back)
end
BufferedTerminal.setBackgroundColour = BufferedTerminal.setBackgroundColor
function BufferedTerminal:setCursorBlink(blink)
	self.blink = blink or false
	self.out.setCursorBlink(blink)
end
function BufferedTerminal:clearLine(y)
	local str = string.rep(" ", self:getWidth())
	local strip = self:writeBuffer(str, 1, self.curY, self.text, self.back)
	strip.dirty = false
	self.out.clearLine(y)
end
function BufferedTerminal:clear()
	local str = string.rep(" ", self:getWidth())
	local h = self:getHeight()
	for y=1,h do
		local strip = self:writeBuffer(str, 1, y, self.text, self.back)
		strip.dirty = false
	end
	self.out.clear()
end

-- Exports
return BufferedTerminal