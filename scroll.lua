--[[

	ComputerCraft GUI
	Scroll demo

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
local window = ccgui.Window:new{
	title = "CCGUI :: Scroll Demo",
	background = colours.white,
	windowBox = ccgui.geom.Rectangle:new(1, 1, 45, 15),
	_name = "window"
}
window:on("close", function()
	screen:stop()
end)

local content = ccgui.FlowContainer:new{
	stretch = true,
	horizontal = false
}
local toolbar = ccgui.FlowContainer:new{
	horizontal = true,
	padding = ccgui.geom.Margins:new(0, 1),
	spacing = 1,
	_name = "toolbar"
}
local btnOne = ccgui.Button:new{
	text = "One",
	_name = "btnOne"
}
btnOne:on("buttonpress", function()
	window:setStatusText("One pressed")
end)
local btnTwo = ccgui.Button:new{
	text = "Two",
	_name = "btnTwo"
}
btnTwo:on("buttonpress", function()
	window:setStatusText("Two pressed")
end)
local btnThree = ccgui.Button:new{
	text = "Three",
	_name = "btnThree"
}
btnThree:on("buttonpress", function()
	window:setStatusText("Three pressed")
end)
toolbar:add(btnOne, btnTwo, btnThree)
local txtA = ccgui.TextElement:new{
	text = "|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n",
	foreground = colours.grey
}
local txtB = ccgui.TextArea:new{
	text = "ABC\nDEF\nGHI"
}
content:add(toolbar, txtA, txtB)

local scroll = ccgui.ScrollWrapper:new{
	vertical = true,
	content = content,
	_name = "scroll"
}
window:content():add(scroll)
container:add(window)
screen:add(container)

screen:run()

-- Restore
screen:reset()