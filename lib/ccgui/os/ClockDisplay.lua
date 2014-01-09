--[[

	ComputerCraft GUI OS
	Clock display

--]]

local TextElement	= require "ccgui.TextElement"

local function formatTime(nTime, bTwentyFourHour)
	local sTOD = nil
	if not bTwentyFourHour then
		if nTime >= 12 then
			sTOD = "PM"
		else
			sTOD = "AM"
		end
		if nTime >= 13 then
			nTime = nTime - 12
		end
	end

	local nHour = math.floor(nTime)
	local nMinute = math.floor((nTime - nHour)*60)
	if sTOD then
		return string.format( "%02d:%02d %s", nHour, nMinute, sTOD )
	else
		return string.format( "%02d:%02d", nHour, nMinute )
	end
end

local ClockDisplay = TextElement:subclass("ccgui.os.ClockDisplay")
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
	self:setText(formatTime(os.time(), true))
end

-- Exports
return ClockDisplay