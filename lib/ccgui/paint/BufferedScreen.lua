--[[

	ComputerCraft GUI
	Buffered screen

--]]

local Object	= require "objectlua.Object"

local Strip = Object:subclass("ccgui.paint.Strip")
function Strip:initialize(str, x, text, back, dirty)
	self.str = str
	self.x = x
	self.text = text
	self.back = back
	self.dirty = (dirty == nil) or (not not dirty)
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

local BufferedScreen = Object:subclass("ccgui.paint.BufferedScreen")
function BufferedScreen:initialize(width, height)
	self.width = width or 0
	self.height = height or 0
	-- Paint strips, grouped by y and sorted by x
	self.strips = {}
	for y=1,self.height do
		self.strips[y] = {}
	end
end

function BufferedScreen:updateSize(newWidth, newHeight, back, dirty)
	dirty = (dirty == nil) or (not not dirty)
	local oldWidth, oldHeight = self.width, self.height
	self.width, self.height = newWidth, newHeight
	-- Update width
	if newWidth > oldWidth then
		-- Fill extra width
		local empty = string.rep(" ", newWidth - oldWidth + 1)
		for y=1,oldHeight do
			self:write(empty, oldWidth, y, colours.white, back, dirty)
		end
	elseif newWidth < oldWidth then
		-- Trim strips
		for y=1,oldHeight do
			local line = self.strips[y]
			local i = #line
			while i > 0 do
				local strip = line[i]
				if strip:left() > newWidth then
					-- Fully past new width, remove
					table.remove(line, i)
				elseif strip:right() <= newWidth then
					-- Fully before new width, done
					break
				else
					-- Trim
					strip.str = string.sub(strip.str, 1, newWidth - strip:left() + 1)
					strip.dirty = strip.dirty or dirty
				end
				i = i - 1
			end
		end
	end
	-- Update height
	if newHeight > oldHeight then
		-- Fill extra lines
		for y=oldHeight,newHeight do
			self.strips[y] = {}
			self:clearLine(y, back, dirty)
		end
	elseif newHeight < oldHeight then
		-- Remove excess lines
		while #self.strips > newHeight do
			table.remove(self.strips, #self.strips)
		end
	end
end

-- Add strip to screen
function BufferedScreen:add(y, newStrip)
	-- Trim to width
	local newLen = math.min(#newStrip.str, math.max(0, self.width - newStrip:left() + 1))
	newStrip.str = string.sub(newStrip.str, 1, newLen)
	-- Ignore empty strips
	if #newStrip.str == 0 then return end
	if y < 1 or y > self.height then return end
	-- Split intersecting existing paints
	local line, i, pos = self.strips[y], 1, nil
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
					local rightStrip = Strip:new(rightStr, newStrip:right(), strip.text, strip.back, strip.dirty)
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

-- Create and add strip to screen
function BufferedScreen:write(str, x, y, text, back, dirty)
	return self:add(y, Strip:new(str, x, text, back, dirty))
end

-- Scroll screen (empty lines are filled with back color)
function BufferedScreen:scroll(n, back, dirty)
	local empty = string.rep(" ", self.width)
	function scrollLine(i)
		local j = i + n
		if 1 <= j and j <= self.height then
			self.strips[i] = self.strips[j]
		else
			self.strips[i] = { Strip:new(empty, 1, colours.black, back) }
		end
		if dirty then
			for _,strip in ipairs(self.strips[i]) do
				strip.dirty = true
			end
		end
	end

	if n == 0 then return
	elseif n > 0 then
		-- Scrolling down, bottom becomes top
		-- Iterate top to bottom
		for i=1,self.height do
			scrollLine(i)
		end
	else
		-- Scrolling up, top becomes bottom
		-- Iterate bottom to top
		for i=self.height,1,-1 do
			scrollLine(i)
		end
	end
end

-- Clear single line
function BufferedScreen:clearLine(y, back, dirty)
	local empty = string.rep(" ", self.width)
	return self:write(empty, 1, y, colours.white, back, dirty)
end

-- Clear screen
function BufferedScreen:clear(back, dirty)
	for y=1,self.height do
		self:clearLine(y, back, dirty)
	end
end

-- Exports
return BufferedScreen