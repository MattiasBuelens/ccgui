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
	if button == 1 and self:visible() and self:canDrag() and self.titleText:contains(x, y) then
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
	if button == 1 and self:visible() and self:canDrag() and self.dragStartPos ~= nil then
		-- Get drag delta
		local current = vector.new(x, y)
		local delta = current - self.dragStartPos
		-- Set window position
		self.parent:setPosition(self.dragStartValue + delta)
	end
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
	self.contentPane = FlowContainer:new(opts)
	-- TODO Status bar, resize handle?

	self:add(self.titleBar, self.contentPane)

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

function Window:maximize()
	if not self.isMaximized then
		self.isMaximized = true
		self:bringToForeground()
		self:trigger("maximize")
	end
end
function Window:restoreSize()
	if self.isMaximized then
		self.isMaximized = false
		self:bringToForeground()
		self:trigger("restore")
	end
end
function Window:isForeground()
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
function Window:calcSize(size)
	if not self.isMaximized then
		size = Rectangle:new(self.windowBox)
	end
	super.calcSize(self, size)
end
function Window:calcLayout(bbox)
	if not self.isMaximized then
		bbox = self.windowBox:shift(bbox:tl())
	end
	super.calcLayout(self, bbox)
end

-- Bring to foreground on click
function Window:foregroundOnClick(button, x, y)
	if button == 1 and self:visible() and self:contains(x, y) then
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
		if self.storedBlink then
			return self:showCursorBlink()
		else
			return self:hideCursorBlink()
		end
	end
	return false
end
function Window:showCursorBlink()
	if self.storedBlink and self.parent ~= nil then
		local x, y, color = unpack(self.storedBlink)
		return super.setCursorBlink(self, true, x, y, color)
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