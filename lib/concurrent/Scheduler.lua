--[[

	Concurrency
	Thread scheduler

--]]

local Object		= require "objectlua.Object"
local Thread		= require "concurrent.Thread"

local ThreadState = Object:subclass("concurrent.ThreadState")
function ThreadState:initialize(func, co, owner)
	self.func = func
	self.co = co
	self.owner = owner or nil
	self.filter = nil
	self.result = nil
end

local Scheduler = Object:subclass("concurrent.Scheduler")
function Scheduler:initialize(errorHandler)
	super.initialize(self)
	self.errorHandler = errorHandler or Scheduler.defaultErrorHandler
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

function Scheduler:spawn(func, owner)
	local co = coroutine.create(func)
    local state = ThreadState:new(func, co, owner)
    table.insert(self.starting, state)
    return co
end

function Scheduler:handleResult(state, data)
	local ok = table.remove(data, 1)
	if ok then
		-- OK, data = yield or return value
		if coroutine.status(state.co) == Thread.DEAD then
			-- Returned, store result
			state.result = data
			return false
		else
			-- Yielded, store filter
			state.filter = (#data > 0 and data[1]) or nil
			state.started = true
			return true
		end
	else
		-- Errored, data = error
		self.errorHandler(unpack(data))
		return false
	end
end

function Scheduler:startThreads()
	while #self.starting > 0 do
		local state = table.remove(self.starting, 1)
		-- Start thread
		local data = { coroutine.resume(state.co) }
		local stillRunning = self:handleResult(state, data)
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
			local stillRunning = self:handleResult(state, data)
			if not stillRunning then
				-- Remove thread
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