--[[

	ComputerCraft GUI
	Focusable element

--]]

ccgui = ccgui or {}

local FocusElement = common.newClass({
	hasFocus = false
}, ccgui.Element)
ccgui.FocusElement = FocusElement

function FocusElement:init()
	ccgui.Element.init(self)

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