--[[

	ComputerCraft GUI
	Demonstration program

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
	title = "CCGUI :: Demonstration",
	background = colours.white,
	windowBox = ccgui.geom.Rectangle:new(1, 1, 45, 15),
	_name = "window"
}
window:on("close", function()
	screen:stop()
end)

local footer = ccgui.TextElement:new{
	text = "Ready",
	foreground = colours.white,
	background = colours.lightGrey,
	_name = "footer"
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
	footer:setText("One pressed")
end)
local btnTwo = ccgui.Button:new{
	text = "Two",
	_name = "btnTwo"
}
btnTwo:on("buttonpress", function()
	footer:setText("Two pressed")
end)
local btnThree = ccgui.Button:new{
	text = "Three",
	_name = "btnThree"
}
btnThree:on("buttonpress", function()
	footer:setText("Three pressed")
end)
toolbar:add(btnOne, btnTwo, btnThree)

local fieldAddress = ccgui.FlowContainer:new{
	horizontal = true,
	padding = ccgui.geom.Margins:new(1),
	_name = "fieldAddress"
}
local labelAddress = ccgui.TextElement:new{
	text = "To: ",
	_name = "labelAddress"
}
local textAddress = ccgui.TextInput:new{
	_name = "textAddress"
}
textAddress:setText("mattias@island")
fieldAddress:add(labelAddress, textAddress)

local textMessage = ccgui.TextArea:new{
	stretch = true,
	_name = "textMessage"
}
window:content():add(toolbar, fieldAddress, textMessage, footer)
container:add(window)
screen:add(container)
window:maximize()

screen:run()

-- Restore
screen:reset()