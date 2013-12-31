--[[

	ComputerCraft GUI
	Buffered terminal

	IBuffer API, by Symmetryc
	https://github.com/Symmetryc/Buffer

--]]

local Object	= require "objectlua.Object"

local Strip = Object:subclass("ccgui.paint.Strip")
function Strip:initialize(str, x, y, text, back)
	self.str = str
	self.x = x
	self.y = y
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
	return self.y == other.y
	   and self:left() < other:right()
	   and self:right() > other:left()
end
function Strip:matchesColor(other)
	return self.text == other.text
	   and self.back == other.back
end
function Strip:canAppend(other)
	return self.y == other.y
	   and self:right() == other:left()
	   and self:matchesColor(other)
end
function Strip:canPrepend(other)
	return self.y == other.y
	   and self:left() == other:right()
	   and self:matchesColor(other)
end
function Strip:append(other)
	self.str = self.str .. other.str
	self.dirty = true
end
function Strip:prepend(other)
	self.str = other.str .. self.str
	self.x = other.x
	self.dirty = true
end
function Strip:__tostring()
	return "Strip["
		.."y="..self.y
		..",l="..self:left()
		..",r="..self:right()
		..",t="..self.text
		..",b="..self.back
		..",d="..(self.dirty and "T" or "F")
		..",s="..self.str
		.."]"
end

local Screen = Object:subclass("ccgui.paint.Screen")
function Screen:initialize()
	-- Paint strips, grouped by y and sorted by x
	self.strips = {}
end

function Screen:getLine(strip)
	local y = strip.y
	local line = self.strips[y]
	if line == nil then
		line = {}
		self.strips[y] = line
	end
	return line
end

-- Add to screen
function Screen:add(newStrip)
	-- Ignore empty strips
	if #newStrip.str == 0 then return end
	-- Split intersecting existing paints
	local line, i = self:getLine(newStrip), 1
	while i <= #line do
		local strip = line[i]
		-- Resolve intersections
		if newStrip:intersects(strip) then
			local leftLen = math.max(0, newStrip:left() - strip:left())
			local rightLen = math.max(0, strip:right() - newStrip:right())
			local leftStr = string.sub(strip.str, 1, leftLen)
			local rightStr = string.sub(strip.str, -rightLen)
			local hasLeft, hasRight = leftLen > 0, rightLen > 0
			strip.dirty = true
			if hasLeft then
				-- Replace original strip with left strip
				strip.str = leftStr
				if hasRight then
					-- Also create right strip
					local rightStrip = Strip:new(rightStr, newStrip:right(), strip.y, strip.text, strip.back)
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
	-- Find insert position
	local pos = nil
	for i=1,#line do
		if newStrip:left() <= line[i]:left() then
			pos = i
			break
		end
	end
	if pos == nil then pos = #line+1 end
	-- Merge with surrounding strips
	local merged = false
	if pos > 1 and line[pos-1]:canAppend(newStrip) then
		-- Append to strip on left
		pos = pos-1
		line[pos]:append(newStrip)
		newStrip = line[pos]
		merged = true
	end
	if pos < #line and line[pos+1]:canPrepend(newStrip) then
		if merged then
			-- Multiple merges, append and remove
			newStrip:append(line[pos+1])
			table.remove(line, pos+1)
		else
			-- Not yet merged, prepend to strip on right
			line[pos+1]:prepend(newStrip)
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
	return self.screen:add(Strip:new(str, x, y, text, back))
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
	local nStrips = 0 -- TODO DEBUG
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
				nStrips = nStrips + 1
			end
		end
	end
	-- TODO DEBUG
	self.count = (self.count or 0) + 1
	x, y, text, back = 1, 1, colours.yellow, colours.black
	self.out.setCursorPos(x, y)
	self.out.setTextColor(text)
	self.out.setBackgroundColor(back)
	self.out.write(string.format("%02d|%02d", self.count, nStrips))
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

-- TODO DEBUG
function BufferedTerminal:dump()
	local res = "{\n"
	for y,line in ipairs(self.screen.strips) do
		res = res .. "\t"..y.." = {\n"
		for i,strip in ipairs(line) do
			res = res .. "\t\t" .. tostring(strip) .. "\n"
		end
		res = res .. "\t}\n"
	end
	res = res .. "}"
	return res
end

-- Exports
return BufferedTerminal