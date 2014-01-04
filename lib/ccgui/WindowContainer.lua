--[[

	ComputerCraft GUI
	Window container

--]]

local Container	= require "ccgui.Container"

local WindowContainer = Container:subclass("ccgui.WindowContainer")
function WindowContainer:initialize(opts)
	super.initialize(self, opts)
	
	self.sunkMouseEvents = {}
	self:unsinkEvent("mouse_click")
	self:unsinkEvent("mouse_drag")
	self:on("mouse_click", self.windowsClick, self, 1000)
	self:on("mouse_drag", self.windowsDrag, self, 1000)
	
	self:on("add", self.markPaint, self)
	self:on("remove", self.markRepaint, self)
end

function WindowContainer:getWindowCount()
	return #self.children
end
function WindowContainer:getWindow(i)
	return self.children[i]
end
function WindowContainer:getForegroundWindow()
	return self:getWindow(self:getWindowCount())
end

function WindowContainer:bringToFront(window)
	self:move(window, self:getWindowCount())
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

function WindowContainer:windowsClick(button, x, y, ...)
	-- Click on most front window
	if self:visible() and self:contains(x, y) then
		for i=self:getWindowCount(),1,-1 do
			local window = self:getWindow(i)
			if window:visible() and window:contains(x, y) then
				return window:trigger("mouse_click", button, x, y, ...)
			end
		end
	end
end

function WindowContainer:windowsDrag(button, x, y, ...)
	-- Drag foreground window
	local window = self:getForegroundWindow()
	if window ~= nil and window:visible() then
		window:trigger("mouse_drag", button, x, y, ...)
	end
end

function WindowContainer:handleFocusSink(event, ...)
	-- Only sink focus when focused is on foreground
	if self.childFocus == self:getWindowCount() then
		super.handleFocusSink(self, event, ...)
	end
end

-- Exports
return Window