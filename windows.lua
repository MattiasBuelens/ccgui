--[[

	ComputerCraft GUI
	Windows demonstration

--]]


local root = fs.combine(shell.getRunningProgram(), "../lib/")
dofile(fs.combine(root, "/compat.lua"))
package.root = root

local ccgui	= require "ccgui"

local isRunning = true

local screen = ccgui.Page:new{
	horizontal = false,
	_name = "screen"
}
local container = ccgui.WindowContainer:new{
	stretch = true,
	background = colours.lightBlue,
	_name = "container"
}
container:on("remove", function()
	if container:windowCount() == 0 then
		isRunning = false
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
local btnQuit = ccgui.Button:new{
	text = "Quit",
	_name = "btnQuit"
}
btnQuit:on("buttonpress", function()
	isRunning = false
end)
window1:content():add(labelHello, btnQuit)
local window2 = ccgui.Window:new{
	title = "Window 2",
	foreground = colours.black,
	background = colours.white,
	windowBox = ccgui.geom.Rectangle:new(10, 3, 15, 10),
	_name = "window2"
}
local textFoo = ccgui.TextArea:new{
	stretch = true,
	text = "Here is a longer text\nwith lots of interesting stuff!\n\nFoo\nBar\nBaz",
	_name = "textFoo"
}
window2:content():add(textFoo)
container:add(window1, window2)
screen:add(container)

screen:paint()
while isRunning do
	local event, p1, p2, p3, p4, p5 = os.pullEvent()
	screen:trigger(event, p1, p2, p3, p4, p5)
end

-- Restore
screen:reset()