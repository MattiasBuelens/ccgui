--[[

	ComputerCraft GUI
	Tab container

--]]

local FlowContainer	= require "ccgui.FlowContainer"

local TabContainer = FlowContainer.subclass("ccgui.TabContainer")
function TabContainer:initialize(opts)
	super.initialize(self, opts)

	-- Spacing between tab buttons
	self.tabSpacing = opts.tabSpacing or 0
	-- Stretch tab panes
	self.tabStretch = (type(opts.tabStretch) == "nil") or (not not opts.tabStretch)
	-- Style for tab buttons
	self.tabStyle = opts.tabStyle or ccgui.Button

	-- Current tab
	self.currentTab = nil
	-- Tab bar
	self.tabBar = ccgui.FlowContainer:new{
		horizontal = not self.horizontal,
		spacing = self.tabSpacing
	}
	-- Tab pane
	self.tabPane = ccgui.FlowContainer:new{
		horizontal = not self.horizontal,
		stretch = tabStretch
	}
	self:add(self.tabBar, self.tabPane)

	self:on("beforepaint", self.updateVisibleTab, self)
end

function TabContainer:tabCount()
	return #self.tabPane.children
end

function TabContainer:addTab(label, tab)
	if self.tabPane:find(tab, true) ~= nil then
		-- Tab already contained
		return tab
	end
	
	-- Add tab pane
	self.tabPane:add(tab)

	-- Add tab button
	local tabButton = self:addButton(label)

	-- Link button and pane
	tab.tabButton = tabButton
	tabButton.tab = tab

	-- Bind button to pane
	local container = self
	tabButton:on("buttonpress", function(self)
		container:setCurrentTab(self.tab)
	end, tabButton)

	self:updateVisibleTab()

	return tab
end

function TabContainer:addButton(label)
	local tabButton = self.tabStyle:new{
		text = label
	}
	self.tabBar:add(tabButton)
	return tabButton
end

function TabContainer:setCurrentTab(tab)
	if type(tab) ~= "table" then return false end

	-- Set as current tab
	self.currentTab = tab

	self:updateVisibleTab()
	--self.tabPane:markRepaint()
	return true
end

function TabContainer:removeTab(tab)
	if self.currentTab == tab then
		-- Current tab removed
		local i, n = self.tabPane:find(tab), self:tabCount()
		if n > 1 then
			-- Move to neighbour tab
			if i == n then
				i = i-1
			else
				i = i+1
			end
			self:setCurrentTab(self.tabPane.children[i])
		else
			-- No new current tab
			self.currentTab = nil
		end
	end

	-- Remove tab
	self.tabPane:remove(tab)

	-- Remove tab button
	self.tabBar:remove(tab.tabButton)

	self:updateVisibleTab()
end

function TabContainer:updateVisibleTab()
	if self.currentTab == nil and self:tabCount() > 0 then
		self.currentTab = self.tabPane.children[1]
	end

	-- Show current tab and hide others
	self.tabPane:each(function(child)
		if child == self.currentTab then
			child:show()
		else
			child:hide()
		end
	end)
end

function TabContainer:sinkEventToCurrent(event)
	self:on(event, function(...)
		if self.isVisible and self.currentTab ~= nil then
			self.currentTab:trigger(event, ...)
		end
	end, self)
end

-- Exports 
return TabContainer