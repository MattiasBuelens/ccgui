--[[

	ComputerCraft GUI
	Button element

--]]

local TextElement	= require "ccgui.TextElement"

local Button = TextElement:subclass("ccgui.Button")
function Button:initialize(opts)
	-- Default style
	opts.foreground = opts.foreground or colours.grey
	opts.background = opts.background or colours.lightGrey
	opts.padding = (opts.padding == nil and 1) or tonumber(opts.padding)

	super.initialize(self, opts)

	self:on("mouse_click", self.buttonClick, self)
end

function Button:buttonClick(button, x, y)
	if button == 1 then
		-- Left mouse button, trigger pressed
		if self:visible() and self:contains(x, y) then
			self:trigger("buttonpress")
		end
	end
end

-- Exports
return Button