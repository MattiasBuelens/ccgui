--[[

	ComputerCraft GUI
	Dimension specification

--]]

local Object = require "objectlua.Object"

-- Specification types
DimensionSpec.class.Unspecified	= "?"
DimensionSpec.class.Exact			= "="
DimensionSpec.class.AtMost		= "<"

local DimensionSpec = Object:subclass("ccgui.DimensionSpec")
function DimensionSpec:initialize(specType, value)
	self.specType = specType or self.Unspecified
	self.value = self:isUnspecified() and math.huge or (value or 0)
end

function DimensionSpec:isUnspecified()
	return self.specType == DimensionSpec.class.Unspecified
end
function DimensionSpec:isExact()
	return self.specType == DimensionSpec.class.Exact
end
function DimensionSpec:isAtMost()
	return self.specType == DimensionSpec.class.AtMost
end

function DimensionSpec:add(v)
	return DimensionSpec:new(self.specType, self.value + v)
end
function DimensionSpec:multiply(f)
	return DimensionSpec:new(self.specType, self.value * f)
end
function DimensionSpec:__add(m)
	return self:add(m)
end
function DimensionSpec:__mul(f)
	return self:multiply(f)
end
function DimensionSpec:__unm()
	return self:multiply(-1)
end
function DimensionSpec:__eq(o)
	return self.specType == o.specType and self.value == o.value
end

function DimensionSpec:__tostring(o)
	if self:isUnspecified() then
		return "DimensionSpec["..self.specType.."]"
	end
	return "DimensionSpec["..self.specType..self.value.."]"
end

-- Exports
return DimensionSpec