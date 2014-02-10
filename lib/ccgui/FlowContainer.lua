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
	-- Specifications
	local flowSpec, fixedSpec = spec[flowDim], spec[fixedDim]
	
	-- Use at most specification for remaining
	local remainingSpec = self:makeRemaining(flowSpec)
	
	-- Sizes
	local flowSize, fixedSize = 0, 0
	-- Children to be stretched
	local stretchChildren = {}
	-- Total of stretch factors
	local stretchTotal = 0
	
	-- Measure children with decreasing spec
	self:eachVisible(function(child, i, n)
		-- Handle absolutely positioned children
		if child.absolute then
			-- Can occupy whole inner box
			child:measure(spec)
			return
		end
		-- No spacing on last child
		local spacing = (i < n and self.spacing) or 0
		-- Remove spacing
		flowSize = flowSize + spacing
		remainingSpec = remainingSpec - spacing
		-- Handle stretched children later
		if flowSpec:isExact() and child.stretch then
			-- Add to stretch total
			local stretchFactor = (type(child.stretch) == "number" and child.stretch or 1)
			stretchTotal = stretchTotal + stretchFactor
			-- Add to stretched children
			table.insert(stretchChildren, child)
			return
		end
		-- Measure child
		child:measure(MeasureSpec:new{
			[flowDim] = remainingSpec,
			[fixedDim] = fixedSpec
		})
		-- Remove child size
		local childSize = child.size[flowDim]
		flowSize = flowSize + childSize
		remainingSpec = remainingSpec - childSize
		-- Update maximum fixed size
		fixedSize = math.max(fixedSize, child.size[fixedDim])
	end)

	-- Divide remaining size over stretched children
	local remaining = remainingSpec.value
	local stretchUnit = math.floor(remaining / stretchTotal)
	local stretchExtra = remaining % stretchTotal
	for i,child in ipairs(stretchChildren) do
		local stretchFactor = (type(child.stretch) == "number" and child.stretch or 1)
		local childSize = stretchUnit * stretchFactor + (i == 1 and stretchExtra or 0)
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
	if flowSpec:isExact() then
		flowSize = math.max(flowSize, flowSpec.value)
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

function FlowContainer:makeRemaining(dimSpec)
	-- Use at most specification for remaining
	return dimSpec:isExact() and DimensionSpec:new("<", dimSpec.value) or dimSpec
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
	self:eachVisible(function(child, i)
		-- Handle absolutely positioned children
		if child.absolute then
			-- Position in top left corner
			child:layout(Rectangle:new(cbox:tl(), child.size:size()))
			return
		end
		-- Layout child
		child:layout(Rectangle:new{
			[flowCoord] = flowPos,
			[fixedCoord] = fixedPos,
			[flowDim] = child.size[flowDim],
			[fixedDim] = fixedSize
		})
		-- Add child size and spacing to flow position
		flowPos = flowPos + child.bbox[flowDim] + self.spacing
	end)
end

-- Exports
return FlowContainer