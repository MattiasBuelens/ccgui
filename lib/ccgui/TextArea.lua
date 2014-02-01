--[[

	ComputerCraft GUI
	Text area

--]]

local Element		= require "ccgui.Element"
local ScrollElement	= require "ccgui.ScrollElement"
local Rectangle		= require "ccgui.geom.Rectangle"

local TextArea = ScrollElement:subclass("ccgui.TextArea")
function TextArea:initialize(opts)
	-- Default style
	opts.background = opts.background or colours.white
	-- Scroll horizontally by default as well
	opts.horizontal = (opts.horizontal == nil) or (not not opts.horizontal)
	-- Mouse scroll by default
	opts.mouseScroll = (opts.mouseScroll == nil) or (not not opts.mouseScroll)

	super.initialize(self, opts)

	-- Text lines
	self:setText(opts.text)

	-- Cursor position
	self.cursorLine = 1 -- [1, #(lines)]
	self.cursorChar = 1  -- [1, #(lines[cursorLine])]

	self:on("focus", self.textFocus, self)
	self:on("blur", self.textBlur, self)
	
	self:on("mouse_click", self.textClick, self)
	self:on("key", self.textKey, self)
	self:on("char", self.textChar, self)

	self:on("paint", self.drawText, self)
	self:on("afterpaint", self.drawCursor, self)
end

local function splitLines(str)
	local t = {}
	local function helper(line)
		table.insert(t, line)
		return ""
	end
	helper((string.gsub(str, "(.-)\n", helper)))
	return t
end

function TextArea:text()
	local text = ""
	-- Join lines
	for i,line in ipairs(self.lines) do
		if i > 1 then
			text = text.."\n"
		end
		text = text..line
	end
	return text
end

function TextArea:setText(text)
	-- Split lines
	self.lines = splitLines(text or "")
	self:updateScroll()
	-- Reset cursor
	if self.bbox then
		self:setCursor(1, 1)
	end
	-- Mark for repaint
	self:markRepaint()
end

function TextArea:multiline()
	return true
end

function TextArea:readonly()
	return false
end

--[[

	Scroll

]]--

function TextArea:scrollVisible()
	return self:inner(self.bbox):size()
end

function TextArea:scrollTotal()
	local bbox = self:inner(self.bbox)
	return vector.new(
		math.max(bbox.w, self.longestLineLength + 1), -- for cursor at end of line
		math.max(bbox.h, #(self.lines))
	)
end

function TextArea:updateScroll()
	-- Update longest line length
	local maxLen = 0
	for i,line in ipairs(self.lines) do
		maxLen = math.max(maxLen, #line)
	end
	self.longestLineLength = maxLen
end

--[[

	Focus

]]--

function TextArea:canFocus()
	return self:isVisible()
end

function TextArea:textFocus()
	self:drawCursor()
end

function TextArea:textBlur()
	self:setCursorBlink(false)
end

function TextArea:textClick(button, x, y)
	if button == 1 then
		-- Left mouse button
		if self:canFocus() and self:contains(x, y) then
			-- Set cursor
			local cursor = self:fromScreen(x, y)
			self:setCursor(cursor.x, cursor.y)
			-- Draw cursor
			self:drawCursor()
		end
	end
end

--[[

	Cursor

]]--

function TextArea:moveCursor(dx, dy)
	local x, y = self.cursorChar, self.cursorLine
	if dy ~= 0 then
		-- Moving vertically, don't switch lines
		y = y + dy
	else
		-- Moving horizontally, switch lines if needed
		x = x + dx
		if x <= 0 then
			if y > 1 then
				-- Move to end of previous line
				y = y - 1
				x = #(self.lines[y]) + 1
			else
				-- Clip to start of first line
				x = 1
			end
		elseif x > #(self.lines[y]) + 1 then
			if y < #self.lines then
				-- Move to start of next line
				y = y + 1
				x = 1
			else
				-- Clip to end of last line
				x = #(self.lines[y]) + 1
			end
		end
	end
	self:setCursor(x, y)
end

function TextArea:movePage(delta)
	local x, y = self.cursorChar, self.cursorLine
	-- Move per scroll page
	y = y + delta * self:scrollVisible().y
	self:setCursor(x, y)
end

function TextArea:setCursor(x, y)
	-- Keep in text bounds
	y = math.max(1, math.min(y, #self.lines))
	x = math.max(1, math.min(x, #(self.lines[y]) + 1))

	-- Update cursor position
	self.cursorChar = x
	self.cursorLine = y

	-- Adjust scroll position
	local scrollX, scrollY = self.scrollPosition.x, self.scrollPosition.y
	local scrollVis = self:scrollVisible()

	if x <= scrollX then
		scrollX = x - 1
	elseif x >= scrollX + scrollVis.x then
		scrollX = x - scrollVis.x
	end

	if y <= scrollY then
		scrollY = y - 1
	elseif y >= scrollY + scrollVis.y then
		scrollY = y - scrollVis.y
	end

	self:setScrollPosition(scrollX, scrollY)

	-- Draw cursor
	self:drawCursor()
end

--[[

	Manipulations

]]--

function TextArea:insert(char)
	-- Insert character
	local line = self.lines[self.cursorLine]
	line = string.sub(line, 1, self.cursorChar-1) .. char .. string.sub(line, self.cursorChar, -1)
	self.lines[self.cursorLine] = line
	self:markRepaint()
	-- Move cursor
	self:moveCursor(1, 0)
	self:updateScroll()
end

function TextArea:delete(before)
	if before == nil then
		before = true
	else
		before = not not before
	end

	if before then
		if self.cursorChar == 1 and self.cursorLine > 1 then
			-- Get old length of previous line
			local prevLength = #(self.lines[self.cursorLine-1])
			-- Concat with previous line
			self.lines[self.cursorLine-1] = self.lines[self.cursorLine-1] .. self.lines[self.cursorLine]
			table.remove(self.lines, self.cursorLine)
			self:setCursor(prevLength + 1, self.cursorLine-1)
		elseif self.cursorChar > 1 then
			-- Remove previous in current line
			local line = self.lines[self.cursorLine]
			line = string.sub(line, 1, self.cursorChar-2) .. string.sub(line, self.cursorChar, -1)
			self.lines[self.cursorLine] = line
			self:moveCursor(-1, 0)
		end
	else
		local line = self.lines[self.cursorLine]
		if self.cursorChar == #line + 1 and self.cursorLine < #(self.lines) then
			-- Concat with next line
			self.lines[self.cursorLine] = self.lines[self.cursorLine] .. self.lines[self.cursorLine + 1]
			table.remove(self.lines, self.cursorLine + 1)
		elseif self.cursorChar <= #line then
			-- Remove next in current line
			line = string.sub(line, 1, self.cursorChar-1) .. string.sub(line, self.cursorChar + 1, -1)
			self.lines[self.cursorLine] = line
		end
	end
	self:markRepaint()

	self:updateScroll()
end

function TextArea:newline()
	if not self:multiline() then return end

	-- Split current line
	local line = self.lines[self.cursorLine]
	self.lines[self.cursorLine] = string.sub(line, 1,self.cursorChar-1)
	table.insert(self.lines, self.cursorLine + 1, string.sub(line, self.cursorChar, -1))
	self:markRepaint()

	-- Move to new next line
	self:setCursor(1, self.cursorLine + 1)
	self:updateScroll()
end

--[[

	Drawing

]]--

function TextArea:fromScreen(x, y)
	local screenPos = type(x) == "table" and x or vector.new(x, y)
	return screenPos + vector.new(1, 1) - self:inner(self.bbox):tl() + self.scrollPosition
end

function TextArea:toScreen(x, y)
	local textPos = type(x) == "table" and x or vector.new(x, y)
	return textPos - vector.new(1, 1) + self:inner(self.bbox):tl() - self.scrollPosition
end

function TextArea:measure(size)
	-- Get inner bounding box
	local bbox = self:inner(size)
	local w, h = bbox.w, bbox.h

	-- Limit inner height when single line
	if not self:multiline() then h = 1 end

	-- Get inner bounding box with new size
	size = Rectangle:new(bbox.x, bbox.y, w, h)
	-- Use outer size box
	size = self:outer(size)
	super.measure(self, size)
end

function TextArea:drawCursor()
	if self:hasFocus() then
		-- Get screen position
		local pos = self:toScreen(self.cursorChar, self.cursorLine)
		if self:contains(pos) then
			-- Show blinking cursor
			self:setCursorBlink(true, pos.x, pos.y, self.foreground)
		else
			-- Hide blinking cursor
			self:setCursorBlink(false)
		end
	end
end

function TextArea:drawText(ctxt)
	local bbox = self:inner(self.bbox)
	-- Get screen position
	local pos = self:toScreen(1, 1)
	local x, y = pos.x, pos.y
	-- Draw lines
	for i,line in ipairs(self.lines) do
		-- TODO Use ctxt's clip?
		ctxt:draw(x, y, line, self:getForeground(), self:getBackground(), bbox)
		y = y + 1
	end
end

function TextArea:textKey(key)
	-- Translate key to action
	if key == keys.up then
		self:moveCursor(0, -1)
	elseif key == keys.down then
		self:moveCursor(0, 1)
	elseif key == keys.left then
		self:moveCursor(-1, 0)
	elseif key == keys.right then
		self:moveCursor(1, 0)
	elseif key == keys.home then
		self:setCursor(1, self.cursorLine)
	elseif key == keys["end"] then
		self:setCursor(#(self.lines[self.cursorLine]) + 1, self.cursorLine)
	elseif key == keys.pageUp then
		self:movePage(-1)
	elseif key == keys.pageDown then
		self:movePage(1)
	elseif not self:readonly() then
		if key == keys.backspace then
			self:delete(true)
		elseif key == keys.delete then
			self:delete(false)
		elseif key == keys.enter or key == keys.numPadEnter then
			self:newline()
		end
	end
end

function TextArea:textChar(char)
	if not self:readonly() then
		-- Insert character
		self:insert(char)
	end
end

-- Exports
return TextArea