--[[

	ComputerCraft GUI
	Element

--]]

local Object		= require "objectlua.Object"
local EventEmitter	= require "event.EventEmitter"

local Border		= require "ccgui.Border"
local Margins		= require "ccgui.geom.Margins"
local Rectangle		= require "ccgui.geom.Rectangle"

local Element = EventEmitter:subclass("ccgui.Element")
function Element:initialize(opts)
	super.initialize(self)
	-- Parent element
	self.parent = opts.parent or nil
	-- Visibility
	self.isVisible = true
	-- Colors
	self.foreground = opts.foreground or colours.black
	self.background = opts.background or 0
	-- Padding
	self.padding = Margins:new(opts.padding or 0)
	-- Border
	self.border = Border:new(opts.border or 0)
	-- Size and bounding box for drawing
	self.size = opts.size or nil
	self.bbox = opts.bbox or nil
	-- Mouse
	self:on("mouse_click", self.mouseClick, self)
	-- Focus
	self:on("focus", self.updateFocus, self)
	-- Paint
	self:on("paint", self.clear, self)
	self:on("paint", self.drawBorder, self)

	-- Need repaint
	--self.needsRepaint = true
	--self:markRepaint()
end

function Element:show()
	if not self.isVisible then
		--self:markRepaint()
		self.isVisible = true
		return true
	end
	return false
end

function Element:hide()
	if self.isVisible then
		--self:markRepaint()
		self.isVisible = false
		return true
	end
	return false
end

--[[

	Bounding box

--]]

-- Inner bounding box, without border and padding
function Element:inner(bbox)
	if bbox == nil then
		print("invalid bbox")
		for k,v in pairs(self) do
			print(tostring(k).."="..tostring(v))
		end
		error()
	end
	assert(bbox ~= nil, "invalid bbox")
	assert(self.padding ~= nil, "invalid padding")
	assert(self.border ~= nil, "invalid border")

	return bbox:contract(self.padding):contract(self.border:margins())
end

-- Outer bounding box, with border and padding
function Element:outer(bbox)
	assert(bbox ~= nil, "invalid bbox")
	assert(self.padding ~= nil, "invalid padding")
	assert(self.border ~= nil, "invalid border")

	return bbox:expand(self.padding):expand(self.border:margins())
end

-- Calculate element size within given size box
function Element:calcSize(size)
	self.size = Rectangle:new(0, 0, 0, 0)
end

-- Calculate element layout within given bounding box
function Element:calcLayout(bbox)
	self.bbox = bbox
end

-- Update element layout within given bounding box
function Element:updateLayout(bbox)
	self:calcSize(bbox)
	self:calcLayout(Rectangle:new(bbox:tl(), self.size:size()))
end

-- Check if the bounding box with padding contains the given point
function Element:contains(x, y)
	if self.bbox == nil then return false end
	return self:inner(self.bbox):expand(self.padding):contains(x, y)
end

--[[

	Focus

--]]

function Element:canFocus()
	return false
end

function Element:focus()
	if not self:canFocus() then
		return false
	end

	-- Set focus
	if not self.hasFocus then
		self.hasFocus = true
		self:trigger("focus", self)
	end

	return true
end

function Element:blur()
	if not self:canFocus() then
		return false
	end

	-- Set focus
	if self.hasFocus then
		self.hasFocus = false
		self:trigger("blur", self)
	end

	return true
end

function Element:updateFocus(newFocus)
	-- Blur if this element lost focus
	if self ~= newFocus then
		self:blur()
	end
	-- Bubble up to parent
	if self.parent ~= nil then
		self.parent:updateFocus(newFocus)
	end
end

function Element:mouseClick(button, x, y)
	if button == 1 then
		-- Left mouse button
		-- Take focus when focusable and contains mouse pointer
		if self:canFocus() and self:contains(x, y) then
			self:focus()
		end
	end
end

--[[

	Painting

]]--

-- Get the output device for drawing
function Element:getOutput()
	-- Bubble up to parent
	return self.parent:getOutput()
end

--[[function Element:markRepaint()
	self.needsRepaint = true
end

function Element:unmarkRepaint()
	self.needsRepaint = false
end]]--

function Element:paint()
	if not self.isVisible then return end
	self:trigger("beforepaint")
	if self.bbox ~= nil then
		self:trigger("paint")
	end
	self:trigger("afterpaint")
end

-- Clear element's bounding box
function Element:clear()
	local bbox = self.bbox
	for y=0,bbox.h-1 do
		for x=0,bbox.w-1 do
			self:draw(bbox.x + x, bbox.y + y, " ", self.foreground, self.background)
		end
	end
end

-- Draw single text line within bounding rectangle
function Element:draw(x, y, text, fgColor, bgColor, bounds)
	if type(x) == "table" then
		-- Position given as vector
		return self:draw(x.x, x.y, y, text, fgColor, bgColor)
	end

	if bounds then
		-- Check vertical bounds
		if y < bounds.y or y >= bounds.y + bounds.h then
			return
		end
		-- Limit to horizontal bounds
		local startIdx = 1 + math.max(0, bounds.x - x)
		local endIdx = math.min(#text, bounds.x + bounds.w - x)
		text = string.sub(text, startIdx, endIdx)
		x = x + startIdx - 1
	end

	self:drawUnsafe(x, y, text, fgColor, bgColor)
end

-- Unsafe drawing
function Element:drawUnsafe(x, y, text, fgColor, bgColor)
	-- Draw on parent
	if self.isVisible and self.parent ~= nil then
		self.parent:drawUnsafe(x, y, text, fgColor, bgColor)
	end
end

-- Draw line
function Element:drawLine(line, color)
	-- Draw each point along the line
	for i,point in ipairs(line:points()) do
		self:draw(point, " ", colours.white, color)
	end
end

-- Draw single border
function Element:drawSingleBorder(side)
	if(self.border:has(side)) then
		self:drawLine(self.bbox[side](self.bbox), self.border:get(side))
	end
end

-- Draw all borders
function Element:drawBorder()
	self:drawSingleBorder("left")
	self:drawSingleBorder("right")
	self:drawSingleBorder("top")
	self:drawSingleBorder("bottom")
end

-- Bubble event up to parent
function Element:bubbleEvent(event)
	self:on(event, function(self, ...)
		if self.parent ~= nil then
			self.parent:trigger(event, ...)
		end
	end, self)
end

-- Exports
return Element