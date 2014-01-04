--[[

	ComputerCraft GUI
	Container element

--]]

local Element		= require "ccgui.Element"

local Container = Element:subclass("ccgui.Container")
function Container:initialize(opts)
	super.initialize(self, opts)

	-- Children
	self.children = {}
	self.childFocus = nil
	
	-- Sunk events
	self.sunkEvents = {}
	self.sunkFocusEvents = {}

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
		if child.isVisible then
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

function Container:remove(child)
	if child.parent ~= self then
		return false
	end
	self:trigger("beforeremove", child)

	-- Remove from children
	local i = self:find(child, false)
	if i ~= nil then
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
		table.remove(self.children, i)
	end

	-- Remove as parent
	child.parent = nil

	self:trigger("remove", child)
	return true
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

function Container:drawChildren()
	-- Paint visible children
	self:eachVisible(function(child)
		child:paint()
	end)
end

--[[

	Focus

]]

function Container:updateFocus(newFocus)
	local newIndex = self:find(newFocus)

	-- Blur previously focused child
	if self.childFocus ~= nil and self.childFocus ~= newIndex then
		self.children[self.childFocus]:blur()
	end

	-- Set focused child
	self.childFocus = newIndex

	-- Bubble up to parent
	if self.parent ~= nil then
		if newFocus == nil then
			self.parent:updateFocus(nil)
		else
			self.parent:updateFocus(self)
		end
	end
end

function Container:blur()
	-- Blur previously focused child
	if self.childFocus ~= nil then
		self.children[self.childFocus]:blur()
		self.childFocus = nil
	end

	-- Call super
	return super.blur(self)
end

--[[

	Event sinking

]]--

function Container:sinkEvent(event)
	if self.sunkEvents[event] then return end
	local handler = function(self, ...)
		if self:visible() then
			local args = { ... }
			self:each(function(child)
				child:trigger(event, unpack(args))
			end)
		end
	end
	self.sunkEvents[event] = handler
	self:on(event, handler, self, 1000)
end

function Container:unsinkEvent(event)
	if not self.sunkEvents[event] then return end
	self:off(event, self.sunkEvents[event], self, 1000)
	self.sunkEvents[event] = nil
end

function Container:sinkFocusEvent(event)
	if self.sunkFocusEvents[event] then return end
	local handler = function(self, ...)
		if self:visible() and self.childFocus ~= nil then
			self.children[self.childFocus]:trigger(event, ...)
		end
	end
	self.sunkFocusEvents[event] = handler
	self:on(event, handler, self, 1000)
end

function Container:unsinkFocusEvent(event)
	if not self.sunkFocusEvents[event] then return end
	self:off(event, self.sunkFocusEvents[event], self, 1000)
	self.sunkFocusEvents[event] = nil
end

-- Exports
return Container