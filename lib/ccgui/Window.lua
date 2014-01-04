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
	self.windowBox = opts.windowBox or Rectangle:new(0, 0, 15, 10)

	-- Title bar
	self.titleBar = TitleBar:new{
		foreground = opts.titleForeground or colours.white,
		background = opts.titleBackground or colours.blue,
		maximizable = opts.maximizable,
		closable = opts.closable
	}
	self:setTitle(opts.title or "")

	-- Content pane
	self.contentPane = FlowContainer:new(opts)
	-- TODO Status bar, resize handle?

	self:add(self.titleBar, self.contentPane)

	self:on("maximize", self.titleBar.updateMaximized, self.titleBar)
	self:on("restore", self.titleBar.updateMaximized, self.titleBar)
	self:on("mouse_click", self.windowClick, self)
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
		self:bringToFront()
		self:trigger("maximize")
	end
end
function Window:restoreSize()
	if self.isMaximized then
		self.isMaximized = false
		self:bringToFront()
		self:trigger("restore")
	end
end
function Window:bringToFront()
	self.parent:bringToFront(self)
end
function Window:close()
	self:trigger("close")
	self.parent:remove(self)
end

function Window:getPosition(pos)
	return self.windowBox:tl()
end
function Window:setPosition(pos)
	assert(not self.isMaximized, "cannot set position when maximized")
	if self.windowBox.x ~= pos.x or self.windowBox.y ~= pos.y then
		self.windowBox.x, self.windowBox.y = pos.x, pos.y
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

function Window:windowClick(button, x, y)
	if button == 1 and self:visible() and self:contains(x, y) then
		self:bringToFront()
	end
end

-- Exports
return Window