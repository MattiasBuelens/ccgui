--[[

	ComputerCraft GUI
	Program window

--]]

local Element			= require "ccgui.Element"
local Window			= require "ccgui.Window"
local Thread			= require "concurrent.Thread"
local ElementTerminal	= require "ccgui.paint.ElementTerminal"

local ProgramPane = Element:subclass("ccgui.ProgramPane")
function ProgramPane:initialize(opts)
	super.initialize(self, opts)
	
	-- Terminal
	self.term = ElementTerminal:new(self)
	
	-- Program
	if type(opts.func) == "function" then
		self.func = opts.func
	elseif type(opts.program) == "string" then
		self.func, err = loadfile(opts.program)
		if err then error(err) end
	end
	
	-- Program thread
	self.programThread = self:createProgramThread()
	
	self:on("beforepaint", self.programResize, self)
	self:on("paint", self.programPaint, self)
	self:on("terminate", self.terminateProgram, self)
end

function ProgramPane:createProgramThread()
	local term = self.term:export()
	local f = self.func
	local env = {
		["term"] = term,
		["shell"] = false
	}
	setmetatable(env, { __index = getfenv(f) })
	env._G = env
	setfenv(f, env)
	return Thread:new(f)
end
function ProgramPane:startProgram()
	-- Schedule program thread
	self.programThread:start(self:getScheduler())
end
function ProgramPane:terminateProgram()
	-- Terminate if still running
	if self.programThread:isAlive() then
		self.programThread:terminate()
	end
end

function ProgramPane:programResize()
	self.term:updateSize()
end
function ProgramPane:programPaint()
	if self.needsRepaint then
		self.term:repaint()
	else
		self.term:paint()
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