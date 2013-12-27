--[[

	ComputerCraft GUI
	Geometry: Margins

--]]

os.loadAPI("/rom/apis/vector")

local Object = require "objectlua.Object"

local Margins = Object.subclass("ccgui.geom.Margins")
function Margins:initialize(...)
	local args = { ... }
	local n = #args
	local top, right, bottom, left

	if n >= 4 then
		top, right, bottom, left = unpack(args)
	elseif n == 1 then
		local m = args[1]
		if type(m) == "table" then
			-- Clone margins
			top, right, bottom, left = m.top, m.right, m.bottom, m.left
		else
			-- All margins
			top, right, bottom, left = m, m, m, m
		end
	elseif n == 2 then
		-- Vertical and horizontal margins
		top, right, bottom, left = args[1], args[2], args[1], args[2]
	elseif n == 3 then
		-- Top, horizontal and bottom margins
		top, right, bottom, left = args[1], args[2], args[3], args[2]
	end

	self.top	= tonumber(top)
	self.right	= tonumber(right)
	self.bottom	= tonumber(bottom)
	self.left	= tonumber(left)
end

function Margins:vertical()
	return self.top + self.bottom
end

function Margins:horizontal()
	return self.left + self.right
end

function Margins:add(m)
	return Margins:new(self.top + m.top, self.right + m.right, self.bottom + m.bottom, self.left + m.left)
end

function Margins:multiply(m)
	return Margins:new(self.top * m, self.right * m, self.bottom * m, self.left * m)
end

function Margins:__add(o)
	return self:add(o)
end

function Margins:__unm()
	return self:multiply(-1)
end

function Margins:__eq(o)
	return self.top == o.top and self.right == o.right
		and self.bottom == o.bottom and self.left == o.left
end

function Margins:__tostring(o)
	return "Margins["..self.top..","..self.right..","..self.bottom..","..self.left.."]"
end

-- Exports
return Margins