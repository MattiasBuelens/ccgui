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

function Thread:initialize(func, callback)
	super.initialize(self)
	self.func = func
	self.callback = callback or nil
	self.scheduler = nil
	self.co = nil
	self.result = nil
	self.error = nil
end

function Thread:start(scheduler)
	assert(not self:isAlive(), "thread already running")
	self.scheduler = scheduler
	self.result, self.error = nil, nil
	self.co = scheduler:spawn(self.func, function(...)
		self:handleResult(...)
	end)
end

function Thread:terminate()
	assert(self:isAlive(), "thread already terminated")
	self.scheduler:terminate(self.co)
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

function Thread:handleResult(ok, data)
	-- Store result
	if ok then
		self.result = data
	else
		self.error = data[1]
	end
	-- Clean up
	self.scheduler = nil
	-- Callback
	if self.callback then
		self.callback(self, ok, data)
	end
end

-- Exports
return Thread