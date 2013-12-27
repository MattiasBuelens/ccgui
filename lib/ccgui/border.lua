--[[

	ComputerCraft GUI
	Border

--]]

local Object		= require "objectlua.Object"
local Margins		= require "ccgui.geom.Margins"

local Border = Object:subclass("ccgui.Border")
function Border:initialize(...)
	local args = { ... }
	local n = #args

	-- Defaults
	local top, right, bottom, left

	if n >= 4 then
		-- All colors
		top, right, bottom, left = unpack(args)
	elseif n == 1 then
		local x = args[1]
		if type(x) == "table" then
			-- Clone colors
			top, right, bottom, left = x.top, x.right, x.bottom, x.left
		else
			-- One color for all
			top, right, bottom, left = x, x, x, x
		end
	elseif n == 2 then
		-- Vertical and horizontal colors
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

function Border:get(side)
	return self[side] or 0
end

function Border:set(side, color)
	if type(side) == "string" then
		-- setColor(side, color)
		self[side] = (color or 0)
	elseif type(side) == "number" then
		-- setColor(color)
		color = side
		self:set("top", color)
		self:set("right", color)
		self:set("bottom", color)
		self:set("left", color)
	end
end

function Border:has(side)
	return self[side] ~= 0
end

function Border:margins()
	return Margins:new{
		top		= self:has("top")		and 1 or 0,
		right	= self:has("right")		and 1 or 0,
		bottom	= self:has("bottom")	and 1 or 0,
		left	= self:has("left")		and 1 or 0
	}
end

function Border:__tostring()
	return "Border["
		..self:get("top")..","..self:get("right")..","
		..self:get("bottom")..","..self:get("left").."]"
end

-- Exports
return Border