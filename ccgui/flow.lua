--[[

	ComputerCraft GUI
	Flow container

--]]

ccgui = ccgui or {}

local FlowContainer = common.newClass({
	-- Orientation
	horizontal = false,
	-- Spacing between children
	spacing = 0
}, ccgui.Container)
ccgui.FlowContainer = FlowContainer

function FlowContainer:init()
	ccgui.Container.init(self)

	-- Orientation
	self.horizontal = not not self.horizontal
end

function FlowContainer:calcSize(size)
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
	self:eachVisible(function(child, i, isLast)
		-- No spacing on last child
		local spacing = (not isLast and self.spacing) or 0
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
		child:calcSize(ccgui.Rectangle:new{
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
		child:calcSize(ccgui.Rectangle:new{
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
	self:eachVisible(function(child, i)
		child.size[fixedDim] = maxFixed
	end)

	-- Get children size box
	local bbox = ccgui.Rectangle:new{
		[flowDim] = flowSize,
		[fixedDim] = maxFixed
	}
	-- Use outer size box
	self.size = self:outer(bbox)
end

function FlowContainer:calcLayout(bbox)
	-- Get inner box for children bounding box
	local cbox = self:inner(bbox)

	-- Collect old child bounding boxes
	local childBboxes = {}
	self:eachVisible(function(child, i)
		childBboxes[i] = child.bbox
	end)

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
	self:eachVisible(function(child, i, isLast)
		local spacing = (not isLast and self.spacing) or 0
		-- Get child bounding box
		child:calcLayout(ccgui.Rectangle:new{
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
			childBboxChanged = true
		end
	end)
	if childBboxChanged then
		self:markRepaint()
	end]]--

	-- Use given bounding box
	self.bbox = bbox
end