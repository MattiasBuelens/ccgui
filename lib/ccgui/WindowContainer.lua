--[[

	ComputerCraft GUI
	Window container

--]]

local Container	= require "ccgui.Container"

local WindowContainer = Container:subclass("ccgui.WindowContainer")
function WindowContainer:initialize(opts)
	super.initialize(self, opts)
	
	self:on("add", self.markPaint, self)
	self:on("remove", self.markRepaint, self)
end

function WindowContainer:windowCount()
	return #self.children
end

function WindowContainer:bringToFront(window)
	local i = self:find(window, false)
	assert(i ~= nil, "cannot bring non-child window to front")
	-- Reinsert at end
	table.remove(self.children, i)
	table.insert(self.children, window)
	self:markRepaint()
end

function WindowContainer:markPaint()
	-- Temporarily ignore markPaint requests
	-- to prevent infinite recursion
	if self.ignorePaints then return end
	self.ignorePaints = true

	super.markPaint(self)

	-- Painter's algorithm
	local repaint = false
	self:each(function(window)
		if repaint then
			window:markRepaint()
		elseif window.needsPaint then
			repaint = true
		end
	end)
	if repaint then
		self:markRepaint()
	end

	-- Re-enable paints
	self.ignorePaints = false
end

function WindowContainer:calcSize(size)
	self.size = size
end
function WindowContainer:calcLayout(bbox)
	super.calcLayout(self, bbox)
	self:each(function(window)
		window:updateLayout(bbox)
	end)
end

-- Exports
return Window