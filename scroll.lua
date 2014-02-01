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
local btnQuit = ccgui.Button:new{
	text = "Quit"
}
btnQuit:on("buttonpress", function()
	screen:stop()
end)
local txtA = ccgui.TextElement:new{
	text = "ABC\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nDEF\nGHI"
}
local txtB = ccgui.TextArea:new{
	text = "ABC\nDEF\nGHI"
}
content:add(btnQuit, txtA, txtB)

local scroll = require("ccgui.ScrollWrapper"):new{
	vertical = true,
	content = content,
	_name = "scroll"
}
window:add(scroll)
container:add(window)
screen:add(container)

screen:run()

-- Restore
screen:reset()