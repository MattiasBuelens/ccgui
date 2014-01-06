--[[

	Concurrency
	Thread

--]]

local Object		= require "objectlua.Object"

local Thread = Object:subclass("concurrent.Thread")

-- Thread state
Thread.class.SUSPENDED = "suspended"
Thread.class.RUNNING = "running"
Thread.class.NORMAL = "normal"
Thread.class.DEAD = "dead"

function Thread:initialize(func)
	super.initialize(self)
	self.func = func
	self.co = nil
end

function Thread:start(scheduler)
	assert(not self:isAlive(), "thread already running")
	self.co = scheduler:spawn(self.func, self)
end

function Thread.class:sleep(nTime)
    local timer = os.startTimer(nTime or 0)
	repeat
		local sEvent, param = os.pullEvent("timer")
	until param == timer
end

function Thread:join()
    while self:isAlive() do
        Thread:sleep()
    end
end

function Thread:status()
	if self.co == nil then
		return Thread.SUSPENDED
	else
		return coroutine.status(self.co)
	end
end

function Thread:isAlive()
    return self:status() ~= Thread.DEAD
end

-- Exports
return Thread