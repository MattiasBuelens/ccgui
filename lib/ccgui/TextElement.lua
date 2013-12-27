--[[

	ComputerCraft GUI
	Text element

--]]

local Element		= require "ccgui.Element"
local Align			= require "ccgui.Align"
local VAlign		= require "ccgui.VAlign"
local Rectangle		= require "ccgui.geom.Rectangle"

local TextElement = Element:subclass("ccgui.TextElement")
function TextElement:initialize(opts)
	super.initialize(self, opts)

	-- Text
	self:setText(opts.text)
	-- Text alignment
	self.align = opts.align or Align.Left
	self.valign = opts.valign or VAlign.Top

	self:on("paint", self.drawText, self)
end

function TextElement:setText(text)
	self.text = text or ""
	self.lines = {}
	self:markRepaint()
end

local function wrapLine(str, limit)
	-- Wrap in words
	str = string.gsub(str, "(%S+)",
		function(word)
			local length, lastBreak = #word, 0
			while length - lastBreak > limit do
				lastBreak = lastBreak + limit
				word = string.sub(word, 1, lastBreak) .. "\n" .. string.sub(word, lastBreak+1)
			end
			return word
		end
	)
	-- Wrap on word boundaries
	local lastBreak = 1
	return string.gsub(str, "(%s+)()(%S+)()",
		function(spaces, start, word, finish)
			if finish - lastBreak > limit then
				lastBreak = start
				return "\n"..word
			end
		end
	)
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

function TextElement.wordwrap(str, limit)
	-- Clean leading spaces after newlines
	--str = string.gsub(str, "%s*\n%s+", "\n")
	-- Clean subsequent spaces
	--str = string.gsub(str, "%s%s+", " ")
	-- Wrap every single line
	str = string.gsub(str, "[^\n]+",
		function(line)
			return wrapLine(line, limit)
		end
	)
	return str
end

function TextElement:calcSize(size)
	-- Get inner bounding box
	local bbox = self:inner(size)

	-- Wrap text to fit bounding box width
	local text = self.wordwrap(self.text, bbox.w)

	-- Split in lines
	self.lines = splitLines(text)

	-- Get longest line length
	local nw = 0
	for i,line in ipairs(self.lines) do
		local len = #line
		if(len > nw) then nw = len end
	end

	-- Draw less lines if height limited
	local nh = math.min(bbox.h, #self.lines)
	self.lineCount = nh

	-- Get inner bounding box with new size
	bbox = Rectangle:new(bbox.x, bbox.y, nw, nh)
	-- Use outer size box
	self.size = self:outer(bbox)
end

function TextElement:drawText()
	-- Get inner bounding box
	local bbox = self:inner(self.bbox)

	-- Vertical align
	local firstLine, y = 1, bbox.y
	local nLines, nLinesToPaint = #self.lines, self.lineCount
	if self.valign == VAlign.Center then
		y = y + math.floor((bbox.h - nLinesToPaint)/2)
		if nLines > nLinesToPaint then
			firstLine = math.floor((nLines - nLinesToPaint)/2) + 1
		end
	elseif self.valign == VAlign.Bottom then
		y = y + bbox.h - nLinesToPaint
		if nLines > nLinesToPaint then
			firstLine = nLines - nLinesToPaint + 1
		end
	end

	local lastLine = firstLine + nLinesToPaint - 1
	for i=firstLine,lastLine do
		local line = self.lines[i]
		-- Horizontal align
		local x = bbox.x
		local len = #(line)
		if self.align == Align.Center then
			x = x + math.floor((bbox.w - len)/2)
		elseif self.align == Align.Right then
			x = x + bbox.w - len
		end
		-- Write text
		self:draw(x, y, line, self.foreground, self.background, bbox)
		y = y + 1
	end
end

-- Exports
return TextElement