--[[

	ComputerCraft GUI
	Container element

--]]

ccgui = ccgui or {}

local Container = common.newClass({
	-- Children
	children = nil,
	-- Focused child index
	childFocus = nil
}, ccgui.Element)
ccgui.Container = Container

function Container:init()
	ccgui.Element.init(self)

	self.children = {}

	-- Paint
	self:on("paint", self.drawChildren, self)
	self:sinkEvent("beforepaint")
	self:sinkEvent("afterpaint")
	self:sinkEvent("beforeframe")
	self:sinkEvent("afterframe")

	-- Mouse
	self:sinkEvent("mouse_click")
	self:sinkEvent("mouse_drag")
	self:sinkEventToCurrent("mouse_scroll")

	-- Keyboard
	self:sinkEventToCurrent("key")
	self:sinkEventToCurrent("char")
end

function Container:find(elem, deep)
	if elem == nil then return nil end

	-- Deep search in child containers
	deep = not not deep

	for i,child in ipairs(self.children) do
		if child == elem then
			return i
		elseif (deep and type(child.find) == "function") then
			if child:find(elem) ~= nil then
				return i
			end
		end
	end
	return nil
end

function Container:each(func)
	local n = #self.children
	for i,child in ipairs(self.children) do
		func(child, i, i == n)
	end
end

function Container:eachVisible(func)
	-- Check if there is another visible child
	-- after the given child index
	local hasVisibleAfter = function(i)
		for j=i+1, #self.children do
			if self.children[j].isVisible then
				return true
			end
		end
		return false
	end

	-- Process only visible children
	self:each(function(child, i)
		if child.isVisible then
			func(child, i, not hasVisibleAfter(i))
		end
	end)
end

function Container:add(...)
	local children = {...}

	-- Add as child
	for i,child in ipairs(children) do
		child.parent = self
		table.insert(self.children, child)
	end

	return #self.children
end

function Container:remove(child)
	if child.parent ~= self then
		return false
	end

	-- Remove as parent
	child.parent = nil

	-- Remove from children
	local i = common.ifind(self.children, child)
	if i ~= nil then
		table.remove(self.children, i)
		-- Fix focused child
		if self.childFocus ~= nil then
			if self.childFocus == i then
				-- Currently focused child removed
				self.childFocus = nil
				self:updateFocus(nil)
			elseif self.childFocus > i then
				-- Adjust focused child index
				self.childFocus = self.childFocus - 1
			end
		end
	end

	return true
end

function Container:drawChildren()
	-- Repaint all children
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
	return ccgui.Element.blur(self)
end

--[[

	Event sinking

]]--

function Container:sinkEvent(event)
	self:on(event, function(self, ...)
		if self.isVisible then
			local args = { ... }
			self:each(function(child)
				child:trigger(event, unpack(args))
			end)
		end
	end, self, 1000)
end

function Container:sinkEventToCurrent(event)
	self:on(event, function(self, ...)
		if self.isVisible and self.childFocus ~= nil then
			self.children[self.childFocus]:trigger(event, ...)
		end
	end, self, 1000)
end