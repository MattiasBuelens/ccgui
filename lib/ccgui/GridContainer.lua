--[[

	ComputerCraft GUI
	Grid container

--]]

local Container			= require "ccgui.Container"
local Rectangle			= require "ccgui.geom.Rectangle"
local DimensionSpec		= require "ccgui.DimensionSpec"
local MeasureSpec		= require "ccgui.MeasureSpec"

local GridContainer = Container:subclass("ccgui.GridContainer")
function GridContainer:initialize(opts)
	super.initialize(self, opts)
	-- Orientation
	self.horizontal = not not opts.horizontal
	-- Spacing between rows and columns
	self.rowSpacing = opts.rowSpacing or 0
	self.columnSpacing = opts.columnSpacing or 0
	-- Cells
	self.cells = {}
	
	self:on("add", self.gridCellAdd, self)
	self:on("remove", self.gridCellRemove, self)
end

function GridContainer:gridCellAdd(child)
	-- Update indices
	local r, c = child.rowIndex or (#self.cells + 1), child.columnIndex or 1
	child.rowIndex, child.columnIndex = r, c
	-- Update cells
	local row = self.cells[r] or {}
	assert(row[c] == nil, "cannot place two elements in same cell at "..r..","..c)
	row[c] = child
	self.cells[r] = row
end
function GridContainer:gridCellRemove(child)
	local r, c = child.rowIndex, child.columnIndex
	local row = self.cells[r]
	if row and row[c] == child then
		-- Remove in row
		row[c] = nil
		-- Remove row when empty
		if next(row) == nil then
			self.cells[r] = nil
		end
	end
end

function GridContainer:getFlowFixedDims()
	if self.horizontal then
		return "w", "h", "x", "y"
	else
		return "h", "w", "y", "x"
	end
end

function GridContainer:measure(spec)
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

function GridContainer:measureUnspecified(spec)
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
		-- Ignore absolutely positioned children
		if child.absolute then return end
		-- Update flow size
		local childSize = child.size[flowDim] + spacing
		flowSize = flowSize + childSize
		-- Update fixed size
		fixedSize = math.max(fixedSize, child.size[fixedDim])
	end)
	
	return flowSize, fixedSize
end

function GridContainer:measureSpecified(spec, isExact)
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
		if isExact and child.stretch then
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
	if isExact then
		flowSize = math.max(flowSize, spec[flowDim].value)
	end
	
	return flowSize, fixedSize
end

function GridContainer:forceFixedSize(fixedSize)
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

function GridContainer:layout(bbox)
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
		-- Layout child
		child:layout(Rectangle:new{
			[flowCoord] = flowPos,
			[fixedCoord] = fixedPos,
			[flowDim] = child.size[flowDim],
			[fixedDim] = fixedSize
		})
		-- Force size
		-- Add child size and spacing to flow position
		local childSize = child.bbox[flowDim] + spacing
		flowPos = flowPos + childSize
	end)
end

-- Exports
return GridContainer