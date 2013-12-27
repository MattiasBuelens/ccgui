--[[

	ComputerCraft GUI
	Geometry: Polygon

--]]

os.loadAPI("/rom/apis/vector")

local Object = require "objectlua.Object"
local Line = require "ccgui.geom.Line"

local Polygon = Object:subclass("ccgui.Polygon")
function Polygon:initialize(vertices)
	vertices = vertices or {}

	-- Vertices passed as table
	while table.getn(vertices) == 1 do
		vertices = vertices[1]
	end

	-- Check amount of vertices
	if #vertices < 2 then
		error("Polygon requires at least two vertices")
	end

	self.vertices = vertices
end

function Polygon:sides()
	local vertices = self.vertices

	-- Add last side first
	local v1, v2 = vertices[#vertices], vertices[1]
	local sides = { Line:new(v1, v2) }

	-- Walk over vertices
	for i=2, #vertices do
		v1, v2 = v2, vertices[i]
		table.insert(sides, Line:new(v1, v2))
	end

	return sides
end

function Polygon:points()
	local sides = self:sides()

	local points = {}
	for i,side in ipairs(sides) do
		-- Get points from side
		local sidePoints = side:points()
		-- Remove last point, since the next side
		-- will have it as its first point
		table.remove(sidePoints, #sidePoints)
		-- Add to polygon points
		for j=1, #sidePoints do
			table.insert(points, sidePoints[j])
		end
	end
	return points
end

function Polygon:__tostring()
	return "Polygon["..table.getn(self.vertices).."]"
end

-- Exports
return Polygon