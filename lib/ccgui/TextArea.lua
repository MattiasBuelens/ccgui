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
	self:on("paste", self.textPaste, self)

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

function TextArea:getText()
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

function TextArea:insert(text)
	-- Insert text on current line
	local x, y = self.cursorChar, self.cursorLine
	local line = self.lines[y]
	local before, after = string.sub(line, 1, x-1), string.sub(line, x, -1)

	-- Remove new lines when not multiline
	if not self:multiline() then
		text = string.gsub(text, "\n", "")
	end

	local textLines = splitLines(text)
	if #textLines == 1 then
		-- Single line
		self.lines[y] = before .. text .. after
		-- Update cursor
		x = x + #text
	else
		-- Multiple lines
		-- Insert last line
		table.insert(self.lines, y+1, textLines[#textLines] .. after)
		-- Insert other lines back to front before last line
		for i=#textLines-1,2,-1 do
			table.insert(self.lines, y+1, textLines[i])
		end
		-- Update first line
		self.lines[y] = before .. textLines[1]
		-- Update cursor
		x = #(textLines[#textLines]) + 1
		y = y + #textLines - 1
	end
	self:setCursor(x, y)

	self:markRepaint()
	self:updateScroll()
end

function TextArea:delete(before)
	local x, y = self.cursorChar, self.cursorLine
	before = (before == nil) or (not not before)

	if before then
		if x == 1 and y > 1 then
			-- Get old length of previous line
			local prevLength = #(self.lines[y-1])
			-- Concat with previous line
			self.lines[y-1] = self.lines[y-1] .. self.lines[y]
			table.remove(self.lines, y)
			self:setCursor(prevLength + 1, y-1)
		elseif x > 1 then
			-- Remove previous in current line
			local line = self.lines[y]
			line = string.sub(line, 1, x-2) .. string.sub(line, x, -1)
			self.lines[y] = line
			self:moveCursor(-1, 0)
		end
	else
		local line = self.lines[y]
		if x == #line+1 and y < #(self.lines) then
			-- Concat with next line
			self.lines[y] = self.lines[y] .. self.lines[y+1]
			table.remove(self.lines, y+1)
		elseif x <= #line then
			-- Remove next in current line
			line = string.sub(line, 1, x-1) .. string.sub(line, x+1, -1)
			self.lines[y] = line
		end
	end

	self:markRepaint()
	self:updateScroll()
end

function TextArea:newline()
	if not self:multiline() then return end
	local x, y = self.cursorChar, self.cursorLine

	-- Split current line
	local line = self.lines[y]
	local before, after = string.sub(line, 1, x-1), string.sub(line, x, -1)
	self.lines[y] = before
	table.insert(self.lines, y+1, after)
	-- Move to new next line
	self:setCursor(1, y+1)

	self:markRepaint()
	self:updateScroll()
end

--[[

	Drawing

]]--

function TextArea:getScreenOffset()
	return self:inner(self.bbox):tl() - self.scrollPosition - vector.new(1, 1)
end
function TextArea:fromScreen(x, y)
	local screenPos = type(x) == "table" and x or vector.new(x, y)
	return screenPos - self:getScreenOffset()
end
function TextArea:toScreen(x, y)
	local localPos = type(x) == "table" and x or vector.new(x, y)
	return localPos + self:getScreenOffset()
end

function TextArea:measure(spec)
	-- Get inner spec
	spec = self:inner(spec)

	-- Use smallest possible size
	local w, h = spec.w.value, spec.h.value
	if not spec.w:isExact() then
		w = math.min(w, self.longestLineLength + 1)
	end
	if not spec.h:isExact() then
		h = math.min(h, #self.lines)
	end

	-- Limit inner height when single line
	if not self:multiline() then h = 1 end

	-- Get inner bounding box with new size
	size = Rectangle:new(1,1, w, h)
	-- Use outer size box
	self.size = self:outer(size)
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
		self:drawTextLine(ctxt, line, x, y, bbox)
		y = y + 1
	end
end
function TextArea:drawTextLine(ctxt, line, x, y, bbox)
	-- TODO Use ctxt's clip?
	ctxt:draw(x, y, line, self:getForeground(), self:getBackground(), bbox)
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

function TextArea:textPaste(pasted)
	if not self:readonly() then
		-- Insert pasted text
		self:insert(pasted)
	end
end

-- Exports
return TextArea