--[[

	ComputerCraft GUI
	Button element

--]]

local TextElement	= require "ccgui.TextElement"
local Pressable		= require "ccgui.Pressable"

local Button = TextElement:subclass("ccgui.Button")
Button:uses(Pressable)

function Button:initialize(opts)
	-- Default style
	opts.foreground = opts.foreground or colours.grey
	opts.background = opts.background or colours.lightGrey
	opts.padding = (opts.padding == nil) and 1 or opts.padding

	super.initialize(self, opts)
	self:pressInitialize(opts)
end

-- Exports
return Button