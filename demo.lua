--[[

	ComputerCraft GUI
	Demonstration program

--]]


local root = fs.combine(shell.getRunningProgram(), "../lib/")
dofile(fs.combine(root, "/compat.lua"))
package.root = root

local ccgui	= require "ccgui"

local isRunning = true

local screen = ccgui.Page:new{
	horizontal = false,
	background = colours.white,
	_name = "screen"
}
local header = require("ccgui.FlowContainer"):new{
	horizontal = true,
	_name = "header"
}
local headerTitle = ccgui.TextElement:new{
	text = "CCGUI :: Demonstration",
	align = ccgui.Align.Center,
	stretch = true,
	foreground = colours.white,
	background = colours.blue,
	_name = "headerTitle"
}
local btnQuit = ccgui.Button:new{
	text = "x",
	align = ccgui.Align.Right,
	padding = 0,
	foreground = colours.white,
	background = colours.red,
	_name = "btnQuit"
}
btnQuit:on("buttonpress", function()
	isRunning = false
end)
header:add(headerTitle, btnQuit)

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
screen:add(header, toolbar, fieldAddress, textMessage, footer)

screen:paint()
while isRunning do
	local event, p1, p2, p3, p4, p5 = os.pullEvent()
	screen:trigger(event, p1, p2, p3, p4, p5)
end

-- Restore
screen:reset()