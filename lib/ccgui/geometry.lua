--[[

	ComputerCraft GUI
	Geometry

--]]

os.loadAPI("/rom/apis/vector")

local Object = require "objectlua.Object"

--[[

	Margins

]]--

local Margins = Object.subclass("ccgui.Margins")
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

--[[

	Line

]]--

local Line = Object.subclass("ccgui.Line")
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

--[[

	Polygon

]]--

local Polygon = Object.subclass("ccgui.Polygon")
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

function Polygon:bbox()
	local vertices = self.vertices

	-- Upper and lower coordinates
	local ux, uy = vertices[1].x, vertices[1].y
	local lx, ly = ux, ly

	-- Walk over vertices
	for i=2, #vertices do
		local v = vertices[i]
		ux = math.max(ux, v.x)
		ux = math.max(uy, v.y)
		lx = math.min(lx, v.x)
		ly = math.min(ly, v.y)
	end

	-- Return as rectangle
	return Rectangle:new(lx, ly, ux - lx, uy - ly)
end

function Polygon:__tostring()
	return "Polygon["..table.getn(self.vertices).."]"
end

--[[

	Rectangle

]]--

local Rectangle = Polygon.subclass("ccgui.Rectangle")
function Rectangle:initialize(x, y, w, h)
	-- Position as vector
	if type(x) == "table" then
		return ccgui.newRectangle(x.x, x.y, y, w)
	end
	-- Size as vector
	if type(w) == "table" then
		return ccgui.newRectangle(x, y, w.x, w.y)
	end
	
	self.x = x
	self.x = x,
	self.y = y,
	self.w = math.max(0, w),
	self.h = math.max(0, h)
	self.vertices = { self:tl(), self:tr(), self:br(), self:bl() }
end

function Rectangle:bbox()
	return self
end

function Rectangle:__tostring()
	return "Rectangle["..tostring(self:tl()).." to "..tostring(self:br()).."]"
end

function Rectangle:__eq(o)
	return self.x == o.x and self.y == o.y
		and self.w == o.w and self.h == o.h
end

-- Vertices
function Rectangle:tl()
	return vector.new(self.x, self.y)
end

function Rectangle:tr()
	return vector.new(self.x + self.w - 1, self.y)
end

function Rectangle:bl()
	return vector.new(self.x, self.y + self.h - 1)
end

function Rectangle:br()
	return vector.new(self.x + self.w - 1, self.y + self.h - 1)
end

-- Sides
function Rectangle:left()
	return Line:new(self:tl(), self:bl())
end

function Rectangle:right()
	return Line:new(self:tr(), self:br())
end

function Rectangle:top()
	return Line:new(self:tl(), self:tr())
end

function Rectangle:bottom()
	return Line:new(self:bl(), self:br())
end

-- Size
function Rectangle:size()
	return vector.new(self.w, self.h)
end

function Rectangle:area()
	return self.w * self.h
end

-- Queries
function Rectangle:contains(x, y)
	if type(x) == "table" then	
		-- Vector given
		return self:contains(x.x, x.y)
	end

	return self.x <= x and x < self.x + self.w
		and self.y <= y and y < self.y + self.h
end

-- Modifications
function Rectangle:shift(v)
	return Rectangle:new(self.x + v.x, self.y + v.y, self.w, self.h)
end

function Rectangle:expand(m)
	m = Margins:new(m)
	return Rectangle:new(
		self.x - m.left, self.y - m.top,
		self.w + m:horizontal(), self.h + m:vertical()
	)
end

function Rectangle:contract(m)
	return self:expand(-m)
end

-- Intersections
function Rectangle:intersects(rect)
	if rect == nil then return false end

	return self.x <= rect.x + rect.w
	   and self.x + self.w >= rect.x
	   and self.y <= rect.y + rect.h
	   and self.y + self.h >= rect.y
end

-- Exports
return {
	Margins		= Margins,
	Line		= Line,
	Polygon		= Polygon,
	Rectangle	= Rectangle
}