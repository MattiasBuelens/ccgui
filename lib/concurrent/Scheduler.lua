--[[

	Concurrency
	Thread scheduler

--]]

local Object		= require "objectlua.Object"
local Thread		= require "concurrent.Thread"

local ThreadState = Object:subclass("concurrent.ThreadState")
function ThreadState:initialize(func, co, callback)
	self.func = func
	self.co = co
	self.callback = callback or nil
	self.filter = nil
end

local Scheduler = Object:subclass("concurrent.Scheduler")
function Scheduler:initialize(errorHandler)
	super.initialize(self)
	self.errorHandler = errorHandler or Scheduler.defaultErrorHandler
	self.stateByCo = {}
	self.starting = {}
	self.running = {}
end

function Scheduler.class.defaultErrorHandler(err)
	if term.isColor() then
		term.setTextColor(colours.red)
	end
	print(err)
	term.setTextColor(colours.white)
end

function Scheduler:threadCount()
	return #self.starting + #self.running
end

function Scheduler:spawn(func, callback)
	local co = coroutine.create(func)
	local state = ThreadState:new(func, co, callback)
	self.stateByCo[co] = state
	table.insert(self.starting, state)
	return co
end

function Scheduler:terminate(co)
	local state = self.stateByCo[co]
	assert(state ~= nil, "cannot find thread to terminate")
	local err = "Terminated"
	if state.started and coroutine.status(state.co) ~= Thread.DEAD then
		-- Already started, terminate
		local ok, param = coroutine.resume(state.co, "terminate")
		if not ok then
			err = param
		end
	end
	-- Remove
	self:remove(state)
	self:finishThread(state, false, { err })
end

function Scheduler:remove(state)
	local t = state.started and self.running or self.starting
	for i=1,#t do
		if t[i] == state then
			table.remove(t, i)
			return true
		end
	end
	self.stateByCo[state.co] = nil
	return false
end

function Scheduler:handleResume(state, data)
	local ok = table.remove(data, 1)
	if ok then
		-- OK, data = yield or return value
		if coroutine.status(state.co) == Thread.DEAD then
			-- Returned
			self:finishThread(state, ok, data)
			return false
		else
			-- Yielded, store filter
			state.filter = (#data > 0 and data[1]) or nil
			state.started = true
			return true
		end
	else
		-- Errored, data = error
		self:finishThread(state, ok, data)
		return false
	end
end

function Scheduler:finishThread(state, ok, data)
	-- Handle errors
	if not ok and self.errorHandler then
		self.errorHandler(unpack(data))
	end
	-- Callback
	if state.callback then
		state.callback(ok, data)
	end
	-- Remove
	self.stateByCo[state.co] = nil
end

function Scheduler:startThreads()
	while #self.starting > 0 do
		local state = table.remove(self.starting, 1)
		-- Start thread
		local data = { coroutine.resume(state.co) }
		local stillRunning = self:handleResume(state, data)
		if stillRunning then
			-- Add to running
			table.insert(self.running, state)
		end
	end
end

function Scheduler:resumeThreads(event, ...)
	local i = 1
	while i <= #self.running do
		local state = self.running[i]
		-- Resume thread
		if state.filter == nil or state.filter == event or event == "terminate" then
			local data = { coroutine.resume(state.co, event, ...) }
			local stillRunning = self:handleResume(state, data)
			if not stillRunning then
				-- Remove from running
				table.remove(self.running, i)
				i = i - 1
			end
		end
		i = i + 1
	end
end

function Scheduler:run()
	while self:threadCount() > 0 do
		-- Start threads
		self:startThreads()
		-- Pull event
		local eventData = { coroutine.yield() }
		-- Start threads again (if new threads were added)
		self:startThreads()
		-- Resume threads
		self:resumeThreads(unpack(eventData))
		-- Terminate
		if eventData[1] == "terminate" then
			error("Terminated", 0)
		end
	end
end

-- Exports
return Scheduler