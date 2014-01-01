--[[

	ComputerCraft GUI
	Radio button

--]]

local Button		= require "ccgui.Button"
local RadioGroup	= require "ccgui.RadioGroup"

local RadioButton = Button:subclass("ccgui.RadioButton")
function RadioButton:initialize(opts)
	super.initialize(self, opts)

	-- Radio group
	self.radioGroup = opts.radioGroup
	assert(self.radioGroup ~= nil, "missing required radio group")
	self.radioGroup:add(self)

	-- Radio on/off prefixes
	self.radioOnPrefix = opts.radioOnPrefix or "[X] "
	self.radioOffPrefix = opts.radioOffPrefix or "[ ] "
	-- Radio label
	self:setLabel(opts.radioLabel or self.text)

	self:on("select", self.radioUpdateText, self)
	self:on("unselect", self.radioUpdateText, self)
	self:on("buttonpress", self.select, self)
end

function RadioButton:isSelected()
	return self.radioGroup:isSelected(self)
end

function RadioButton:select()
	self.radioGroup:select(self)
end

function RadioButton:setLabel(label)
	self.radioLabel = label or ""
	self:radioUpdateText()
end

function RadioButton:radioUpdateText()
	local text = self.radioLabel
	if self:isSelected() then
		text = self.radioOnPrefix .. text
	else
		text = self.radioOffPrefix .. text
	end
	self:setText(text)
end

-- Exports
return RadioButton