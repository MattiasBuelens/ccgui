--[[

	ComputerCraft GUI
	Grid demo

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
	title = "CCGUI :: Grid Demo",
	background = colours.white,
	windowBox = ccgui.geom.Rectangle:new(1, 1, 45, 15),
	_name = "window"
}
window:on("close", function()
	screen:stop()
end)

local content = ccgui.GridContainer:new{
	stretch = true,
	rowSpacing = 1,
	colSpacing = 1,
	colSpecs = {
		ccgui.GridContainer.GridSpec:new(false),
		ccgui.GridContainer.GridSpec:new(true)
	},
	rowSpecs = {
		ccgui.GridContainer.GridSpec:new(true),
		ccgui.GridContainer.GridSpec:new(false),
		ccgui.GridContainer.GridSpec:new(false)
	}
}
local btnOne = ccgui.Button:new{
	rowIndex = 1,
	colIndex = 1,
	text = "One",
	background = colours.red,
	_name = "btnOne"
}
btnOne:on("buttonpress", function()
	window:setStatusText("One pressed")
end)
local txtTwo = ccgui.TextArea:new{
	rowIndex = 1,
	colIndex = 2,
	text = "Twooooooooooooooooooooooooooooooooooooooo",
	_name = "txtTwo"
}
local btnThree = ccgui.Button:new{
	rowIndex = 2,
	colIndex = 1,
	text = "Three",
	background = colours.green,
	_name = "btnThree"
}
btnThree:on("buttonpress", function()
	window:setStatusText("Three pressed")
end)
local btnFour = ccgui.Button:new{
	rowIndex = 2,
	colIndex = 2,
	text = "Four",
	background = colours.cyan,
	_name = "btnFour"
}
btnFour:on("buttonpress", function()
	window:setStatusText("Four pressed")
end)
local btnFive = ccgui.Button:new{
	rowIndex = 3,
	colIndex = 1,
	text = "Five",
	background = colours.blue,
	_name = "btnFive"
}
btnFive:on("buttonpress", function()
	window:setStatusText("Five pressed")
end)
local btnSix = ccgui.Button:new{
	rowIndex = 3,
	colIndex = 2,
	text = "Six",
	background = colours.magenta,
	_name = "btnSix"
}
btnSix:on("buttonpress", function()
	window:setStatusText("Six pressed")
end)
content:add(btnOne, txtTwo, btnThree, btnFour, btnFive, btnSix)

window:content():add(content)
container:add(window)
screen:add(container)

screen:run()

-- Restore
screen:reset()