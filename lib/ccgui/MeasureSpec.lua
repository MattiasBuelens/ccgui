--[[

	ComputerCraft GUI
	Measure specification

--]]

local Object		= require "objectlua.Object"
local Margins		= require "ccgui.geom.Margins"
local DimensionSpec	= require "ccgui.DimensionSpec"

local MeasureSpec = Object:subclass("ccgui.MeasureSpec")

--[[
	MeasureSpec:new(MeasureSpec)
	MeasureSpec:new(Rectangle)
	MeasureSpec:new(DimensionSpec, DimensionSpec)
	MeasureSpec:new(widthType, widthValue, heightType, heightValue)
	MeasureSpec:new(widthType, heightType)
]]--
function MeasureSpec:initialize(widthType, widthValue, heightType, heightValue)
	local widthSpec, heightSpec
	if type(widthType) == "table" then
		if widthType.specType then
			-- Dimension specification
			widthSpec = widthType
			heightType, heightValue = widthValue, heightType
		elseif type(widthType.w) == "table" then
			-- Measure specification
			widthSpec, heightSpec = widthType.w, widthType.h
			heightType, heightValue = nil, nil
		elseif type(widthType.w) == "number" then
			-- Rectangle
			widthSpec = DimensionSpec:new("=", widthType.w)
			heightSpec = DimensionSpec:new("=", widthType.h)
		end
	elseif type(widthType) == "string" then
		if type(widthValue) == "number" then
			-- Type and value
			widthSpec = DimensionSpec:new(widthType, widthValue)
		else
			-- Type
			widthSpec = DimensionSpec:new(widthType)
			heightType, heightValue = widthValue, heightType
		end
	end
	if type(heightType) == "table" then
		-- Dimension specification
		heightSpec = heightType
	elseif type(heightType) == "string" then
		-- Type and value
		heightSpec = DimensionSpec:new(heightType, heightValue)
	end
	
	self.w = assert(widthSpec, "no width spec given")
	self.h = assert(heightSpec, "no height spec given")
end

function MeasureSpec:__tostring(o)
	return "MeasureSpec["..tostring(self.w)..","..tostring(self.h).."]"
end

function MeasureSpec:expand(m)
	m = Margins:new(m)
	return MeasureSpec:new(
		self.w:add(m:horizontal()),
		self.h:add(m:vertical())
	)
end
function MeasureSpec:contract(m)
	return self:expand(-m)
end

-- Exports
return MeasureSpec