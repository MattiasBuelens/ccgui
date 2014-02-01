--[[

	ComputerCraft GUI
	Scroll wrapper

--]]

local ScrollElement		= require "ccgui.ScrollElement"
local Margins			= require "ccgui.geom.Margins"
local Rectangle			= require "ccgui.geom.Rectangle"
local ChildDrawContext	= require "ccgui.paint.ChildDrawContext"

local ScrollWrapper = ScrollElement:subclass("ccgui.ScrollWrapper")
function ScrollWrapper:initialize(opts)
	-- Mouse scroll by default
	opts.mouseScroll = (opts.mouseScroll == nil) or (not not opts.mouseScroll)

	super.initialize(self, opts)

	-- Content element
	self.content = opts.content
	self.content.parent = self

	-- Mouse
	self:sinkEvent("mouse_click")
	self:sinkEvent("mouse_drag")

	-- Paint
	self:on("paint", self.scrollContentPaint, self)
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

function ScrollWrapper:measure(size)
	local ownSize = self:inner(size)
	-- Update content size
	local w = self.horizontal and math.huge or ownSize.w
	local h = self.vertical and math.huge or ownSize.h
	self.content:measure(Rectangle:new(1, 1, w, h))
	local contentSize = self.content.size
	-- Update own size
	ownSize.w = self.horizontal and math.min(ownSize.w, contentSize.w) or contentSize.w
	ownSize.h = self.vertical and math.min(ownSize.h, contentSize.h) or contentSize.h
	size = self:outer(ownSize)
	super.measure(self, size)
end
function ScrollWrapper:layout(bbox)
	super.layout(self, bbox)
	self.content:layout(Rectangle:new(1, 1, self.content.size:size()))
end

function ScrollWrapper:markPaint()
	if not self.needsPaint then
		super.markPaint(self)
		self.content:markPaint()
	end
end
function ScrollWrapper:markRepaint()
	if not self.needsRepaint then
		super.markRepaint(self)
		self.content:markRepaint()
	end
end
function ScrollWrapper:scrollContentPaint(ctxt)
	local offset = self:getScreenOffset()
	local clip = self:inner(self.bbox)
	local contentCtxt = ChildDrawContext:new(ctxt, offset.x, offset.y, clip)
	self.content:paint(contentCtxt)
end

--[[

	Event sinking

]]--

function ScrollWrapper:handleSink(event, ...)
	local args = { ... }
	if event == "mouse_click" or event == "mouse_scroll" or event == "mouse_drag" then
		local x, y = args[2], args[3]
		if self:contains(x, y) then
			-- Transform coordinates
			local localPos = self:fromScreen(x, y)
			args[2], args[3] = localPos.x, localPos.y
		end
	end
	self.content:trigger(event, unpack(args))
end
function ScrollWrapper:sinkEvent(event)
	self:on(event, function(self, ...)
		self:handleSink(event, ...)
	end, self, 1000)
end

-- Exports
return ScrollWrapper