--[[

	ComputerCraft GUI
	Radio group

--]]

local EventEmitter	= require "event.EventEmitter"

local RadioGroup = EventEmitter:subclass("ccgui.RadioGroup")
function RadioGroup:initialize()
	super.initialize(self)
	
	-- Hash table of radios
	self.radios = {}
	-- Selected radio
	self.selected = nil
end

function RadioGroup:add(radio)
	self.radios[radio] = true
end

function RadioGroup:remove(radio)
	if radio == nil then return end
	self.radios[radio] = nil
	if self.selected == radio then
		self:unselect()
	end
end

function RadioGroup:getSelected()
	return self.selected
end
function RadioGroup:hasSelected()
	return self:getSelected() ~= nil
end
function RadioGroup:isSelected(radio)
	return self.selected == radio
end

function RadioGroup:select(radio)
	local oldRadio = self.selected
	if radio ~= oldRadio then
		assert(self.radios[radio] ~= nil, "selected radio must be inside radio group")
		self.selected = radio
		self:trigger("select", radio)
		if oldRadio ~= nil then
			oldRadio:trigger("unselect")
		end
		radio:trigger("select")
	end
end

function RadioGroup:unselect()
	local radio = self.selected
	if radio ~= nil then
		self.selected = nil
		self:trigger("unselect", radio)
		radio:trigger("unselect")
	end
end

-- Exports
return RadioGroup