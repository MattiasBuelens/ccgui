--[[

	ComputerCraft GUI
	Scrollable element

--]]

local Element		= require "ccgui.Element"
local Scrollable	= require "ccgui.Scrollable"

local ScrollElement = Element:subclass("ccgui.ScrollElement")
ScrollElement:uses(Scrollable)

function ScrollElement:initialize(opts)
	super.initialize(self, opts)
	self:initializeScroll(opts)
end

function ScrollElement:inner(bbox)
	return self:scrollInner(super.inner(self, bbox))
end

function ScrollElement:outer(bbox)
	return self:scrollOuter(super.inner(self, bbox))
end

function ScrollElement:markPaint()
	if not self.needsPaint then
		super.markPaint(self)
		self:scrollMarkPaint()
	end
end

-- Exports
return ScrollElement