--[[

	ComputerCraft GUI
	Button element

--]]

local Element	= require "ccgui.Element"

local Button = TextElement.subclass("ccgui.Button")
function Button:initialize(opts)
	-- Default style
	opts.foreground = opts.foreground or colours.grey
	opts.background = opts.foreground or colours.lightGrey
	opts.padding = opts.padding or 1

	super.initialize(self, opts)

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

-- Exports
return Button