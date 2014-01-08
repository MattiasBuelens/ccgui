--[[

	ComputerCraft GUI
	Clock display

--]]

local TextElement	= require "ccgui.TextElement"

local ClockDisplay = TextElement:subclass("ccgui.ClockDisplay")
function ClockDisplay:initialize(opts)
	super.initialize(self, opts)
	
	-- Clock update alarm
	self.clockAlarm = nil
	
	self:on("alarm", self.clockUpdateOnAlarm, self)
	
	self:updateClock()
	self:startClockAlarm()
end

function ClockDisplay:show()
	if super.show(self) then
		self:updateClock()
		self:startClockAlarm()
	end
end
function ClockDisplay:hide()
	self:stopClockAlarm()
	super.hide(self)
end

function ClockDisplay:startClockAlarm()
	if self.clockAlarm == nil then
		self:restartClockAlarm()
	end
end
function ClockDisplay:restartClockAlarm()
	self.clockAlarm = os.setAlarm(os.time() + (1 / 120))
end
function ClockDisplay:stopClockAlarm()
	self.clockAlarm = nil
end
function ClockDisplay:clockUpdateOnAlarm(alarmId)
	if alarmId == self.clockAlarm then
		self:updateClock()
		self:restartClockAlarm()
	end
end
function ClockDisplay:updateClock()
	self:setText(textutils.formatTime(os.time(), true))
end

-- Exports
return ClockDisplay