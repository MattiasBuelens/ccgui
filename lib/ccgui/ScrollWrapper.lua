--[[

	ComputerCraft GUI
	Scroll wrapper

--]]

local Container			= require "ccgui.Container"
local Scrollable		= require "ccgui.Scrollable"
local Margins			= require "ccgui.geom.Margins"
local Rectangle			= require "ccgui.geom.Rectangle"
local MeasureSpec		= require "ccgui.MeasureSpec"
local ChildDrawContext	= require "ccgui.paint.ChildDrawContext"

local ScrollWrapper = Container:subclass("ccgui.ScrollWrapper")
ScrollWrapper:uses(Scrollable)

function ScrollWrapper:initialize(opts)
	-- Mouse scroll by default
	opts.mouseScroll = (opts.mouseScroll == nil) or (not not opts.mouseScroll)

	super.initialize(self, opts)
	self:initializeScroll(opts)

	-- Content element
	self.content = opts.content
	self:add(self.content)
end

function ScrollWrapper:inner(bbox)
	return self:scrollInner(super.inner(self, bbox))
end
function ScrollWrapper:outer(bbox)
	return self:scrollOuter(super.inner(self, bbox))
end

function ScrollWrapper:scrollVisible()
	return self:inner(self.bbox):size()
end
function ScrollWrapper:scrollTotal()
	return self.content:inner(self.content.bbox):size()
end

function ScrollWrapper:getScreenOffset()
	return self:inner(self.bbox):tl() - self.scrollPosition - vector.new(1, 1)
end
function ScrollWrapper:fromScreen(x, y)
	local screenPos = type(x) == "table" and x or vector.new(x, y)
	return screenPos - self:getScreenOffset()
end
function ScrollWrapper:toScreen(x, y)
	local localPos = type(x) == "table" and x or vector.new(x, y)
	return localPos + self:getScreenOffset()
end

function ScrollWrapper:measure(spec)
	-- Get inner spec
	spec = self:inner(spec)
	
	-- Measure content with unconstrained specifications
	local cw = self.horizontal and "?" or spec.w
	local ch = self.vertical and "?" or spec.h
	self.content:measure(MeasureSpec:new(cw, ch))
	local contentSize = self.content.size
	
	-- Get own size
	local w, h
	if spec.w:isExact() then
		w = spec.w.value
	elseif spec.w:isUnspecified() then
		w = contentSize.w
	else
		w = math.min(spec.w.value, contentSize.w)
	end
	if spec.h:isExact() then
		h = spec.h.value
	elseif spec.h:isUnspecified() then
		h = contentSize.h
	else
		h = math.min(spec.h.value, contentSize.h)
	end
	
	-- Get inner bounding box
	local size = Rectangle:new(1, 1, w, h)
	-- Use outer size box
	self.size = self:outer(size)
end
function ScrollWrapper:layout(bbox)
	super.layout(self, bbox)
	self.content:layout(Rectangle:new(1, 1, self.content.size:size()))
end

function ScrollWrapper:markPaint()
	if not self.needsPaint then
		super.markPaint(self)
		-- Mark scrollbars
		self:scrollMarkPaint()
		-- Mark content
		self.content:markPaint()
	end
end
function ScrollWrapper:drawChildren(ctxt)
	-- Change context
	local offset = self:getScreenOffset()
	local clip = self:inner(self.bbox)
	local contentCtxt = ChildDrawContext:new(ctxt, offset.x, offset.y, clip)
	-- Draw content
	super.drawChildren(self, contentCtxt)
end
function ScrollWrapper:setCursorBlink(blink, x, y, color)
	if blink then
		-- Transform coordinates
		local blinkPos = self:toScreen(x, y)
		x, y = blinkPos.x, blinkPos.y
		-- Check bounds
		blink = self:contains(x, y)
	end
	return super.setCursorBlink(self, blink, x, y, color)
end

--[[

	Event sinking

]]--

function ScrollWrapper:scrollFilterEvent(event, ...)
	local args = { ... }
	if event == "mouse_click" or event == "mouse_scroll" or event == "mouse_drag" then
		local x, y = args[2], args[3]
		if self:contains(x, y) then
			-- Transform coordinates
			local localPos = self:fromScreen(x, y)
			args[2], args[3] = localPos.x, localPos.y
		end
	end
	return event, unpack(args)
end
function ScrollWrapper:handleSink(event, ...)
	super.handleSink(self, self:scrollFilterEvent(event, ...))
end
function ScrollWrapper:handleFocusSink(event, ...)
	super.handleFocusSink(self, self:scrollFilterEvent(event, ...))
end

-- Exports
return ScrollWrapper