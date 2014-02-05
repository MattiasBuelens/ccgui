--[[

	ComputerCraft GUI
	Password input

]]--

local TextInput	= require "ccgui.TextInput"

local PasswordInput = TextInput:subclass("ccgui.PasswordInput")

function PasswordInput:initialize(opts)
	super.initialize(self, opts)

	-- Password mask
	self.passwordMask = opts.passwordMask or "*"
end

function PasswordInput:drawTextLine(ctxt, line, x, y, bbox)
	line = string.gsub(line, ".", self.passwordMask)
	super.drawTextLine(self, ctxt, line, x, y, bbox)
end

return PasswordInput