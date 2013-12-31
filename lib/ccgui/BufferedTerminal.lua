--[[

	ComputerCraft GUI
	Buffered terminal

	IBuffer API, by Symmetryc
	https://github.com/Symmetryc/Buffer

--]]

local Object	= require "objectlua.Object"
local Rectangle	= require "ccgui.geom.Rectangle"

local BufferedPaint = Object:subclass("ccgui.BufferedPaint")
function BufferedPaint:initialize(str, x, text, back)
	self.str = str
	self.x = x
	self.text = text
	self.back = back
end
function BufferedPaint:left()
	return self.x
end
function BufferedPaint:right()
	return self.x + #self.str
end
function BufferedPaint:intersects(other)
	return self:left() < other:right()
	   and self:right() > other:left()
end
function BufferedPaint:contains(other)
	return self:left() <= other:left()
	   and self:right() >= other:right()
end
function BufferedPaint:matchesColor(other)
	return self.text == other.text
	   and self.back == other.back
end
function BufferedPaint:canMergeLeft(other)
	return self:left() == other:right()
	   and self:matchesColor(other)
end
function BufferedPaint:canMergeRight(other)
	return self:right() == other:left()
	   and self:matchesColor(other)
end
function BufferedPaint:append(other)
	self.str = self.str .. other.str
end
function BufferedPaint:prepend(other)
	self.str = other.str .. self.str
	self.x = other.x
end

local BufferedTerminal = Object:subclass("ccgui.BufferedTerminal")
function BufferedTerminal:initialize(out)
	-- Output device
	self.out = out or term
	-- Queued paints, grouped by y and sorted by x
	self.queue = {}
	-- State to restore after draw
	self.curX, self.curY = self.out.getCursorPos()
	self.text = colours.white
	self.back = colours.black
	self.blink = false
	-- Delegate terminal methods
	for k,v in pairs(self.out) do
		if self[k] == nil then
			local f = v -- for scope
			self[k] = function(self, ...)
				return f(...)
			end
		end
	end
	-- Create delegate which matches the term API
	self.term = {}
	local me = self
	for k,v in pairs(self.out) do
		-- Wrap own method
		local f = me[k] -- for scope
		self.term[k] = function(...)
			return f(me, ...)
		end
	end
end

function BufferedTerminal:asTerm()
	return self.term
end

function BufferedTerminal:getBounds()
	local width, height = self.out.getSize()
	return Rectangle:new(1, 1, width, height)
end

function BufferedTerminal:getQueueLine(y)
	local line = self.queue[y]
	if line == nil then
		line = {}
		self.queue[y] = line
	end
	return line
end

-- Write to buffer
function BufferedTerminal:writeBuffered(str, x, y, text, back)
	-- Create paint
	local paint = BufferedPaint:new(str, x, text, back)
	-- Split intersecting existing paints
	local line = self:getQueueLine(y)
	local pos = nil
	local i = 1
	while i <= #line do
		local linePaint = line[i]
		-- Resolve intersections
		if paint:intersects(linePaint) then
			local leftLen = math.max(0, paint:left() - linePaint:left())
			local rightLen = math.max(0, linePaint:right() - paint:right())
			local leftStr = string.sub(linePaint.str, leftLen)
			local rightStr = string.sub(linePaint.str, -rightLen)
			local hasLeft, hasRight = leftLen > 0, rightLen > 0
			if hasLeft then
				-- Replace original paint with left part
				linePaint.str = leftStr
				if hasRight then
					-- Also create right paint
					local rightPaint = BufferedPaint:new(rightStr, paint:right(), linePaint.text, linePaint.back)
					table.insert(line, i+1, rightPaint)
				end
				print()
			elseif hasRight then
				-- Replace original paint with right paint
				linePaint.str = rightStr
				linePaint.x = paint:right()
			else
				-- Original paint fully covered by new paint, remove it
				table.remove(line, i)
				i = i-1
			end
		end
		-- Find insert position
		if pos == nil and paint:left() < linePaint:left() then
			pos = i
		end
		i = i + 1
	end
	if pos == nil then pos = #line+1 end
	-- Merge with surrounding paints
	local merged = false
	--[[if pos > 1 and paint:canMergeLeft(line[pos-1]) then
		-- Append to paint on left
		line[pos-1]:append(paint)
		merged = true
	end
	if pos < #line and paint:canMergeRight(line[pos+1]) then
		if merged then
			-- Double merge, remove
			paint:append(line[pos+1])
			table.remove(line, pos+1)
		else
			-- Prepend to paint on right
			line[pos+1]:prepend(paint)
		end
		merged = true
	end]]--
	-- Insert if not yet merged
	if not merged then
		table.insert(line, pos, paint)
	end
end

-- Draw buffer
function BufferedTerminal:draw()
	-- Get current state
	local x, y = self.out.getCursorPos()
	local text, back = self.text, self.back
	self.out.setTextColor(text)
	self.out.setBackgroundColor(back)
	self.out.setCursorBlink(false)
	-- Draw each paint in the queue
	for lineY,line in ipairs(self.queue) do
		for i,paint in ipairs(line) do
			if x ~= paint:left() or y ~= lineY then
				self.out.setCursorPos(paint:left(), lineY)
				x, y = paint:left(), lineY
			end
			if text ~= paint.text then
				self.out.setTextColor(paint.text)
				text = paint.text
			end
			if back ~= paint.back then
				self.out.setBackgroundColor(paint.back)
				back = paint.back
			end
			self.out.write(paint.str)
			x = paint:right()
		end
	end
	-- Clear queue
	self.queue = {}
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
	self.out.write(str)
	self:writeBuffered(str, self.curX, self.curY, self.text, self.back)
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
	self.queue[y] = {}
	self.out.clearLine(y)
end
function BufferedTerminal:clear()
	self.queue = {}
	self.out.clear()
end

-- Exports
return BufferedTerminal