--[[

	ComputerCraft GUI
	Flow container

--]]

local Container			= require "ccgui.Container"
local Rectangle			= require "ccgui.geom.Rectangle"
local DimensionSpec		= require "ccgui.DimensionSpec"
local MeasureSpec		= require "ccgui.MeasureSpec"

local FlowContainer = Container:subclass("ccgui.FlowContainer")
function FlowContainer:initialize(opts)
	super.initialize(self, opts)
	-- Orientation
	self.horizontal = not not opts.horizontal
	-- Spacing between children
	self.spacing = opts.spacing or 0
end

function FlowContainer:getFlowFixedDims()
	if self.horizontal then
		return "w", "h", "x", "y"
	else
		return "h", "w", "y", "x"
	end
end

function FlowContainer:measure(spec)
	-- Get inner spec
	spec = self:inner(spec)
	
	-- Dimensions
	local flowDim, fixedDim = self:getFlowFixedDims()
	-- Flow specification
	local flowSpec = spec[flowDim]
	-- Sizes
	local flowSize, fixedSize = 0, 0

	-- Measure
	if flowSpec:isUnspecified() then
		flowSize, fixedSize = self:measureUnspecified(spec)
	else
		flowSize, fixedSize = self:measureSpecified(spec, flowSpec:isExact())
	end
	
	-- Force fixed size
	self:forceFixedSize(fixedSize)
	
	-- Set size
	local size = Rectangle:new{
		[flowDim] = flowSize,
		[fixedDim] = fixedSize
	}
	self.size = self:outer(size)
end

function FlowContainer:measureUnspecified(spec)
	-- Dimensions
	local flowDim, fixedDim = self:getFlowFixedDims()
	-- Sizes
	local flowSize, fixedSize = 0, 0
	
	-- Measure all children with unspecified spec
	self:eachVisible(function(child, i, n)
		-- No spacing on last child
		local spacing = (i < n and self.spacing) or 0
		-- Measure child
		child:measure(spec)
		-- Update flow size
		local childSize = child.size[flowDim] + spacing
		flowSize = flowSize + childSize
		-- Update fixed size
		fixedSize = math.max(fixedSize, child.size[fixedDim])
	end)
	
	return flowSize, fixedSize
end

function FlowContainer:measureSpecified(spec, isExact)
	-- Dimensions
	local flowDim, fixedDim = self:getFlowFixedDims()
	-- Sizes
	local flowSize, fixedSize = 0, 0
	
	-- Flow specification: at most
	local remainingSpec = DimensionSpec:new("<", spec[flowDim].value)
	-- Fixed specification: inherit
	local fixedSpec = spec[fixedDim]
	
	-- Children to be stretched
	local stretchChildren = {}
	
	-- Measure children with decreasing spec
	self:eachVisible(function(child, i, n)
		-- No spacing on last child
		local spacing = (i < n and self.spacing) or 0
		-- Handle absolutely positioned children
		if child.absolute then
			-- Can occupy whole inner box
			child:measure(spec)
			return
		end
		-- Handle stretched children later
		if isExact and child.stretch then
			-- Remove spacing from remaining
			-- and add to flow size
			flowSize = flowSize + spacing
			remainingSpec = remainingSpec - spacing
			-- Add to stretched children
			table.insert(stretchChildren, child)
			return
		end
		-- Get child size
		child:measure(MeasureSpec:new{
			[flowDim] = remainingSpec,
			[fixedDim] = fixedSpec
		})
		-- Remove child size and spacing from remaining
		-- and add to flow size
		local childSize = child.size[flowDim] + spacing
		flowSize = flowSize + childSize
		remainingSpec = remainingSpec - childSize
		-- Update maximum fixed size
		fixedSize = math.max(fixedSize, child.size[fixedDim])
	end)

	-- Divide remaining size over stretched children
	local remaining = remainingSpec.value
	local stretchSize = math.floor(remaining / #stretchChildren)
	local firstStretch = stretchSize + (remaining % #stretchChildren)
	for i,child in ipairs(stretchChildren) do
		local childSize = (i == 1 and firstStretch) or stretchSize
		-- Measure child
		child:measure(MeasureSpec:new{
			[flowDim] = DimensionSpec:new("=", childSize),
			[fixedDim] = fixedSpec
		})
		-- Update size
		flowSize = flowSize + childSize
		fixedSize = math.max(fixedSize, child.size[fixedDim])
	end
	
	-- Force exact flow size
	if isExact then
		flowSize = math.max(flowSize, spec[flowDim].value)
	end
	
	return flowSize, fixedSize
end

function FlowContainer:forceFixedSize(fixedSize)
	-- Dimensions
	local flowDim, fixedDim = self:getFlowFixedDims()
	
	-- Make fixed dimension exact
	local fixedSpec = DimensionSpec:new("=", fixedSize)
	self:eachVisible(function(child)
		-- Ignore absolutely positioned children
		if child.absolute then return end
		-- Force fixed size
		child:measure(MeasureSpec:new{
			[flowDim] = DimensionSpec:new("=", child.size[flowDim]),
			[fixedDim] = fixedSpec
		})
	end)
end

function FlowContainer:layout(bbox)
	super.layout(self, bbox)

	-- Get inner box for children bounding box
	local cbox = self:inner(bbox)

	-- Dimensions and coordinates
	local flowDim, fixedDim, flowCoord, fixedCoord = self:getFlowFixedDims()
	-- Flow position
	local flowPos = cbox[flowCoord]
	-- Fixed position and size
	local fixedPos, fixedSize = cbox[fixedCoord], cbox[fixedDim]

	-- Update layout of children
	self:eachVisible(function(child, i, n)
		local spacing = (i < n and self.spacing) or 0
		-- Handle absolutely positioned children
		if child.absolute then
			-- Position in top left corner
			child:layout(Rectangle:new(cbox:tl(), child.size:size()))
			return
		end
		-- Get child bounding box
		child:layout(Rectangle:new{
			[flowCoord] = flowPos,
			[fixedCoord] = fixedPos,
			[flowDim] = child.size[flowDim],
			[fixedDim] = fixedSize
		})
		-- Force size
		--child.bbox[flowDim] = child.size[flowDim]
		--child.bbox[fixedDim] = fixedSize
		-- Add child size and spacing to flow position
		local childSize = child.bbox[flowDim] + spacing
		flowPos = flowPos + childSize
	end)
end

-- Exports
return FlowContainer