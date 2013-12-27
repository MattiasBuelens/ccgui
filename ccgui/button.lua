--[[

	ComputerCraft GUI
	Button element

--]]

ccgui = ccgui or {}

local Button = common.newClass({
	-- Style
	foreground = colours.grey,
	background = colours.lightGrey,
	border = ccgui.newBorder(0),
	padding = ccgui.newMargins(1)
}, ccgui.TextElement)
ccgui.Button = Button

function Button:init()
	ccgui.TextElement.init(self)

	self:on("mouse_click", self.buttonClick, self)
end

function Button:buttonClick(button, x, y)
	if button == 1 then
		-- Left mouse button, trigger pressed
		if self.isVisible and self:contains(x, y) then
			self:trigger("buttonpress")
		end
	end
end