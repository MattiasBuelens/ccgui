--[[

	Event emitter

--]]

local Object = require "objectlua.Object"

local EventEmitter = Object:subclass("event.EventEmitter")
local Event = Object:subclass("event.Event")
local EventHandler = Object:subclass("event.EventHandler")

local stablesort = require "common.stablesort"

function EventEmitter:initialize()
	self:offAll()
end
function EventEmitter:on(event, ...)
	local e = self.events[event] or Event:new()
	self.events[event] = e
	return e:add(...)
end
function EventEmitter:off(event, ...)
	local e = self.events[event]
	return e == nil or e:remove(...)
end
function EventEmitter:trigger(event, ...)
	local e = self.events[event]
	return e == nil or e:trigger(...)
end
function EventEmitter:offAll()
	self.events = {}
end


function Event:initialize()
	self.handlers = {}
end
function Event:add(func, ctxt, prio)
	assert(type(func) == "function", "invalid handler")
	if type(ctxt) ~= "table" then
		ctxt = nil
	end
	if type(prio) ~= "number" then
		prio = 0
	end

	local handler = EventHandler:new{
		func = func,
		ctxt = ctxt,
		prio = prio
	}
	if self:find(handler) ~= nil then
		-- Handler already registered
		return false
	end
	table.insert(self.handlers, handler)

	-- Sort by priority
	stablesort(self.handlers, EventHandler.compareByPriority)
	return true
end
function Event:remove(func, ctxt, prio)
	assert(type(func) == "function", "invalid handler")
	if type(ctxt) ~= "table" then
		ctxt = nil
	end
	if type(prio) ~= "number" then
		prio = 0
	end

	local i = self:find(EventHandler:new{
		func = func,
		ctxt = ctxt,
		prio = prio
	})
	if i == nil then
		-- Nothing to remove
		return false
	else
		-- Remove
		table.remove(self.handlers, i)
		return true
	end
end
function Event:trigger(...)
	local result = nil

	for i,handler in ipairs(self.handlers) do
		if handler.ctxt == nil then
			-- Call without context
			result = handler.func(...)
		else
			-- Call with context
			result = handler.func(handler.ctxt, ...)
		end
	end

	return result
end
function Event:find(handler)
	for i,v in ipairs(self.handlers) do
		if handler:equals(v) then
			return i
		end
	end
	return nil
end


function EventHandler:initialize(options)
	self.func = options.func or nil
	self.ctxt = options.ctxt or nil
	self.prio = options.prio or nil
end
function EventHandler:equals(other)
	-- Compare by members
	return self.func == other.func
		and self.ctxt == other.ctxt
		and self.prio == other.prio
end
function EventHandler.class.compareByPriority(h1, h2)
	return h1.prio < h2.prio
end

-- Exports
return EventEmitter