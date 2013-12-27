--[[

	Event loop

--]]

local Object		= require "objectlua.Object"
local EventEmitter	= require "event.EventEmitter"

local EventLoop = EventEmitter:subclass("event.EventLoop")
EventLoop:has("running", {
	is = "rb"
})

function EventLoop:initialize()
	super.initialize(self)
	-- Clean up on terminate
	self:on("terminate", self.stop, self)
end
function EventLoop:run()
	-- Start
	self:start()
	-- Run event loop, catch errors
	local ok, err = pcall(function()
		while self:isRunning() do
			self:process()
		end
	end)
	-- Clean stop
	self:stop()
	-- Re-throw error
	if not ok then
		printError(err)
	end
end
function EventLoop:process()
	-- Process event
	self:trigger(os.pullEventRaw())
end
function EventLoop:start()
	if self:isRunning() then return false end
	self.running = true
	return true
end
function EventLoop:stop()
	if not self:isRunning() then return false end
	self.running = false
	-- Unregister all event handlers
	-- Necessary since this instance may be reused later
	self:offAll()
	return true
end

-- Exports
return EventLoop:new()