--[[

	ComputerCraft GUI
	Toggle button

--]]

ccgui = ccgui or {}

local ToggleButton = common.newClass({
	-- Button state
	toggleState = false,
	-- Button label
	labelOn = "On",
	labelOff = "Off"
}, ccgui.Button)
ccgui.ToggleButton = ToggleButton

function ToggleButton:init()
	ccgui.Button.init(self)

	self:updateLabel()

	self:on("buttonpress", self.togglePress, self)
end

function ToggleButton:isOn()
	return self.toggleState
end

function ToggleButton:isOff()
	return not self:isOn()
end

function ToggleButton:setState(state)
	self.toggleState = not not state
	self:updateLabel()
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

function ToggleButton:togglePress()
	self:toggle()
	if self:isOn() then
		self:trigger("toggleon")
	else
		self:trigger("toggleoff")
	end
end