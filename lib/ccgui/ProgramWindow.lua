--[[

	ComputerCraft GUI
	Program window

--]]

local Element			= require "ccgui.Element"
local Window			= require "ccgui.Window"
local Thread			= require "concurrent.Thread"
local TerminalElement	= require "ccgui.TerminalElement"

local ProgramPane = TerminalElement:subclass("ccgui.ProgramPane")
function ProgramPane:initialize(opts)
	super.initialize(self, opts)
	
	-- Program
	self.program = opts.program or (function() end)
	
	-- Program thread
	self.programThread = self:createProgramThread()
	
	self:on("beforepaint", self.startProgram, self)
	self:on("terminate", self.terminateProgram, self)
end

function ProgramPane:isForeground()
	if not self:visible() then
		return false
	end
	if self.parent ~= nil then
		return self.parent:isForeground()
	end
	return false
end

-- Program loading
function ProgramPane:loadProgram(program)
	-- Load program
	local func = nil
	if type(program) == "function" then
		func = program
	elseif type(program) == "string" then
		func, err = loadfile(program)
		if not func then error(err) end
	end
	
	-- Wrap program
	return self:wrapProgram(function()
		term.clear()
		term.setCursorPos(1, 1)
		term.setCursorBlink(true)
		func()
	end)
end
function ProgramPane:wrapProgram(func)
	-- Terminal
	local redirectTerm = self:asTerm()

	return function(...)
		local co = coroutine.create(func)
		local input = { ... }
		while true do
			-- Redirect terminal
			term.redirect(redirectTerm)
			-- Resume program
			local output = { coroutine.resume(co, unpack(input)) }
			-- Restore terminal
			term.restore()
			-- Handle result
			local ok = table.remove(output, 1)
			if ok then
				if coroutine.status(co) == "dead" then
					-- Returned
					return unpack(output)
				else
					-- Yielded
					repeat
						input = { coroutine.yield(unpack(output)) }
						input = self:filterProgramEvent(input)
					until (input ~= nil)
				end
			else
				-- Error
				error(unpack(output))
			end
		end
	end
end
function ProgramPane:filterProgramEvent(eventData)
	local event = eventData[1]
	if event == "key" or event == "char" then
		-- Must have focus for keyboard event
		if self:isForeground() and self.hasFocus then
			return eventData
		else
			return nil
		end
	elseif event == "mouse_click" or event == "mouse_drag" or event == "mouse_scroll" then
		-- Must contain mouse position
		local x, y = eventData[3], eventData[4]
		if self:isForeground() and self:contains(x, y) then
			-- Translate to local coordinates
			local bbox = self:inner(self.bbox)
			eventData[3] = x - bbox.x + 1
			eventData[4] = y - bbox.y + 1
			return eventData
		else
			return nil
		end
	else
		return eventData
	end
end

-- Program running
function ProgramPane:createProgramThread()
	local f = self:loadProgram(self.program)
	return Thread:new(f)
end
function ProgramPane:startProgram()
	if not self.hasProgramStarted then
		-- Schedule program thread
		self.programThread:start(self:getScheduler())
		self.hasProgramStarted = true
	end
end
function ProgramPane:terminateProgram()
	-- Terminate if still running
	if self.programThread:isAlive() then
		self.programThread:terminate()
	end
end

local ProgramWindow = Window:subclass("ccgui.ProgramWindow")
function ProgramWindow:initialize(opts)
	-- Program pane
	opts.contentPane = opts.contentPane or ProgramPane:new({
		func = opts.func,
		program = opts.program
	})
	
	super.initialize(self, opts)
	
	-- Terminate on close
	self:on("close", self.terminateOnClose, self)
end

function ProgramWindow:startProgram()
	self:content():startProgram()
end
function ProgramWindow:terminateProgram()
	self:content():terminateProgram()
end

function ProgramWindow:terminateOnClose()
	self:terminateProgram()
end

-- Exports
return ProgramWindow