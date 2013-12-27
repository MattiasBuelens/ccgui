--[[

	ComputerCraft GUI
	Scrollable element

--]]

ccgui = ccgui or {}

local ScrollSlider = common.newClass(ccgui.Slider)
function ScrollSlider:init()
	ccgui.Slider.init(self)

	self:on("beforepaint", self.sliderLayout, self, -1)
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

local HorizontalSlider = common.newClass({
	horizontal	= true,
	arrowLabels	= { "<", ">" }
}, ScrollSlider)
function HorizontalSlider:sliderLayout()
	-- Place below inner box of scroll element
	local sbox = self.parent:inner(self.parent.bbox)
	self.bbox = ccgui.newRectangle(sbox.x, sbox.y + sbox.h, sbox.w, 1)
end
function HorizontalSlider:getValue()
	return self.parent.scrollPosition.x
end
function HorizontalSlider:rawSetValue(newValue)
	self.parent.scrollPosition.x = newValue
	--self.parent:markRepaint()
end
function HorizontalSlider:getSpan()
	return self.parent:scrollVisible().x
end
function HorizontalSlider:getMaximum()
	return self.parent:scrollTotal().x
end

local VerticalSlider = common.newClass({
	horizontal = false,
	arrowLabels	= { "^", "v" }
}, ScrollSlider)
function VerticalSlider:sliderLayout()
	-- Place at right of inner box of scroll element
	local sbox = self.parent:inner(self.parent.bbox)
	self.bbox = ccgui.newRectangle(sbox.x + sbox.w, sbox.y, 1, sbox.h)
end
function VerticalSlider:getValue()
	return self.parent.scrollPosition.y
end
function VerticalSlider:rawSetValue(newValue)
	self.parent.scrollPosition.y = newValue
	--self.parent:markRepaint()
end
function VerticalSlider:getSpan()
	return self.parent:scrollVisible().y
end
function VerticalSlider:getMaximum()
	return self.parent:scrollTotal().y
end

local ScrollElement = common.newClass({
	-- Orientation
	horizontal		= false,
	vertical		= true,
	-- Show scroll bars
	showScrollBars	= true,
	-- Mouse scroll
	mouseScroll		= false,
	-- Colors
	colorForeground	= colours.grey,
	colorBar		= colours.grey,
	colorButton		= colours.lightGrey,
	-- Relative scroll position
	scrollPosition	= nil,
	-- Sliders
	sliderHoriz		= nil,
	sliderVerti		= nil
}, ccgui.Element)
ccgui.ScrollElement = ScrollElement

function ScrollElement:init()
	ccgui.Element.init(self)

	-- Scroll position
	self.scrollPosition = vector.new(0, 0)

	-- Orientation
	self.horizontal = not not self.horizontal
	self.vertical = not not self.vertical

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
	self:sinkEvent("mouse_click")
	self:sinkEvent("mouse_drag")
	self:on("mouse_scroll", self.scrollMouse, self)

	-- Paint
	self:on("paint", self.scrollPaint, self)
end

function ScrollElement:canScroll()
	return true
end

-- Relative visible scroll region
function ScrollElement:scrollVisible()
	error("ScrollElement:scrollVisible() not implemented")
end

-- Relative total scroll size
function ScrollElement:scrollTotal()
	error("ScrollElement:scrollTotal() not implemented")
end

-- Extra margins due to scroll bar
function ScrollElement:scrollBarMargins()
	if self.showScrollBars then
		local right, bottom = 0, 0
		if self.horizontal then
			bottom = 1
		end
		if self.vertical then
			right = 1
		end
		return ccgui.newMargins(0, right, bottom, 0)
	end

	return ccgui.newMargins(0)
end

function ScrollElement:inner(bbox)
	return ccgui.Element.inner(self, bbox):contract(self:scrollBarMargins())
end

function ScrollElement:outer(bbox)
	return ccgui.Element.outer(self, bbox:expand(self:scrollBarMargins()))
end

function ScrollElement:scrollPaint()
	if self.showScrollBars then
		if self.horizontal then
			self.sliderHoriz:paint()
		end
		if self.vertical then
			self.sliderVerti:paint()
		end
	end
end

function ScrollElement:scrollMouse(dir, x, y)
	if self.isVisible and self.mouseScroll and self:contains(x, y) then
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

function ScrollElement:sinkEvent(event)
	self:on(event, function(self, ...)
		if self.isVisible and self.showScrollBars then
			if self.horizontal then
				self.sliderHoriz:trigger(event, ...)
			end
			if self.vertical then
				self.sliderVerti:trigger(event, ...)
			end
		end
	end, self)
end