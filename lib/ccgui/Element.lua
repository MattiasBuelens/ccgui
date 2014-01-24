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
	-- Copy all options (includes extensions such as "stretch")
	for k,v in pairs(opts) do
		self[k] = v
	end

	-- Parent element
	self.parent = opts.parent or nil
	-- Visibility
	self.isVisible = (opts.isVisible == nil) or (not not opts.isVisible)
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
	self:on("mouse_click", self.focusOnClick, self)
	-- Paint
	self:on("repaint", self.drawBackground, self)
	self:on("paint", self.drawBorder, self)

	-- Bubble focus events
	self:bubbleEvent("focus")
	self:bubbleEvent("blur")

	-- Need repaint
	self.needsPaint = true
	self.needsRepaint = true
end

function Element:visible()
	if not self.isVisible then
		return false
	end
	if self.parent ~= nil then
		return self.parent:visible()
	end
	-- TODO What about detached children?
	return true
end

function Element:show()
	if not self.isVisible then
		self:markRepaint()
		self.isVisible = true
		return true
	end
	return false
end

function Element:hide()
	if self.isVisible then
		if self.parent ~= nil then
			self.parent:markRepaint()
		end
		self:blur()
		self.isVisible = false
		return true
	end
	return false
end

function Element:getScheduler()
	if self.scheduler ~= nil then
		return self.scheduler
	end
	if self.parent ~= nil then
		return self.parent:getScheduler()
	end
	return nil
end

--[[

	Bounding box

--]]

-- Inner bounding box, without border and padding
function Element:inner(bbox)
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

function Element:focused(elem)
	if self:checkFocused(elem) then
		-- Bubble up to parent
		return (self.parent == nil) or self.parent:focused(self)
	end
	return false
end

function Element:checkFocused(elem)
	if elem == nil or elem == self then
		-- Must have visible focus
		return self:canFocus() and self.hasFocus and self.isVisible
	end
end

function Element:focus()
	if not self:canFocus() then
		return false
	end
	
	-- Grab focus
	self:updateFocus(self)

	return true
end

function Element:blur()
	if not self:canFocus() then
		return false
	end

	-- Lose focus
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
	-- Trigger focus if gained focus
	if self == newFocus and not self.hasFocus then
		self.hasFocus = true
		self:trigger("focus", self)
	end
end

function Element:focusOnClick(button, x, y)
	if button == 1 then
		-- Left mouse button
		-- Take focus when focusable and contains mouse pointer
		if self:canFocus() and not self.hasFocus and self:contains(x, y) then
			self:focus()
		end
	end
end

--[[

	Painting

]]--

function Element:setCursorBlink(blink, x, y, color)
	if self.parent ~= nil then
		return self.parent:setCursorBlink(blink, x, y, color)
	end
	return false
end

function Element:markPaint()
	if not self.needsPaint then
		self.needsPaint = true
		if self.parent ~= nil then
			self.parent:markPaint()
		end
	end
end

function Element:markRepaint()
	self.needsRepaint = true
	self:markPaint()
end

function Element:unmarkPaint()
	self.needsPaint = false
	self.needsRepaint = false
end

function Element:paint()
	-- Ignore if invisible or no paint requested
	if not self:visible() then return end
	if not self.needsPaint then return end

	self:trigger("beforepaint")
	if self.bbox ~= nil then
		-- Repaint
		if self.needsRepaint then
			self:trigger("repaint")
		end
		-- Paint
		self:trigger("paint")
	end
	self:trigger("afterpaint")
	self:unmarkPaint()
end

-- Fill element's bounding box with background color
function Element:drawBackground()
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
		x, y, text, fgColor, bgColor, bounds = x.x, x.y, y, text, fgColor, bgColor
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
	-- Fill in transparency
	fgColor = fgColor ~= 0 and fgColor or self.foreground
	bgColor = bgColor ~= 0 and bgColor or self.background
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
	if self.border:has(side) then
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