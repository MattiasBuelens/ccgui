--[[

	ComputerCraft GUI
	Geometry: Rectangle

--]]

os.loadAPI("/rom/apis/vector")

local Margins = require "ccgui.geom.Margins"
local Line = require "ccgui.geom.Line"
local Polygon = require "ccgui.geom.Polygon"

local Rectangle = Polygon:subclass("ccgui.Rectangle")
function Rectangle:initialize(x, y, w, h)
	if type(x) == "table" then
		if(x.w) then
			-- Clone rectangle
			x, y, w, h = x.x, x.y, x.w, x.h
		else
			-- Position as vector
			x, y, w, h = x.x, x.y, y, w
		end
	end
	if type(w) == "table" then
		-- Size as vector
		w, h = w.x, w.y
	end

	self.x = x or 0
	self.y = y or 0
	self.w = math.max(0, w)
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

--[[

	Polygon extensions

]]--

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

-- Exports
return Rectangle