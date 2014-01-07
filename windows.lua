--[[

	ComputerCraft GUI
	Windows demonstration

--]]


local root = fs.combine(shell.getRunningProgram(), "../lib/")
dofile(fs.combine(root, "/compat.lua"))
package.root = root

local ccgui	= require "ccgui"

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
local window1 = ccgui.Window:new{
	title = "Window 1",
	foreground = colours.black,
	background = colours.white,
	_name = "window1"
}
local labelHello = ccgui.TextElement:new{
	stretch = true,
	text = "Hello, world!",
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
	local window = ccgui.Window:new{
		title = "New window",
		foreground = colours.black,
		background = colours.white,
		windowPos = vector.new(10, 5),
		titleBackground = colours.green
	}
	local labelHello = ccgui.TextElement:new{
		stretch = true,
		text = "A brand new window!"
	}
	window:content():add(labelHello)
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
	windowPos = vector.new(25, 3),
	windowSize = vector.new(20, 10),
	_name = "window2"
}
local textFoo = ccgui.TextArea:new{
	stretch = true,
	text = "Here is a longer text\nwith lots of interesting stuff!\n\nFoo\nBar\nBaz",
	_name = "textFoo"
}
window2:content():add(textFoo)
local window3 = ccgui.ProgramWindow:new{
	title = "Shell",
	program = "/rom/programs/shell",
	foreground = colours.black,
	background = colours.white,
	windowPos = vector.new(2, 8),
	_name = "window3"
}
container:add(window1, window2, window3)
screen:add(container)

screen:run()

-- Restore
screen:reset()