--[[

	ComputerCraft GUI
	Scrollable element

--]]

local Trait			= require "objectlua.Traits.Trait"
local Slider		= require "ccgui.Slider"
local MeasureSpec	= require "ccgui.MeasureSpec"
local Margins		= require "ccgui.geom.Margins"
local Rectangle		= require "ccgui.geom.Rectangle"

local ScrollSlider = Slider:subclass("ccgui.scroll.ScrollSlider")
function ScrollSlider:initialize(opts)
	super.initialize(self, opts)

	self:on("beforepaint", self.sliderLayout, self)
end
function ScrollSlider:sliderLayout()
	error("ScrollSlider:sliderLayout() not implemented")
end
function ScrollSlider:getStep()
	return 1
end
function ScrollSlider:getMinimum()
	return 0
end

local HorizontalSlider = ScrollSlider:subclass("ccgui.scroll.HorizontalScrollSlider")
function HorizontalSlider:initialize(opts)
	opts.horizontal = true
	opts.arrowLabels = { "<", ">" }
	super.initialize(self, opts)
end
function HorizontalSlider:sliderLayout()
	-- Place below inner box of scroll element
	local sbox = self.parent:inner(self.parent.bbox)
	local bbox = Rectangle:new(sbox.x, sbox.y + sbox.h, sbox.w, 1)
	-- Update layout
	self:measure(MeasureSpec:new(bbox))
	self:layout(bbox)
end
function HorizontalSlider:getValue()
	return self.parent.scrollPosition.x
end
function HorizontalSlider:rawSetValue(newValue)
	self.parent:setScrollX(newValue)
end
function HorizontalSlider:getSpan()
	return self.parent:scrollVisible().x
end
function HorizontalSlider:getMaximum()
	return self.parent:scrollTotal().x
end

local VerticalSlider = ScrollSlider:subclass("ccgui.scroll.VerticalScrollSlider")
function VerticalSlider:initialize(opts)
	opts.horizontal = false
	opts.arrowLabels = { "^", "v" }
	super.initialize(self, opts)
end
function VerticalSlider:sliderLayout()
	-- Place at right of inner box of scroll element
	local sbox = self.parent:inner(self.parent.bbox)
	local bbox = Rectangle:new(sbox.x + sbox.w, sbox.y, 1, sbox.h)
	-- Update layout
	self:measure(MeasureSpec:new(bbox))
	self:layout(bbox)
end
function VerticalSlider:getValue()
	return self.parent.scrollPosition.y
end
function VerticalSlider:rawSetValue(newValue)
	self.parent:setScrollY(newValue)
end
function VerticalSlider:getSpan()
	return self.parent:scrollVisible().y
end
function VerticalSlider:getMaximum()
	return self.parent:scrollTotal().y
end

local Scrollable = Trait:new("Scrollable")
function Scrollable:initializeScroll(opts)
	-- Orientation
	self.horizontal = not not opts.horizontal
	self.vertical = (opts.vertical == nil) or (not not opts.vertical)
	-- Show scroll bars
	self.showScrollBars = (opts.showScrollBars == nil) or (not not opts.showScrollBars)
	-- Mouse scroll
	self.mouseScroll = not not opts.mouseScroll
	-- Colors
	self.colorForeground = opts.colorForeground or colours.grey
	self.colorBar = opts.colorBar or colours.grey
	self.colorButton = opts.colorButton or colours.lightGrey

	-- Relative scroll position
	self.scrollPosition = vector.new(0, 0)
	-- Sliders
	self.sliderHoriz = HorizontalSlider:new({
		parent			= self,
		colorForeground	= self.colorForeground,
		colorBar		= self.colorBar,
		colorButton		= self.colorButton
	})
	self.sliderVerti = VerticalSlider:new({
		parent			= self,
		colorForeground	= self.colorForeground,
		colorBar		= self.colorBar,
		colorButton		= self.colorButton
	})

	-- Mouse
	self:sinkScrollBarEvent("mouse_click")
	self:sinkScrollBarEvent("mouse_drag")
	self:on("mouse_scroll", self.scrollMouse, self)

	-- Paint
	self:on("paint", self.scrollPaint, self)
end

function Scrollable:canScroll()
	return true
end

function Scrollable:setScrollX(scrollX)
	if self.scrollPosition.x ~= scrollX then
		self.scrollPosition.x = scrollX
		self:markRepaint()
	end
end

function Scrollable:setScrollY(scrollY)
	if self.scrollPosition.y ~= scrollY then
		self.scrollPosition.y = scrollY
		self:markRepaint()
	end
end

function Scrollable:setScrollPosition(scrollX, scrollY)
	self:setScrollX(scrollX)
	self:setScrollY(scrollY)
end

-- Relative visible scroll region
function Scrollable:scrollVisible()
	error("Scrollable:scrollVisible() not implemented")
end

-- Relative total scroll size
function Scrollable:scrollTotal()
	error("Scrollable:scrollTotal() not implemented")
end

-- Extra margins due to scroll bar
function Scrollable:scrollBarMargins()
	if self.showScrollBars then
		local right = self.vertical and 1 or 0
		local bottom = self.horizontal and 1 or 0
		return Margins:new(0, right, bottom, 0)
	end
	return Margins:new(0)
end

function Scrollable:scrollInner(bbox)
	return bbox:contract(self:scrollBarMargins())
end

function Scrollable:scrollOuter(bbox)
	return bbox:expand(self:scrollBarMargins())
end

function Scrollable:scrollMarkPaint()
	-- Repaint scrollbars
	if self.horizontal then
		self.sliderHoriz:markRepaint()
	end
	if self.vertical then
		self.sliderVerti:markRepaint()
	end
end

function Scrollable:scrollPaint(ctxt)
	if self.showScrollBars then
		-- Paint scrollbars
		if self.horizontal then
			self.sliderHoriz:paint(ctxt)
		end
		if self.vertical then
			self.sliderVerti:paint(ctxt)
		end
	end
end

function Scrollable:scrollMouse(dir, x, y)
	if self:isVisible() and self.mouseScroll and self:contains(x, y) then
		-- Prefer vertical over horizontal scrolling
		local slider = self.vertical and self.sliderVerti or self.sliderHorzi
		-- Step in scroll direction
		if dir < 0 then
			slider:prevStep()
		else
			slider:nextStep()
		end
	end
end

--[[

	Event sinking

]]--

function Scrollable:handleScrollBarSink(event, ...)
	if self:isVisible() and self.showScrollBars then
		if self.horizontal then
			self.sliderHoriz:trigger(event, ...)
		end
		if self.vertical then
			self.sliderVerti:trigger(event, ...)
		end
	end
end
function Scrollable:sinkScrollBarEvent(event)
	self:on(event, function(self, ...)
		self:handleScrollBarSink(event, ...)
	end, self, 1000)
end

-- Exports
return Scrollable