--[[

	ComputerCraft GUI
	Flow container

--]]

local Container		= require "ccgui.Container"
local Rectangle		= require "ccgui.geom.Rectangle"

local FlowContainer = Container:subclass("ccgui.FlowContainer")
function FlowContainer:initialize(opts)
	super.initialize(self, opts)
	-- Orientation
	self.horizontal = not not opts.horizontal
	-- Spacing between children
	self.spacing = opts.spacing or 0
end

function FlowContainer:measure(size)
	-- Get inner box
	local cbox = self:inner(size)

	-- Flow dimension
	local flowDim = (self.horizontal and "w") or "h"
	-- Fixed dimension
	local fixedDim = (self.horizontal and "h") or "w"

	-- Flow size
	local flowSize = 0
	-- Remaining flow size
	local remaining = cbox[flowDim]
	-- Fixed size
	local fixedSize = cbox[fixedDim]
	-- Maximum fixed size
	local maxFixed = 0

	-- Children to be stretched
	local stretchChildren = {}

	-- Update sizes of children
	self:eachVisible(function(child, i, n)
		-- No spacing on last child
		local spacing = (i < n and self.spacing) or 0
		-- Handle absolutely positioned children
		if child.absolute then
			-- Can occupy whole inner box
			child:measure(Rectangle:new(cbox))
			return
		end
		-- Handle stretched children later
		if child.stretch then
			-- Remove spacing from remaining
			-- and add to flow size
			flowSize = flowSize + spacing
			remaining = remaining - spacing
			-- Add to stretched children
			table.insert(stretchChildren, child)
			return
		end
		-- Get child size
		child:measure(Rectangle:new{
			[flowDim] = remaining,
			[fixedDim] = fixedSize
		})
		-- Remove child size and spacing from remaining
		-- and add to flow size
		local childSize = child.size[flowDim] + spacing
		flowSize = flowSize + childSize
		remaining = remaining - childSize
		-- Update maximum fixed size
		maxFixed = math.max(maxFixed, child.size[fixedDim])
	end)

	-- Divide remaining size over stretched children
	local stretchSize = math.floor(remaining / #stretchChildren)
	local firstStretch = stretchSize + (remaining % #stretchChildren)
	for i,child in ipairs(stretchChildren) do
		local childSize = (i == 1 and firstStretch) or stretchSize
		-- Get child size
		child:measure(Rectangle:new{
			[flowDim] = childSize,
			[fixedDim] = fixedSize
		})
		-- Force flow size
		child.size[flowDim] = childSize
		-- Add child size to flow size
		flowSize = flowSize + childSize
		-- Update maximum fixed size
		maxFixed = math.max(maxFixed, child.size[fixedDim])
	end

	-- Enforce fixed size
	self:eachVisible(function(child)
		-- Ignore absolutely positioned children
		if child.absolute then return end
		-- Set fixed size
		child.size[fixedDim] = maxFixed
	end)

	-- Get children size box
	size = Rectangle:new{
		[flowDim] = flowSize,
		[fixedDim] = maxFixed
	}
	-- Use outer size box
	size = self:outer(size)
	super.measure(self, size)
end

function FlowContainer:updateLayout(bbox)
	super.updateLayout(self, bbox)

	-- Get inner box for children bounding box
	local cbox = self:inner(bbox)

	-- Collect old child bounding boxes
	--[[local childBboxes = {}
	self:eachVisible(function(child, i)
		childBboxes[i] = child.bbox
	end)]]--

	-- Flow coordinate
	local flowCoord = (self.horizontal and "x") or "y"
	-- Fixed coordinate
	local fixedCoord = (self.horizontal and "y") or "x"
	-- Flow dimension
	local flowDim = (self.horizontal and "w") or "h"
	-- Fixed dimension
	local fixedDim = (self.horizontal and "h") or "w"

	-- Flow position
	local flowPos = cbox[flowCoord]
	-- Fixed size
	local fixedPos, fixedSize = cbox[fixedCoord], cbox[fixedDim]

	-- Update layout of children
	self:eachVisible(function(child, i, n)
		local spacing = (i < n and self.spacing) or 0
		-- Handle absolutely positioned children
		if child.absolute then
			-- Position in top-left corner
			child:updateLayout(Rectangle:new(cbox:tl(), child.size:size()))
			return
		end
		-- Get child bounding box
		child:updateLayout(Rectangle:new{
			[flowCoord] = flowPos,
			[fixedCoord] = fixedPos,
			[flowDim] = child.size[flowDim],
			[fixedDim] = fixedSize
		})
		-- Force size
		child.bbox[flowDim] = child.size[flowDim]
		child.bbox[fixedDim] = fixedSize
		-- Add child size and spacing to flow position
		local childSize = child.bbox[flowDim] + spacing
		flowPos = flowPos + childSize
	end)

	-- Check for child bounding box changes
	--[[local childBboxChanged = false
	self:eachVisible(function(child, i)
		local oldBbox = childBboxes[i]
		if oldBbox == nil or oldBbox ~= child.bbox then
			-- Bounding box changed, repaint child and container
			child:markRepaint()
			self:markRepaint()
		end
	end)]]--
end

-- Exports
return FlowContainer