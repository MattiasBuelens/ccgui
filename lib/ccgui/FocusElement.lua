--[[

	ComputerCraft GUI
	Focusable element

--]]

local Element		= require "ccgui.Element"

local FocusElement = Element.subclass("ccgui.FocusElement")
function FocusElement:initialize(opts)
	super.initialize(self, opts)

	self.hasFocus = false

	self:bubbleEvent("focus")
	self:bubbleEvent("blur")

	-- Repaint on focus
	--[[self:on("focus", self.markRepaint, self)
	self:on("focus", self.markRepaint, self)
	self:on("blur", self.markRepaint, self)]]--
end

function FocusElement:canFocus()
	return self.isVisible
end

-- Exports
return FocusElement