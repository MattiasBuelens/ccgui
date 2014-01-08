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

function ProgramPane:createProgramThread()
	local f = self:loadProgram(self.program)
	return Thread:new(f)
end

function ProgramPane:redirectTerm(func, out)
	return function(...)
		local co = coroutine.create(func)
		local input = { ... }
		while true do
			term.redirect(out)
			local output = { coroutine.resume(co, unpack(input)) }
			term.restore()
			local ok = table.remove(output, 1)
			if ok then
				if coroutine.status(co) == "dead" then
					-- Returned
					return unpack(output)
				else
					-- Yielded
					input = { coroutine.yield(unpack(output)) }
				end
			else
				-- Error
				error(unpack(output))
			end
		end
	end
end

function ProgramPane:loadProgram(program)
	-- Load program
	local func = nil
	if type(program) == "function" then
		func = program
	elseif type(program) == "string" then
		func, err = loadfile(program)
		if not func then error(err) end
	end
	
	-- Redirect terminal
	local programTerm = self:asTerm()
	local redirected = self:redirectTerm(function()
		term.clear()
		term.setCursorPos(1, 1)
		term.setCursorBlink(true)
		func()
	end, programTerm)

	return redirected
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