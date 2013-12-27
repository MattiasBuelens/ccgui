--[[

	ComputerCraft GUI
	Multiline text viewer

]]--

local TextArea	= require "ccgui.TextArea"

local TextViewer = TextArea:subclass("ccgui.TextViewer")

function TextViewer:readonly()
	return true
end

-- Exports
return TextViewer