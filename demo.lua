--[[

	ComputerCraft GUI
	Demonstration program

--]]


local root = fs.combine(shell.getRunningProgram(), "/../../")
dofile(fs.combine(root, "/compat.lua"))
package.root = root

local Geometry		= require "ccgui.Geometry"
local Align			= require "ccgui.Align"
local VAlign		= require "ccgui.VAlign"
local Margins		= Geometry.Margins

local paint = true
local isRunning = true

local screen = require("ccgui.Page"):new{
	horizontal = false,
	background = colours.white,
	_name = "screen"
}
local header = require("ccgui.FlowContainer"):new{
	horizontal = true,
	_name = "header"
}
local headerTitle = require("ccgui.TextElement"):new{
	text = "CCGUI DEMONSTRATION",
	align = Align.Center,
	stretch = true,
	foreground = colours.white,
	background = colours.blue,
	_name = "headerTitle"
}
local btnQuit = require("ccgui.Button"):new{
	text = "X",
	align = Align.Right,
	padding = 0,
	_name = "btnQuit"
}
btnQuit:on("buttonpress", function()
	isRunning = false
end)
header:add(headerTitle, btnQuit)

local footer = require("ccgui.TextElement"):new{
	text = "Ready",
	foreground = colours.white,
	background = colours.lightGrey,
	_name = "footer"
}

local toolbar = require("ccgui.FlowContainer"):new{
	horizontal = true,
	padding = Margins:new(0, 1),
	spacing = 1,
	_name = "toolbar"
}
local btnOne = require("ccgui.Button"):new{
	text = "One",
	_name = "btnOne"
}
btnOne:on("buttonpress", function()
	footer:setText("One pressed")
end)
local btnTwo = require("ccgui.Button"):new{
	text = "Two",
	_name = "btnTwo"
}
btnTwo:on("buttonpress", function()
	footer:setText("Two pressed")
end)
local btnThree = require("ccgui.Button"):new{
	text = "Three",
	_name = "btnThree"
}
btnThree:on("buttonpress", function()
	footer:setText("Three pressed")
end)
toolbar:add(btnOne, btnTwo, btnThree)

local fieldAddress = require("ccgui.FlowContainer"):new{
	horizontal = true,
	padding = Margins:new(1),
	_name = "fieldAddress"
}
local labelAddress = require("ccgui.TextElement"):new{
	text = "To: ",
	_name = "labelAddress"
}
local textAddress = require("ccgui.TextInput"):new{
	_name = "textAddress"
}
textAddress:setText("mattias@island")
fieldAddress:add(labelAddress, textAddress)

local textMessage = require("ccgui.TextArea"):new{
	stretch = true
}
screen:add(header, toolbar, fieldAddress, textMessage, footer)

screen:repaint()
while isRunning do
	local event, p1, p2, p3, p4, p5 = os.pullEvent()
	screen:trigger(event, p1, p2, p3, p4, p5)
end

-- Restore
screen:reset()