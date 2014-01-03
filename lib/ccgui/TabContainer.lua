--[[

	ComputerCraft GUI
	Tab container

--]]

local FlowContainer	= require "ccgui.FlowContainer"
local RadioButton	= require "ccgui.RadioButton"
local RadioGroup	= require "ccgui.RadioGroup"

local TabButton = RadioButton:subclass("ccgui.TabButton")
function TabButton:initialize(opts)
	-- Default style
	opts.padding = opts.padding or 1
	opts.radioOnPrefix = opts.radioOnPrefix or ""
	opts.radioOffPrefix = opts.radioOffPrefix or ""
	opts.radioOnStyle = opts.tabOnStyle or opts.radioOnStyle or {
		foreground = opts.foreground or colours.black,
		background = self.background or colours.lightGrey
	}
	opts.radioOffStyle = opts.tabOffStyle or opts.radioOffStyle or {
		foreground = opts.foreground or colours.grey,
		background = self.background or colours.lightGrey
	}

	super.initialize(self, opts)

	-- Alias tab styles
	self.tabOnStyle = self.radioOnStyle
	self.tabOffStyle = self.radioOffStyle
end

local TabContainer = FlowContainer:subclass("ccgui.TabContainer")
function TabContainer:initialize(opts)
	super.initialize(self, opts)

	-- Tab bar style
	self.tabPadding = opts.tabPadding or 0
	self.tabSpacing = opts.tabSpacing or 0
	self.tabBackground = opts.tabBackground or 0

	-- Stretch tab panes
	self.tabStretch = (opts.tabStretch == nil) or (not not opts.tabStretch)
	-- Class for tab buttons
	self.tabClass = opts.tabClass or TabButton
	-- Extra options (styling) for tab buttons
	self.tabOpts = opts.tabOpts or {}

	-- Tab radio group
	self.tabRadioGroup = RadioGroup:new()
	-- Tab bar
	self.tabBar = ccgui.FlowContainer:new{
		horizontal = not self.horizontal,
		padding = self.tabPadding,
		spacing = self.tabSpacing,
		background = self.tabBackground
	}
	-- Tab pane
	self.tabPane = ccgui.FlowContainer:new{
		horizontal = self.horizontal,
		stretch = tabStretch
	}
	self:add(self.tabBar, self.tabPane)

	-- Update visible tab when tab selection changes
	self.tabRadioGroup:on("select", self.updateVisibleTab, self)
	self.tabRadioGroup:on("unselect", self.updateVisibleTab, self)
end

function TabContainer:tabCount()
	return #self.tabPane.children
end

function TabContainer:getCurrentTab()
	local tabButton = self.tabRadioGroup:getSelected()
	return tabButton and tabButton.tab or nil
end
function TabContainer:setCurrentTab(tab)
	if tab == nil then
		self.tabRadioGroup:unselect()
	else
		self.tabRadioGroup:select(tab.tabButton)
	end
end

function TabContainer:addTab(label, tab)
	if self.tabPane:find(tab, true) ~= nil then
		-- Tab already contained
		return tab
	end
	
	-- Tab fills tab pane
	tab.stretch = true
	
	-- Add tab and tab button
	self.tabPane:add(tab)
	local tabButton = self:addButton(label)

	-- Link tab and tab button
	tab.tabButton = tabButton
	tabButton.tab = tab

	if self:getCurrentTab() == nil then
		-- Select if nothing selected yet
		self:setCurrentTab(tab)
	else
		-- Otherwise, hide tab
		tab:hide()
	end

	return tab
end
function TabContainer:addButton(label)
	local opts = {
		text = label,
		radioGroup = self.tabRadioGroup
	}
	for k,v in pairs(self.tabOpts) do
		opts[k] = v
	end
	local tabButton = self.tabClass:new(opts)
	self.tabBar:add(tabButton)
	return tabButton
end

function TabContainer:removeTab(tab)
	assert(tab ~= nil, "tab cannot be nil")

	if tab == self:getCurrentTab() then
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
			self:setCurrentTab(nil)
		end
	end

	-- Remove tab and tab button
	self.tabPane:remove(tab)
	self.tabBar:remove(tab.tabButton)
	self.tabRadioGroup:remove(tab.tabButton)

	self:updateVisibleTab()
end

function TabContainer:updateVisibleTab()
	-- Show current tab and hide others
	local currentTab = self:getCurrentTab()
	self.tabPane:each(function(child)
		if child == currentTab then
			child:show()
		else
			child:hide()
		end
	end)
end

-- Exports 
return TabContainer