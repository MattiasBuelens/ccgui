--[[

	ComputerCraft GUI
	Windows demonstration

--]]


local root = fs.combine(shell.getRunningProgram(), "../lib/")
dofile(fs.combine(root, "/compat.lua"))
package.root = root

local ccgui		= require "ccgui"
local ccguios	= require "ccgui.os"

local screen = ccgui.Page:new{
	horizontal = false,
	background = colours.lightBlue,
	_name = "screen"
}
local container = ccgui.WindowContainer:new{
	stretch = true,
	_name = "container"
}
container:on("remove", function()
	if container:getWindowCount() == 0 then
		screen:stop()
	end
end)
local taskBar = ccguios.TaskBar:new{
	_name = "taskBar"
}
local window1 = ccgui.Window:new{
	title = "Window 1",
	foreground = colours.black,
	background = colours.white,
	windowPos = vector.new(1, 1),
	padding = 1,
	_name = "window1"
}
local labelHello = ccgui.TextElement:new{
	stretch = true,
	text = "Click New to open a shell",
	_name = "labelHello"
}
local toolbar = ccgui.FlowContainer:new{
	horizontal = true,
	spacing = 1,
	_name = "toolbar"
}
local btnNew = ccgui.Button:new{
	text = "New",
	_name = "btnNew"
}
btnNew:on("buttonpress", function()
	local window = ccgui.ProgramWindow:new{
		title = "Shell",
		program = "shell",
		programAutoStart = true,
		foreground = colours.black,
		background = colours.white,
		titleBackground = colours.green,
		windowPos = vector.new(10, 5),
		_name = "shell"
	}
	container:add(window)
end)
local btnQuit = ccgui.Button:new{
	text = "Quit",
	_name = "btnQuit"
}
btnQuit:on("buttonpress", function()
	screen:stop()
end)
toolbar:add(btnNew, btnQuit)
window1:content():add(labelHello, toolbar)
local window2 = ccgui.Window:new{
	title = "Window 2",
	foreground = colours.black,
	background = colours.white,
	windowPos = vector.new(20, 1),
	windowSize = vector.new(30, 10),
	_name = "window2"
}
local textFoo = ccgui.TextArea:new{
	stretch = true,
	text = "This is a text area where\nyou can type some text.\n\nSupports scrolling and\nkeyboard/mouse navigation!",
	_name = "textFoo"
}
window2:content():add(textFoo)
container:add(taskBar, window1, window2)
screen:add(container)

screen:run()

-- Restore
screen:reset()