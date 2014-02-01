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
	
	-- Program auto-start
	self.programAutoStart = opts.programAutoStart or false
	
	self:on("afterpaint", self.autoStartProgram, self)
	self:on("start", self.autoStartProgram, self)
	self:on("stop", self.terminateProgram, self)
	self:on("terminate", self.terminateProgram, self)
end

function ProgramPane:isForeground()
	if not self:isVisible() then
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
	local func, err
	if type(program) == "function" then
		func = program
	elseif type(program) == "string" then
		local path = shell.resolveProgram(program)
		assert(path, "Program not found: "..program)
		func, err = loadfile(path)
		assert(func, err)
	else
		error("Invalid program: "..tostring(program))
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
				error(output[1], 0)
			end
		end
	end
end
function ProgramPane:filterProgramEvent(eventData)
	local event = eventData[1]
	if event == "key" or event == "char" then
		-- Must have focus for keyboard event
		if self:hasFocus() then
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

function ProgramPane:handleProgramResult(thread, ok, data)
	-- Print result on program terminal
	term.redirect(self:asTerm())
	if ok then
		term.setTextColour(colours.white)
		if data and #data > 0 then
			print("Exited with:", unpack(data))
		else
			print("Exited")
		end
	else
		printError(data[1])
	end
	term.restore()
end

-- Program running
function ProgramPane:createProgramThread()
	local f = self:loadProgram(self.program)
	return Thread:new(f, function(...)
		self:handleProgramResult(...)
	end)
end
function ProgramPane:isProgramRunning()
	return self.programThread:isAlive()
end
function ProgramPane:startProgram()
	-- Schedule program thread
	if not self:isProgramRunning() then
		self.programThread:start(self:getScheduler())
	end
end
function ProgramPane:autoStartProgram()
	-- Schedule program thread
	if self.programAutoStart and not self.hasAutoStarted then
		self:startProgram()
		self.hasAutoStarted = true
	end
end
function ProgramPane:terminateProgram()
	-- Terminate if still running
	if self:isProgramRunning() then
		self.programThread:terminate()
	end
end

local ProgramWindow = Window:subclass("ccgui.ProgramWindow")
function ProgramWindow:initialize(opts)
	-- Program pane
	opts.contentPane = opts.contentPane or ProgramPane:new({
		program = opts.program,
		programAutoStart = opts.programAutoStart
	})
	
	super.initialize(self, opts)
	
	-- Terminate on close
	self:on("close", self.terminateOnClose, self)
end

function ProgramWindow:isProgramRunning()
	return self:content():isProgramRunning()
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