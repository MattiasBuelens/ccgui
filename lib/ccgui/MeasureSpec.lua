--[[

	ComputerCraft GUI
	Measure specification

--]]

local Object		= require "objectlua.Object"
local Margins		= require "ccgui.geom.Margins"
local DimensionSpec	= require "ccgui.DimensionSpec"

local MeasureSpec = Object:subclass("ccgui.MeasureSpec")
function MeasureSpec:initialize(widthType, widthValue, heightType, heightValue)
	local widthSpec, heightSpec
	if type(widthType) == "table" then
		if widthType.w then
			-- Rectangle
			widthSpec = DimensionSpec:new("=", widthType.w)
			heightSpec = DimensionSpec:new("=", widthType.h)
		elseif widthType.specType then
			-- Dimension specification
			widthSpec = widthType
			heightType, heightValue = widthValue, heightType
		elseif widthType.widthSpec then
			-- Measure specification
			widthSpec, heightSpec = widthType.widthSpec, widthType.heightSpec
			heightType, heightValue = nil, nil
		end
	elseif type(widthType) == "string" then
		-- Type and value
		widthSpec = DimensionSpec:new(widthType, widthValue)
	end
	if type(heightType) == "table" then
		-- Dimension specification
		heightSpec = heightType
	elseif type(heightType) == "string" then
		-- Type and value
		heightSpec = DimensionSpec:new(heightType, heightValue)
	end
	
	self.widthSpec = assert(widthSpec, "no width spec given")
	self.heightSpec = assert(heightSpec, "no height spec given")
end

function MeasureSpec:__tostring(o)
	return "MeasureSpec["..tostring(self.widthSpec)..","..tostring(self.widthSpec).."]"
end

function MeasureSpec:expand(m)
	m = Margins:new(m)
	return MeasureSpec:new(
		self.widthSpec:add(m:horizontal()),
		self.heightSpec:add(m:vertical())
	)
end
function MeasureSpec:contract(m)
	return self:expand(-m)
end

-- Exports
return MeasureSpec