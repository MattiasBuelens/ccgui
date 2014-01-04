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

	-- Paint
	self:on("paint", self.drawChildren, self)
	self:sinkEvent("beforepaint")
	self:sinkEvent("afterpaint")

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
	self:on(event, function(self, ...)
		if self:visible() then
			local args = { ... }
			self:each(function(child)
				child:trigger(event, unpack(args))
			end)
		end
	end, self, 1000)
end

function Container:sinkEventToCurrent(event)
	self:on(event, function(self, ...)
		if self:visible() and self.childFocus ~= nil then
			self.children[self.childFocus]:trigger(event, ...)
		end
	end, self, 1000)
end

-- Exports
return Container