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
	text = "CCGUI :: Tabs Example",
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
local tabs = ccgui.TabContainer:new{
	horizontal = false,
	tabStretch = true,
	tabPadding = ccgui.geom.Margins:new(1, 1, 0),
	tabSpacing = 1,
	tabBackground = colours.lightBlue,
	tabOpts = {
		tabOnStyle = {
			foreground = colours.black,
			background = colours.white
		},
		tabOffStyle = {
			foreground = colours.grey,
			background = colours.lightGrey
		}
	},
	_name = "tabs"
}
tabs:addTab("Read", ccgui.TextViewer:new{
	text = "Foo\nbar",
	_name = "textViewer"
})
tabs:addTab("Write", ccgui.TextArea:new{
	_name = "textArea"
})

screen:add(header, tabs, footer)

screen:paint()
while isRunning do
	local event, p1, p2, p3, p4, p5 = os.pullEvent()
	screen:trigger(event, p1, p2, p3, p4, p5)
end

-- Restore
screen:reset()