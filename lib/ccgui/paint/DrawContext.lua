--[[

	ComputerCraft GUI
	Draw context

--]]

local Object	= require "objectlua.Object"

local DrawContext = Object:subclass("ccgui.paint.DrawContext")
function DrawContext:initialize(x, y, clip)
	-- Offset
	self.offsetX = x or 0
	self.offsetY = y or 0
	-- Clip rectangle
	self.clip = clip or nil
end

-- Raw drawing
function DrawContext:rawDraw(x, y, text, fgColor, bgColor)
	error("DrawContext:rawDraw() not implemented")
end

function DrawContext:doClip(x, y, text, clip)
	-- Check vertical bounds
	if y < clip.y or y >= clip.y + clip.h then
		return false
	end
	-- Limit to horizontal bounds
	local startIdx = 1 + math.max(0, clip.x - x)
	local endIdx = math.min(#text, clip.x + clip.w - x)
	text = string.sub(text, startIdx, endIdx)
	x = x + startIdx - 1
	return true, x, y, text
end

-- Draw single text line within bounding rectangle
function DrawContext:draw(x, y, text, fgColor, bgColor, clip)
	if type(x) == "table" then
		-- Position given as vector
		x, y, text, fgColor, bgColor = x.x, x.y, y, text, fgColor
	end

	-- Clip
	local draw = true
	if clip then
		draw, x, y, text = self:doClip(x, y, text, clip)
		if not draw then return end
	end

	-- Offset
	x = x + self.offsetX
	y = y + self.offsetY

	-- Context clip
	if self.clip then
		draw, x, y, text = self:doClip(x, y, text, self.clip)
		if not draw then return end
	end

	self:rawDraw(x, y, text, fgColor, bgColor)
end

-- Draw line
function DrawContext:drawLine(line, color)
	-- Draw each point along the line
	for i,point in ipairs(line:points()) do
		self:draw(point, " ", colours.white, color)
	end
end

-- Draw rectangle
function DrawContext:drawRect(rect, color)
	local line = string.rep(" ", rect.w)
	for y=0,rect.h-1 do
		self:draw(rect.x, rect.y + y, line, colours.white, color)
	end
end

-- Draw single border
function DrawContext:drawSingleBorder(rect, border, side)
	if border:has(side) then
		self:drawLine(rect[side](rect), border:get(side))
	end
end

-- Draw full border
function DrawContext:drawBorder(rect, border)
	self:drawSingleBorder(rect, border, "left")
	self:drawSingleBorder(rect, border, "right")
	self:drawSingleBorder(rect, border, "top")
	self:drawSingleBorder(rect, border, "bottom")
end

-- Exports
return DrawContext