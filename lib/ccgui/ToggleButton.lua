--[[

	ComputerCraft GUI
	Toggle button

--]]

local Element	= require "ccgui.Element"
local Button	= require "ccgui.Button"

local ToggleButton = Button:subclass("ccgui.ToggleButton")
function ToggleButton:initialize(opts)
	super.initialize(self, opts)

	-- Button label
	self.labelOn = opts.labelOn or "On"
	self.labelOff = opts.labelOff or "Off"

	-- Button state
	self.toggleState = false
	self:updateLabel()

	self:on("buttonpress", self.toggle, self)
end

function ToggleButton:isOn()
	return self.toggleState
end

function ToggleButton:isOff()
	return not self:isOn()
end

function ToggleButton:setState(state)
	if self.toggleState ~= state then
		self.toggleState = not not state
		if self.toggleState then
			self:trigger("toggleon")
		else
			self:trigger("toggleoff")
		end
		self:updateLabel()
	end
end

function ToggleButton:toggle()
	self:setState(self:isOff())
end

function ToggleButton:setOnLabel(labelOn)
	self.labelOn = labelOn or ""
	self:updateLabel()
end

function ToggleButton:setOffLabel(labelOff)
	self.labelOff = labelOff or ""
	self:updateLabel()
end

function ToggleButton:updateLabel()
	if self:isOn() then
		self:setText(self.labelOn)
	else
		self:setText(self.labelOff)
	end
end

-- Exports
return ToggleButton