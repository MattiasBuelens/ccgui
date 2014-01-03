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

	-- Radio on/off styles
	self.radioOnStyle = opts.radioOnStyle or {}
	self.radioOffStyle = opts.radioOffStyle or {}
	self:radioUpdateStyle()

	self:on("select", self.radioUpdateStyle, self)
	self:on("unselect", self.radioUpdateStyle, self)

	-- Select on click
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

function RadioButton:radioUpdateStyle()
	local style = self:isSelected() and self.radioOnStyle or self.radioOffStyle
	for k,v in pairs(style) do
		self[k] = v
	end
	self:markRepaint()
end

-- Exports
return RadioButton