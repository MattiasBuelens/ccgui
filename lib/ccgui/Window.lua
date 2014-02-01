--[[

	ComputerCraft GUI
	Window

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local TextElement	= require "ccgui.TextElement"
local Button		= require "ccgui.Button"
local ToggleButton	= require "ccgui.ToggleButton"
local Rectangle		= require "ccgui.geom.Rectangle"

local TitleBar = FlowContainer:subclass("ccgui.window.TitleBar")
function TitleBar:initialize(opts)
	opts.horizontal = true
	super.initialize(self, opts)

	-- Permissions
	self.maximizable = (opts.maximizable == nil) or (not not opts.maximizable)
	self.closable = (opts.closable == nil) or (not not opts.closable)

	-- Title
	self.titleText = TextElement:new{
		text = self.text or "",
		align = ccgui.Align.Center,
		stretch = true,
		foreground = self.foreground,
		background = self.background
	}
	
	-- Minimize/maximize button
	self.minmaxButton = ToggleButton:new{
		labelOff = "+",
		labelOn = "-",
		padding = 0
	}
	self:setMaximizable(self.maximizable)
	self.minmaxButton:on("toggleon", self.maximize, self)
	self.minmaxButton:on("toggleoff", self.restoreSize, self)
	
	-- Close button
	self.closeButton = Button:new{
		text = "x",
		padding = 0,
		foreground = colours.white,
		background = colours.red
	}
	self:setClosable(self.closable)
	self.closeButton:on("buttonpress", self.close, self)
	self:add(self.titleText, self.minmaxButton, self.closeButton)
	
	-- Dragging
	self.dragStartPos = nil
	self.dragStartValue = nil
	self.titleText:on("mouse_click", self.dragStart, self)
	self.titleText:on("mouse_drag", self.dragging, self)
end

function TitleBar:isMaximizable()
	return self.maximizable
end
function TitleBar:setMaximizable(value)
	self.maximizable = value
	if value then
		self.minmaxButton:show()
	else
		self.minmaxButton:hide()
	end
end
function TitleBar:updateMaximized()
	self.minmaxButton:setState(self.parent.isMaximized)
end
function TitleBar:isClosable()
	return self.closable
end
function TitleBar:setClosable(value)
	self.closable = value
	if value then
		self.closeButton:show()
	else
		self.closeButton:hide()
	end
end

function TitleBar:setText(text)
	self.text = text or ""
	self.titleText:setText(self.text)
end
function TitleBar:maximize()
	self.parent:maximize()
end
function TitleBar:restoreSize()
	self.parent:restoreSize()
end
function TitleBar:close()
	self.parent:close()
end

function TitleBar:canDrag()
	return not self.parent.isMaximized
end

-- Start dragging
function TitleBar:dragStart(button, x, y)
	if button == 1 and self:isVisible() and self:canDrag() and self.titleText:contains(x, y) then
		-- Store starting position
		self.dragStartPos = vector.new(x, y)
		self.dragStartValue = self.parent:getPosition()
	else
		-- Stop dragging
		self.dragStartPos = nil
	end
end

-- Position window while dragging
function TitleBar:dragging(button, x, y)
	if button == 1 and self:isVisible() and self:canDrag() and self.dragStartPos ~= nil then
		-- Get drag delta
		local current = vector.new(x, y)
		local delta = current - self.dragStartPos
		-- Set window position
		self.parent:setPosition(self.dragStartValue + delta)
	end
end

local ResizeHandle = TextElement:subclass("ccgui.window.ResizeHandle")
function ResizeHandle:initialize(opts)
	opts.foreground = opts.foreground or colours.white
	opts.background = opts.background or colours.lightGrey
	opts.text = opts.text or "/"
	
	super.initialize(self, opts)
	
	-- Dragging
	self.dragStartPos = nil
	self.dragStartSize = nil
	self:on("mouse_click", self.dragStart, self)
	self:on("mouse_drag", self.dragging, self)
end

function ResizeHandle:getWindow()
	return self.parent.parent
end
function ResizeHandle:canDrag()
	return not self.parent.parent.isMaximized
end

-- Start dragging
function ResizeHandle:dragStart(button, x, y)
	if button == 1 and self:isVisible() and self:canDrag() and self:contains(x, y) then
		-- Store starting position
		self.dragStartPos = vector.new(x, y)
		self.dragStartSize = self:getWindow():getSize()
	else
		-- Stop dragging
		self.dragStartPos = nil
	end
end

-- Resize window while dragging
function ResizeHandle:dragging(button, x, y)
	if button == 1 and self:isVisible() and self:canDrag() and self.dragStartPos ~= nil then
		-- Get drag delta
		local current = vector.new(x, y)
		local delta = current - self.dragStartPos
		-- Set window size
		self:getWindow():setSize(self.dragStartSize + delta)
	end
end

local StatusBar = FlowContainer:subclass("ccgui.window.StatusBar")
function StatusBar:initialize(opts)
	opts.background = opts.background or colours.lightGrey
	opts.horizontal = true
	
	super.initialize(self, opts)
	
	-- Status text
	self.statusText = TextElement:new{
		foreground = opts.statusForeground or colours.white,
		stretch = true
	}
	-- Resize handle
	self.resizeHandle = ResizeHandle:new{
		foreground = opts.resizeForeground
	}
	self:add(self.statusText, self.resizeHandle)
	
	self:setResizable(true)
end

function StatusBar:setText(text)
	self.statusText:setText(text)
end
function StatusBar:setResizable(resizable)
	if resizable then
		self.resizeHandle:show()
	else
		self.resizeHandle:hide()
	end
end
function StatusBar:updateMaximized()
	self:setResizable(not self.parent.isMaximized)
end

local Window = FlowContainer:subclass("ccgui.Window")
function Window:initialize(opts)
	super.initialize(self, {
		horizontal = false,
		spacing = 0
	})

	-- Window positioning
	local pos = opts.windowPos or vector.new(0, 0)
	local size = opts.windowSize or vector.new(15, 10)
	self.windowBox = opts.windowBox or Rectangle:new(pos, size)

	-- Title bar
	self.titleBar = TitleBar:new{
		foreground = opts.titleForeground or colours.white,
		background = opts.titleBackground or colours.blue,
		maximizable = opts.maximizable,
		closable = opts.closable
	}
	self:setTitle(opts.title or "")
	self:on("maximize", self.titleBar.updateMaximized, self.titleBar)
	self:on("restore", self.titleBar.updateMaximized, self.titleBar)

	-- Content pane
	self.contentPane = opts.contentPane or FlowContainer:new(opts)
	self.contentPane.stretch = true
	
	-- Status bar
	self.statusBar = StatusBar:new{
		background = opts.statusBackground
	}
	self:on("maximize", self.statusBar.updateMaximized, self.statusBar)
	self:on("restore", self.statusBar.updateMaximized, self.statusBar)
	
	self:add(self.titleBar, self.contentPane, self.statusBar)
	
	self:on("mouse_click", self.foregroundOnClick, self)
	self:on("window_background", self.hideCursorBlink, self)
	self:on("window_foreground", self.showCursorBlink, self)
end

function Window:content()
	return self.contentPane
end
function Window:setTitle(title)
	return self.titleBar:setText(title)
end

function Window:isMaximizable()
	return self.titleBar:isMaximizable()
end
function Window:setMaximizable(value)
	self.titleBar:setMaximizable(value)
end
function Window:isClosable()
	return self.titleBar:isClosable()
end
function Window:setClosable(value)
	self.titleBar:setClosable(value)
end

function Window:setStatusText(text)
	return self.statusBar:setText(text)
end

function Window:maximize()
	if not self.isMaximized then
		self.isMaximized = true
		self:markRepaint()
		self:bringToForeground()
		self:trigger("maximize")
	end
end
function Window:restoreSize()
	if self.isMaximized then
		self.isMaximized = false
		self:markRepaint()
		self:bringToForeground()
		self:trigger("restore")
	end
end
function Window:isForeground()
	if not self:isVisible() then
		return false
	end
	if self.parent ~= nil then
		return self == self.parent:getForegroundWindow()
	end
	return true
end
function Window:bringToForeground()
	self.parent:bringToForeground(self)
end
function Window:close()
	self:trigger("close")
	self.parent:remove(self)
end

function Window:getPosition()
	return self.windowBox:tl()
end
function Window:setPosition(x, y)
	assert(not self.isMaximized, "cannot change position when maximized")
	if type(x) == "table" then
		-- Vector
		x, y = x.x, x.y
	end
	if self.windowBox.x ~= x or self.windowBox.y ~= y then
		self.windowBox.x, self.windowBox.y = x, y
		self:markRepaint()
	end
end
function Window:getSize()
	return self.windowBox:size()
end
function Window:setSize(w, h)
	assert(not self.isMaximized, "cannot change size when maximized")
	if type(w) == "table" then
		if w.w then
			-- Rectangle
			w, h = w.w, w.h
		else
			-- Vector
			w, h = w.x, w.y
		end
	end
	if self.windowBox.w ~= w or self.windowBox.h ~= h then
		self.windowBox.w, self.windowBox.h = w, h
		self:markRepaint()
	end
end

function Window:markRepaint()
	if not self.needsRepaint then
		-- Repaint parent window container
		if self.parent ~= nil then
			self.parent:markRepaint()
		end
	end
	super.markRepaint(self)
end
function Window:updateSize(size)
	if not self.isMaximized then
		size = Rectangle:new(self.windowBox)
	end
	return super.updateSize(self, size)
end
function Window:updateLayout(bbox)
	if not self.isMaximized then
		bbox = self.windowBox:shift(bbox:tl())
	end
	return super.updateLayout(self, bbox)
end

-- Bring to foreground on click
function Window:foregroundOnClick(button, x, y)
	if button == 1 and self:isVisible() and self:contains(x, y) then
		self:bringToForeground()
	end
end

function Window:setCursorBlink(blink, x, y, color)
	self:storeCursorBlink(blink, x, y, color)
	return self:updateCursorBlink()
end
function Window:storeCursorBlink(blink, x, y, color)
	if blink then
		self.storedBlink = { x, y, color }
	else
		self.storedBlink = nil
	end
end
function Window:updateCursorBlink()
	if self:isForeground() then
		self:showCursorBlink()
	end
	return false
end
function Window:showCursorBlink()
	if self.storedBlink then
		return super.setCursorBlink(self, true, unpack(self.storedBlink))
	else
		return super.setCursorBlink(self, false)
	end
	return false
end
function Window:hideCursorBlink()
	if self.storedBlink and self.parent ~= nil then
		return super.setCursorBlink(self, false)
	end
	return false
end

-- Exports
return Window