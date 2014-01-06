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
	self.result = nil
	self.error = nil
end

function Thread:start(scheduler)
	assert(not self:isAlive(), "thread already running")
	self.result, self.error = nil, nil
	self.co = scheduler:spawn(self.func, function(...)
		self:callback(...)
	end)
end

function Thread.class:sleep(nTime)
    local timer = os.startTimer(nTime or 0)
	repeat
		local sEvent, param = os.pullEvent("timer")
	until param == timer
end

function Thread:join()
	assert(self.co ~= coroutine.running(), "cannot join with running thread")
    while self:isAlive() do
        Thread:sleep()
    end
	if self.error then
		error(self.error)
	end
	return unpack(self.result)
end

function Thread:status()
	if self.co == nil then
		return Thread.DEAD
	else
		return coroutine.status(self.co)
	end
end
function Thread:isAlive()
    return self:status() ~= Thread.DEAD
end

function Thread:callback(ok, data)
	if ok then
		self.result = data
	else
		self.error = data[1]
	end
end

-- Exports
return Thread