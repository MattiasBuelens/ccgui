--[[

	ComputerCraft GUI
	Geometry: Line

--]]

os.loadAPI("/rom/apis/vector")

local Object = require "objectlua.Object"

local Line = Object:subclass("ccgui.Line")
function Line:initialize(start, stop)
	self.start = start
	self.stop = stop
end

function Line:delta()
	return self.stop - self.start
end

function Line:length()
	return self:delta():length() + 1
end

function Line:isHorizontal()
	return self:delta().y == 0
end

function Line:isVertical()
	return self:delta().x == 0
end

function Line:points()
	local delta, length = self:delta(), self:length()
	if length <= 0 then
		return { self.start }
	end

	-- Shifts per unit length
	local dx, dy = delta.x / length, delta.y / length

	-- Walk along line
	local points = {}
	table.insert(points, self.start)
	for i=1, math.floor(length - 0.5) do
		local x, y = math.floor(i*dx), math.floor(i*dy)
		table.insert(points, self.start + vector.new(x, y))
	end
	table.insert(points, self.stop)

	return points
end

function Line:__tostring()
	return "Line["..tostring(self.start).." to "..tostring(self.stop).."]"
end

function Line:__eq(o)
	return self.start.x == o.start.x and self.start.y == o.start.y
		and self.stop.x == o.stop.x and self.stop.x == o.stop.y
end

-- Exports
return Line