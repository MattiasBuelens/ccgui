--[[

	ComputerCraft GUI OS
	Start menu

--]]

local Menu			= require "ccgui.Menu"
local MenuButton	= require "ccgui.MenuButton"
local ProgramWindow	= require "ccgui.ProgramWindow"

local ProgramMenuButton = MenuButton:subclass("ccgui.os.ProgramMenuButton")
function ProgramMenuButton:initialize(opts)
	super.initialize(self, opts)

	-- Program
	self.program = opts.program
	-- Target window container
	self.windows = opts.windows

	self:on("buttonpress", self.launchProgram, self)
end
function ProgramMenuButton:launchProgram()
	local window = ProgramWindow:new{
		title = self.program,
		program = self.program,
		programAutoStart = true,
		foreground = colours.black,
		background = colours.white
	}
	self.windows:add(window)
end

local StartMenu = Menu:subclass("ccgui.os.StartMenu")
function StartMenu:initialize(opts)
	opts.horizontal = false
	opts.background = opts.background or colours.lightGrey

	super.initialize(self, opts)

	-- Target window container
	self.windows = opts.windows

	self.programsMenu = self:createProgramsMenu()
	self:addSubMenu("Programs", self.programsMenu)

	self.shutdownButton = self:addButton("Shut down")
	self.shutdownButton.foreground = colours.red
	self.shutdownButton:on("buttonpress", function()
		os.shutdown()
	end)

	self.exitButton = self:addButton("Exit")
end

function StartMenu:createProgramsMenu()
	local menu = Menu:new{}
	local programs = shell.programs()
	for _,program in ipairs(programs) do
		menu:addButton(self:createProgramButton(program))
	end
	return menu
end

function StartMenu:createProgramButton(program)
	return ProgramMenuButton:new{
		text	= program,
		program = program,
		windows = self.windows
	}
end

-- Exports
return StartMenu