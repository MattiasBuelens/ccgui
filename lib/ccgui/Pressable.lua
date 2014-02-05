--[[

	ComputerCraft GUI
	Pressable

--]]

local Trait			= require "objectlua.Traits.Trait"

local Pressable = Trait:new("ccgui.Pressable")
function Pressable:pressInitialize(opts)
	self:on("mouse_click", self.pressClick, self)
end

function Pressable:pressClick(button, x, y)
	if button == 1 then
		-- Left mouse button, trigger pressed
		if self:isVisible() and self:contains(x, y) then
			self:trigger("buttonpress")
		end
	end
end

-- Exports
return Pressable