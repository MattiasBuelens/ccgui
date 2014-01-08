--[[

	ComputerCraft GUI
	Program window

--]]

local Element			= require "ccgui.Element"
local Window			= require "ccgui.Window"
local Thread			= require "concurrent.Thread"
local TerminalElement	= require "ccgui.TerminalElement"
local TerminalFunctions	= require "ccgui.TerminalFunctions"

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

-- Install the rest of the OS api
local function runProgram(env, path)
    local fnFile, err = loadfile( sPath )
    if fnFile then
        local tEnv = _tEnv
        setfenv( fnFile, tEnv )
        local ok, err = pcall( function()
        	fnFile( unpack( tArgs ) )
        end )
        if not ok then
        	if err and err ~= "" then
	        	printError( err )
	        end
        	return false
        end
        return true
    end
    if err and err ~= "" then
		printError( err )
	end
    return false
end

function ProgramPane:loadProgram(program)
	local _term = self:asTerm()

	return function()
		local program = program
		-- Create new environment
		local env = TerminalFunctions:new(_term, _G).env
		env.shell = nil
		-- Setup environment
		setfenv(1, env)
		term.clear()
		-- Load program
		local func = nil
		if type(program) == "function" then
			func = program
		elseif type(program) == "string" then
			func, err = loadfile(program)
			if not func then error(err) end
		end
		setfenv(func, env)
		func()
	end
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