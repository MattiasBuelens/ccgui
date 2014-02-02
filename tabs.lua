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
	title = "CCGUI :: Tabs Example",
	background = colours.white,
	windowBox = ccgui.geom.Rectangle:new(1, 1, 45, 15),
	_name = "window"
}
window:on("close", function()
	screen:stop()
end)

local tabs = ccgui.TabContainer:new{
	horizontal = false,
	stretch = true,
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
	text = "This is a read-only text viewer.\nYou can read, navigate and scroll here.\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nNothing to see here...",
	_name = "textViewer"
})
tabs:addTab("Write", ccgui.TextArea:new{
	text = "This is a text area.\nYou can read, edit, navigate and scroll here.",
	_name = "textArea"
})
local labelChoice = ccgui.TextElement:new{
	text = "Choice:"
}
local radioGroupChoice = ccgui.RadioGroup:new()
local radioOne = ccgui.RadioButton:new{
	radioLabel = "One",
	radioGroup = radioGroupChoice
}
local radioTwo = ccgui.RadioButton:new{
	radioLabel = "Two",
	radioGroup = radioGroupChoice
}
local radioThree = ccgui.RadioButton:new{
	radioLabel = "Three",
	radioGroup = radioGroupChoice
}
local form = ccgui.FlowContainer:new{
	horizontal = false,
	_name = "form"
}
form:add(labelChoice, radioOne, radioTwo, radioThree)
tabs:addTab("Form", form)
window:content():add(tabs)
container:add(window)
screen:add(container)
window:maximize()

screen:run()

-- Restore
screen:reset()