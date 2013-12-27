--[[

	ComputerCraft GUI
	Painting

--]]

local Object	= require "objectlua.Object"
local Rectangle	= require "ccgui.geom.Rectangle"

local PaintPixel = Object:subclass("ccgui.paint.PaintPixel")
function PaintPixel:initialize(opts)
	super.initialize(self, opts)

	self.x			= opts.x or 0
	self.y			= opts.y or 0
	self.content	= opts.content or " "
	self.foreground	= opts.foreground or colours.white
	self.background	= opts.background or 0
end

-- Compare pixels
function PaintPixel:__eq(o)
	return self.x == o.x and self.y == o.y
		and self.content == o.content
		and self.foreground == o.foreground and self.background == o.background
end

-- Merge with pixel below
function PaintPixel:merge(pixel)
	-- Inherit colors from other pixel when transparent (zero)
	if self.foreground == 0 then
		if pixel ~= nil and pixel.foreground ~= 0 then
			self.foreground = pixel.foreground
		end
	end
	if self.background == 0 then
		if pixel ~= nil and pixel.background ~= 0 then
			self.background = pixel.background
		end
	end
end

local PaintLayer = Object:subclass("ccgui.paint.PaintLayer")
function PaintLayer:initialize(opts)
	super.initialize(self, opts)

	-- Painted pixels
	self.buffer = {}
	-- Pixels to be painted
	self.update = {}
	-- Output device
	self.output = opts.output or term

	self:updateBounds()
end

-- Get bounding rectangle
function PaintLayer:getBounds()
	return Rectangle:new(1, 1, self.width, self.height)
end

function PaintLayer:updateBounds()
	self.width, self.height = self.output.getSize()
	-- Clear buffers, redraw needed
	self.buffer = {}
	self.update = {}
end

function PaintLayer:getIndex(x, y)
	return (y-1) * self.width + x
end

-- Get painted pixel
function PaintLayer:getBufferPixel(x, y)
	return self.buffer[self:getIndex(x, y)]
end

-- Get pixel to be paint
function PaintLayer:getPixel(x, y)
	local i = self:getIndex(x, y)
	return self.update[i] or self.buffer[i]
end

function PaintLayer:setBufferPixel(pixel)
	self.buffer[self:getIndex(pixel.x, pixel.y)] = pixel
end

function PaintLayer:setPixel(pixel)
	-- Merge with current pixel
	local current = self:getPixel(pixel.x, pixel.y)
	pixel:merge(current)

	self.update[self:getIndex(pixel.x, pixel.y)] = pixel
end

function PaintLayer:commitPixel(pixel, force)
	if pixel == nil then
		return false
	end

	if not force then
		-- Compare to current pixel
		local current = self:getBufferPixel(pixel.x, pixel.y)
		if current ~= nil and current == pixel then
			return false
		end
		self.changed = (self.changed or 0) + 1
	end

	-- Set as buffer pixel
	self:setBufferPixel(pixel)
	-- Draw pixel
	self:drawPixel(pixel)
	return true
end

-- Draw on output
function PaintLayer:drawPixel(pixel)
	self.output.setCursorPos(pixel.x, pixel.y)
	self.output.setTextColor(self.output.isColor() and pixel.foreground or colours.white)
	self.output.setBackgroundColor(self.output.isColor() and pixel.background or colours.black)
	self.output.write(pixel.content)
end

-- Paint updated pixels
function PaintLayer:paint()
	-- Loop over update queue
	for i,pixel in pairs(self.update) do
		-- Commit pixel
		self:commitPixel(pixel)
	end
	--[[for y,row in pairs(self.update) do
		for x,pixel in pairs(row) do
			self:commitPixel(pixel)
		end
	end]]--
	-- Clear update queue
	self.update = {}
end

-- Redraw all pixels
function PaintLayer:repaint()
	-- Loop over whole screen
	for y=1,self.height do
		for x=1,self.width do
			-- Recommit pixel
			local pixel = self:getPixel(x, y)
			self:commitPixel(pixel, true)
		end
	end
	-- Clear update queue
	self.update = {}
end

-- Clear whole screen
function PaintLayer:clear()
	-- Reset output
	self.output.setTextColor(colours.white)
	self.output.setBackgroundColor(colours.black)
	self.output.clear()
	self.output.setCursorPos(1, 1)
	-- Clear buffers
	self.buffer = {}
	self.update = {}
end

-- Write single text line
function PaintLayer:write(x, y, text, foreground, background)
	local n = string.len(text)
	for i=1,n do
		self:setPixel(PaintPixel:new({
			x			= x + i - 1,
			y			= y,
			content		= string.sub(text, i, i),
			foreground	= foreground,
			background	= background
		}))
	end
end

-- Exports
return PaintLayer