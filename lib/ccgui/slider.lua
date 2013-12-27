--[[

	ComputerCraft GUI
	Slider

--]]

local Element		= require "ccgui.Element"
local Button		= require "ccgui.Button"
local FlowContainer	= require "ccgui.FlowContainer"
local Geometry		= require "ccgui.Geometry"
local Line, Rectangle = Geometry.Line, Geometry.Rectangle

local ArrowButton = Button.subclass("ccgui.slider.ArrowButton")
function ArrowButton:initialize(opts)
	-- Default style
	opts.border = 0
	opts.padding = 0
	super.initialize(self, opts)
end

local Bar = Element.subclass("ccgui.slider.Bar")
function Bar:initialize(opts)
	super.initialize(self, opts)

	-- Orientation
	self.horizontal = false
	-- Dragging
	self.dragStartPos = nil
	self.dragStartValue = nil

	self:on("beforepaint", self.barLayout, self)
	self:on("paint", self.barPaint, self)

	self:on("mouse_click", self.dragStart, self)
	self:on("mouse_drag", self.dragging, self)
end

function Bar:getBounds()
	assert(self.parent.bbox ~= nil, "slider not positioned")
	return self:inner(self.parent.bbox)
end

-- Get the available space for the bar
function Bar:getScreenRange()
	local bbox = self:getBounds()
	if self.horizontal then
		return bbox.w-1
	else
		return bbox.h-1
	end
end

-- Convert the given scroll value to a screen value
function Bar:toScreen(x)
	return x * self:getScreenRange() / self.parent:getRange()
end

-- Convert the given screen value to a scroll value
function Bar:fromScreen(x)
	return x * self.parent:getRange() / self:getScreenRange()
end

-- Get the line representing the bar
function Bar:getBarLine()
	local bbox = self:getBounds()

	-- Get value details
	local value, spanValue, maxValue = self.parent:getValue(), self.parent:getSpan(), self.parent:getMaximum()

	-- Get screen values
	local start = self:toScreen(value)
	local stop = self:toScreen(math.min(value + spanValue, maxValue))

	-- Get start and end positions
	local startPos, stopPos
	if self.horizontal then
		startPos = vector.new(math.floor(start), 0)
		stopPos = vector.new(math.floor(stop), 0)
	else
		startPos = vector.new(0, math.floor(start))
		stopPos = vector.new(0, math.floor(stop))
	end

	-- Create line
	return Line:new(bbox:tl() + startPos, bbox:tl() + stopPos)
end

-- Get the bounding rectangle of the bar
function Bar:getBarRect()
	local line = self:getBarLine()
	if self.horizontal then
		return Rectangle:new(line.start, line:length(), 1)
	else
		return Rectangle:new(line.start, 1, line:length())
	end
end

function Bar:barLayout()
	self.bbox = self:getBounds()
end

-- Draw the bar
function Bar:barPaint()
	-- Draw a line
	self:drawLine(self:getBarLine(), self.foreground)
end

-- Start dragging on mouse click on bar
function Bar:dragStart(button, x, y)
	if button == 1 and self.isVisible and self:getBarRect():contains(x, y) then
		-- Store starting position
		self.dragStartPos = vector.new(x, y)
		self.dragStartValue = self.parent:getValue()
	else
		-- Stop dragging
		self.dragStartPos = nil
		self.dragStartValue = nil
	end
end

-- Adjust the scroll position while dragging
function Bar:dragging(button, x, y)
	if button == 1 and self.dragStartPos ~= nil then
		-- Get drag delta
		local current = vector.new(x, y)
		local deltaPos = current - self.dragStartPos
		local delta
		if self.horizontal then
			delta = self:fromScreen(deltaPos.x)
		else
			delta = self:fromScreen(deltaPos.y)
		end
		-- Add delta to starting value
		self.parent:setValue(self.dragStartValue + math.floor(delta))
	end
end

local Slider = FlowContainer.subclass("ccgui.Slider")
function Slider:initialize(opts)
	super.initialize(self, opts)

	-- Orientation
	self.horizontal = not not opts.horizontal

	-- Arrow buttons
	self.showArrows = (type(opts.showArrows) == "nil") or (not not opts.showArrows)
	self.arrowLabels = opts.arrowLabels or { "-", "+" }

	-- Slider bar
	self.bar = Bar:new({
		parent		= self,
		horizontal	= self.horizontal,
		stretch		= true,
		foreground	= self.colorBar,
		background	= self.background
	})

	-- Arrow buttons
	self.showArrows = not not self.showArrows
	if self.showArrows then
		self.prevArrow = ArrowButton:new({
			parent		= self,
			text		= self.arrowLabels[1],
			foreground	= self.colorForeground,
			background	= self.colorButton
		})
		self.prevArrow:on("buttonpress", self.prevStep, self)
		self.nextArrow = ArrowButton:new({
			parent		= self,
			text		= self.arrowLabels[2],
			foreground	= self.colorForeground,
			background	= self.colorButton
		})
		self.nextArrow:on("buttonpress", self.nextStep, self)
		self:add(self.prevArrow, self.bar, self.nextArrow)
	else
		self:add(self.bar)
	end
end

function Slider:getValue()
	error("Slider:getValue() not implemented")
end

function Slider:rawSetValue(newValue)
	error("Slider:rawSetValue() not implemented")
end

function Slider:getStep()
	error("Slider:getStep() not implemented")
end

function Slider:getSpan()
	error("Slider:getSpan() not implemented")
end

function Slider:getMinimum()
	error("Slider:getMinimum() not implemented")
end

function Slider:getMaximum()
	error("Slider:getMaximum() not implemented")
end

function Slider:getRange()
	return self:getMaximum() - self:getMinimum()
end

function Slider:setValue(newValue)
	self:rawSetValue(self:normalizeValue(newValue))
end

function Slider:addValue(delta)
	self:setValue(self:getValue() + delta)
end

function Slider:normalizeValue(value)
	value = math.max(value, self:getMinimum())
	value = math.min(value, self:getMaximum() - self:getSpan())
	return value
end

function Slider:prevStep()
	self:addValue(-self:getStep())
end

function Slider:nextStep()
	self:addValue(self:getStep())
end

-- Exports
return Slider