--[[

	ComputerCraft GUI
	Single line text input

]]--

local TextArea	= require "ccgui.TextArea"

local TextInput = TextArea.subclass("ccgui.TextInput")
function TextInput:initialize(opts)
	opts.horizontal = true
	opts.vertical = false
	opts.mouseScroll = false
	opts.showScrollBars = false

	super.initialize(self, opts)
end

function TextInput:multiline()
	return false
end

return TextInput