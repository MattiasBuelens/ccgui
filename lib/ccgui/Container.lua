--[[

	ComputerCraft GUI
	Container element

--]]

local Element		= require "ccgui.Element"
local stablesort	= require "common.stablesort"

local Container = Element:subclass("ccgui.Container")
function Container:initialize(opts)
	super.initialize(self, opts)

	-- Children
	self.children = {}
	self.childFocus = nil

	-- General
	self:sinkEvent("start")
	self:sinkEvent("stop")
	self:sinkEvent("timer")
	self:sinkEvent("alarm")
	self:sinkEvent("terminate")

	-- Paint
	self:on("paint", self.drawChildren, self)
	self:sinkEvent("beforepaint")
	self:sinkEvent("afterpaint")

	-- Mouse
	self:sinkEvent("mouse_click")
	self:sinkEvent("mouse_drag")
	self:sinkFocusEvent("mouse_scroll")

	-- Keyboard
	self:sinkFocusEvent("key")
	self:sinkFocusEvent("char")
end

function Container:find(elem, deep)
	if elem == nil then return nil end

	-- Deep search in child containers
	deep = not not deep

	for i,child in ipairs(self.children) do
		if child == elem then
			return i
		elseif (deep and type(child.find) == "function") then
			if child:find(elem, deep) ~= nil then
				return i
			end
		end
	end
	return nil
end

function Container:visibleChildren()
	local t = {}
	for i,child in ipairs(self.children) do
		if child.visible then
			table.insert(t, child)
		end
	end
	return t
end

local function forEach(t, f)
	local n = #t
	for i,x in ipairs(t) do
		f(x, i, n)
	end
end

function Container:each(func)
	return forEach(self.children, func)
end

function Container:eachVisible(func)
	return forEach(self:visibleChildren(), func)
end

function Container:add(...)
	local children = {...}

	-- Add as child
	for i,child in ipairs(children) do
		child.parent = self
		table.insert(self.children, child)
		self:trigger("add", child)
	end

	return #self.children
end

function Container:move(child, newIndex)
	local i = self:find(child, false)
	assert(i ~= nil, "cannot move non-child element")
	if i == newIndex then return end

	-- Reinsert
	table.remove(self.children, i)
	table.insert(self.children, newIndex, child)

	-- Fix focused child
	if self.childFocus ~= nil then
		if self.childFocus == i then
			self.childFocus = newIndex
		elseif i < self.childFocus and self.childFocus <= newIndex then
			self.childFocus = self.childFocus - 1
		end
	end
end

function Container:removeByIndex(i)
	local child = self.children[i]
	if child == nil or child.parent ~= self then
		return false
	end
	self:trigger("beforeremove", child)

	-- Fix focused child
	if self.childFocus ~= nil then
		if self.childFocus == i then
			-- Currently focused child removed
			self:updateFocus(nil)
		elseif self.childFocus > i then
			-- Adjust focused child index
			self.childFocus = self.childFocus - 1
		end
	end

	-- Remove as parent
	child.parent = nil
	table.remove(self.children, i)

	self:trigger("remove", child)
	return true
end

function Container:remove(child)
	if child.parent ~= self then
		return false
	end

	local i = self:find(child, false)
	if i == nil then return false end

	return self:removeByIndex(i)
end

function Container:removeAll()
	self:trigger("beforeremoveall")
	while #self.children > 0 do
		self:removeByIndex(1)
	end
	self:trigger("removeall")
end

function Container:markRepaint()
	if not self.needsRepaint then
		super.markRepaint(self)
		-- Repaint all visible children
		self:eachVisible(function(child)
			child:markRepaint()
		end)
	end
end

local function compareZIndex(a, b)
	return a.zIndex < b.zIndex
end
function Container:drawChildren(ctxt)
	-- Copy visible children
	local t = {}
	for _,child in ipairs(self.children) do
		if child.visible then
			table.insert(t, child)
		end
	end
	-- Sort by Z-index
	stablesort(t, compareZIndex)
	-- Paint children
	for _,child in ipairs(t) do
		child:paint(ctxt)
	end
end

--[[

	Focus

]]

function Container:focusedChild()
	return self.childFocus and self.children[self.childFocus] or nil
end

function Container:checkFocused(elem)
	if self.visible and self.childFocus ~= nil then
		-- Check focused child
		if elem == nil then
			return true
		else
			return self:checkChildFocused(elem)
		end
	end
	return super.checkFocused(self, elem)
end

function Container:checkChildFocused(child)
	-- Must be focused child
	return self:focusedChild() == child
end

function Container:updateFocus(newFocus)
	local newIndex = self:find(newFocus)

	-- Blur previously focused child
	if self.childFocus ~= nil and self.childFocus ~= newIndex then
		self:focusedChild():blur()
	end

	-- Set focused child
	self.childFocus = newIndex

	-- Bubble up to parent
	if self.parent ~= nil then
		self.parent:updateFocus(newFocus and self or nil)
	end
end

function Container:blur()
	-- Blur previously focused child
	if self.childFocus ~= nil then
		self:focusedChild():blur()
		self.childFocus = nil
	end

	-- Call super
	return super.blur(self)
end

--[[

	Event sinking

]]--

function Container:handleSink(event, ...)
	if self:isVisible() then
		local args = { ... }
		self:each(function(child)
			child:trigger(event, unpack(args))
		end)
	end
end
function Container:sinkEvent(event)
	self:on(event, function(self, ...)
		self:handleSink(event, ...)
	end, self, 1000)
end

function Container:handleFocusSink(event, ...)
	local child = self:focusedChild()
	if child and child:hasFocus() then
		child:trigger(event, ...)
	end
end
function Container:sinkFocusEvent(event)
	self:on(event, function(self, ...)
		self:handleFocusSink(event, ...)
	end, self, 1000)
end

-- Exports
return Container