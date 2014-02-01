--[[

	ComputerCraft GUI
	Window container

--]]

local Container	= require "ccgui.Container"
local Rectangle	= require "ccgui.geom.Rectangle"

local WindowContainer = Container:subclass("ccgui.WindowContainer")
function WindowContainer:initialize(opts)
	super.initialize(self, opts)

	self.foregroundWindow = nil

	self:on("mouse_click", self.windowsClick, self, 1000)
	self:on("mouse_drag", self.windowsDrag, self, 1000)
	
	self:on("add", self.markPaint, self)
	self:on("remove", self.markRepaint, self)

	self:on("add", self.updateForeground, self)
	self:on("remove", self.updateForeground, self)
	self:on("beforeremove", self.backgroundOnRemove, self)
end

function WindowContainer:getWindowCount()
	return #self.children
end
function WindowContainer:getWindow(i)
	return self.children[i]
end

function WindowContainer:getForegroundWindow()
	return self.foregroundWindow
end
function WindowContainer:bringToForeground(newForeground)
	local oldForeground = self:getForegroundWindow()
	if newForeground ~= oldForeground then
		oldForeground:trigger("window_background")
		self:move(newForeground, self:getWindowCount())
		self.foregroundWindow = newForeground
		newForeground:trigger("window_foreground")
		self:markRepaint()
	end
end
function WindowContainer:updateForeground()
	local n = self:getWindowCount()
	local oldForeground = self:getForegroundWindow()
	local newForeground = (n > 0 and self.children[n]) or nil
	if oldForeground ~= newForeground then
		if oldForeground ~= nil then
			oldForeground:trigger("window_background")
		end
		if newForeground ~= nil then
			newForeground:trigger("window_foreground")
		end
		self.foregroundWindow = newForeground
		self:markRepaint()
	end
end
function WindowContainer:backgroundOnRemove(removedWindow)
	removedWindow:trigger("window_background")
end

function WindowContainer:getWindowAt(x, y)
	if type(x) == "table" then
		-- Position given as vector
		x, y = x.x, x.y
	end
	-- Find window from foreground to background
	for i=self:getWindowCount(),1,-1 do
		local window = self:getWindow(i)
		if window:isVisible() and window:contains(x, y) then
			return window
		end
	end
	-- Not found
	return nil
end

function WindowContainer:markPaint()
	-- Temporarily ignore markPaint requests to prevent infinite recursion
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

function WindowContainer:measure(spec)
	super.measure(self, spec)
	self:each(function(window)
		window:measure(spec)
	end)
end
function WindowContainer:layout(bbox)
	super.layout(self, bbox)
	self:each(function(window)
		window:layout(Rectangle:new(bbox:tl(), window.size:size()))
	end)
end

function WindowContainer:windowsClick(button, x, y, ...)
	-- Click on containing window
	if self:isVisible() and self:contains(x, y) then
		local window = self:getWindowAt(x, y)
		if window ~= nil then
			return window:trigger("mouse_click", button, x, y, ...)
		end
	end
end
function WindowContainer:windowsDrag(button, x, y, ...)
	-- Drag foreground window
	local window = self:getForegroundWindow()
	if window ~= nil and window:isVisible() then
		window:trigger("mouse_drag", button, x, y, ...)
	end
end

function WindowContainer:handleSink(event, ...)
	-- Prevent sinking mouse_click and mouse_drag to all windows
	-- Manually handled in windowsClick and windowsDrag
	if event ~= "mouse_click" and event ~= "mouse_drag" then
		return super.handleSink(self, event, ...)
	end
end

function WindowContainer:checkChildFocused(child)
	-- Must be foreground child
	return super.checkChildFocused(self, child)
		and child == self:getForegroundWindow()
end

-- Exports
return Window