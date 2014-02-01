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
	self.visible = (opts.visible == nil) or (not not opts.visible)
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

function Element:isVisible()
	if not self.visible then
		return false
	end
	if self.parent ~= nil then
		return self.parent:isVisible()
	end
	-- TODO What about detached children?
	return true
end

function Element:show()
	if not self.visible then
		self:markRepaint()
		self.visible = true
		return true
	end
	return false
end

function Element:hide()
	if self.visible then
		if self.parent ~= nil then
			self.parent:markRepaint()
		end
		self:blur()
		self.visible = false
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

-- Update element size within given size box
function Element:updateSize(size)
	self.size = size
end

-- Update element layout within given bounding box
function Element:updateLayout(bbox)
	self.bbox = bbox
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

function Element:hasFocus(elem)
	if self:checkFocused(elem) then
		-- Bubble up to parent
		return (self.parent == nil) or self.parent:hasFocus(self)
	end
	return false
end

function Element:checkFocused(elem)
	if elem == nil or elem == self then
		-- Must have visible focus
		return self:canFocus() and self.focused and self.visible
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
	if self.focused then
		self.focused = false
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
	if self == newFocus and not self.focused then
		self.focused = true
		self:trigger("focus", self)
	end
end

function Element:focusOnClick(button, x, y)
	if button == 1 then
		-- Left mouse button
		-- Take focus when focusable and contains mouse pointer
		if self:canFocus() and not self.focused and self:contains(x, y) then
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

function Element:paint(ctxt)
	-- Ignore if invisible or no paint requested
	if not self:isVisible() then return end
	if not self.needsPaint then return end

	self:trigger("beforepaint")
	if self.bbox ~= nil then
		-- Repaint
		if self.needsRepaint then
			self:trigger("repaint", ctxt)
		end
		-- Paint
		self:trigger("paint", ctxt)
	end
	self:trigger("afterpaint")
	self:unmarkPaint()
end

function Element:getForeground()
	if self.foreground == 0 and self.parent ~= nil then
		return self.parent:getForeground()
	end
	return self.foreground
end
function Element:getBackground()
	if self.background == 0 and self.parent ~= nil then
		return self.parent:getBackground()
	end
	return self.background
end

-- Fill element's bounding box with background color
function Element:drawBackground(ctxt)
	ctxt:drawRect(self.bbox, self:getBackground())
end

-- Draw element's border
function Element:drawBorder(ctxt)
	ctxt:drawBorder(self.bbox, self.border)
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