--[[

	Common utilities
	Observable

--]]

common = common or {}

local Observable = common.newClass{
	events = nil
}
common.Observable = Observable

local Event = common.newClass{
	handlers = nil
}

local Handler = common.newClass{
	func = nil,
	ctxt = nil,
	prio = nil,

	-- Compare by members
	__eq = function(h1, h2)
		return h1.func == h2.func
			and h1.ctxt == h2.ctxt
			and h1.prio == h2.prio
	end
}

function Handler.compareByPriority(a, b)
	return a.prio < b.prio
end

function Observable:init()
	self.events = self.events or {}
end

function Observable:on(event, ...)
	local e = self.events[event] or Event:new()
	self.events[event] = e

	return e:add(...)
end

function Observable:off(event, ...)
	local e = self.events[event]
	return e == nil or e:remove(...)
end

function Observable:trigger(event, ...)
	local e = self.events[event]
	return e == nil or e:trigger(...)
end

function Event:init()
	self.handlers = self.handlers or {}
end

function Event:add(func, ctxt, prio)
	assert(type(func) == "function", "invalid handler")
	if type(ctxt) ~= "table" then
		ctxt = nil
	end
	if type(prio) ~= "number" then
		prio = 0
	end

	if self:find(func, ctxt, prio) ~= nil then
		return true
	end

	local handler = Handler:new{
		func = func,
		ctxt = ctxt,
		prio = prio
	}

	table.insert(self.handlers, handler)

	-- Sort by priority
	table.sort(self.handlers, Handler.compareByPriority)
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

	local i = self:find(func, ctxt, prio)

	if i == nil then
		return false
	end

	table.remove(self.handlers, i)
	return true
end

function Event:trigger(...)
	local result = nil

	for i,handler in ipairs(self.handlers) do
		if handler.ctxt == nil then
			-- Call without context
			result = handler.func(...) or result
		else
			-- Call with context
			result = handler.func(handler.ctxt, ...) or result
		end
	end

	return result
end

function Event:find(func, ctxt, prio)
	-- Handler to find
	local handler = Handler:new{
		func = func,
		ctxt = ctxt,
		prio = prio
	}

	for i,v in ipairs(self.handlers) do
		if v == handler then
			return i
		end
	end

	return nil
end