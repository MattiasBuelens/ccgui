--[[

	ComputerCraft GUI
	Grid container

--]]

local Object			= require "objectlua.Object"
local Container			= require "ccgui.Container"
local Rectangle			= require "ccgui.geom.Rectangle"
local DimensionSpec		= require "ccgui.DimensionSpec"
local MeasureSpec		= require "ccgui.MeasureSpec"

local GridSpec = Object:subclass("ccgui.grid.GridSpec")
function GridSpec:initialize(stretch)
	super.initialize(self)
	
	-- Stretch factor
	self.stretch = not not stretch
end

local GridContainer = Container:subclass("ccgui.GridContainer")
function GridContainer:initialize(opts)
	super.initialize(self, opts)
	-- Orientation
	self.horizontal = not not opts.horizontal
	-- Row and column specifications
	self.rowSpecs = opts.rowSpecs or {}
	self.colSpecs = opts.colSpecs or {}
	-- Spacing between rows and columns
	self.rowSpacing = opts.rowSpacing or 0
	self.colSpacing = opts.colSpacing or 0
	-- Primary and secondary sizes (calculated in measure)
	self.primSizes = {}
	self.secSizes = {}
end
GridContainer.class.GridSpec = GridSpec

function GridContainer:getRows()
	local rows = {}
	for r=1,#self.rowSpecs do
		rows[r] = {}
		for c=1,#self.colSpecs do
			rows[r][c] = false
		end
	end
	self:each(function(child)
		if child.visible then
			local r, c = child.rowIndex or 1, child.colIndex or 1
			rows[r][c] = child
		end
	end)
	return rows
end
function GridContainer:getColumns()
	local cols = {}
	for c=1,#self.colSpecs do
		cols[c] = {}
		for r=1,#self.rowSpecs do
			cols[c][r] = false
		end
	end
	self:each(function(child)
		if child.visible then
			local r, c = child.rowIndex or 1, child.colIndex or 1
			cols[c][r] = child
		end
	end)
	return cols
end

function GridContainer:eachRow(func)
	self.class.forEach(self:getRows(), func)
end
function GridContainer:eachColumn(func)
	self.class.forEach(self:getColumns(), func)
end

function GridContainer:eachGroup(primary, func)
	if self.horizontal == (not not primary) then
		self:eachColumn(func)
	else
		self:eachRow(func)
	end
end
function GridContainer:getDimensions(primary)
	if self.horizontal == (not not primary) then
		return "w", "h", "x", "y"
	else
		return "h", "w", "y", "x"
	end
end
function GridContainer:getSpecs(primary)
	if self.horizontal == (not not primary) then
		return self.colSpecs
	else
		return self.rowSpecs
	end
end
function GridContainer:getSpacing(primary)
	if self.horizontal == (not not primary) then
		return self.colSpacing
	else
		return self.rowSpacing
	end
end

function GridContainer:measure(spec)
	-- Get inner spec
	spec = self:inner(spec)
	
	-- First pass: flow primary
	local primSizes = self:gridMeasureFlow(true, spec)
	-- Second pass: flow secondary with fixed primary
	local secSizes = self:gridMeasureFlow(false, spec, primSizes)
	-- Third pass: all fixed
	local flowSize, fixSize = self:gridMeasureExact(primSizes, secSizes)
	
	-- Store sizes for layout
	self.primSizes, self.secSizes = primSizes, secSizes
	
	-- Force exact sizes
	local flowDim, fixDim = self:getDimensions(true)
	if spec[flowDim]:isExact() then
		flowSize = math.max(flowSize, spec[flowDim].value)
	end
	if spec[fixDim]:isExact() then
		fixSize = math.max(fixSize, spec[fixDim].value)
	end
	
	-- Set size
	local size = Rectangle:new{
		[flowDim] = flowSize,
		[fixDim] = fixSize
	}
	self.size = self:outer(size)
end

--[[

	Measure grid with flow in primary or secondary direction

]]--
function GridContainer:gridMeasureFlow(primary, spec, fixSizes)
	local flowDim, fixDim = self:getDimensions(primary)
	local gridSpecs = self:getSpecs(primary)
	local flowSpacing = self:getSpacing(primary)
	local flowSpec, fixSpec = spec[flowDim], spec[fixDim]
	
	local remainingSpec = self:makeRemaining(flowSpec)
	local groupSizes = {}
	local stretchGroups = {}
	local stretchTotal = 0
	
	-- Measure groups
	self:eachGroup(primary, function(group, i, n)
		-- Remove spacing
		local spacing = (i < n and flowSpacing) or 0
		remainingSpec = remainingSpec - spacing
		
		-- Handle stretched groups later
		local gridSpec = gridSpecs[i]
		if flowSpec:isExact() and gridSpec.stretch then
			-- Add to stretch total
			local stretchFactor = (type(gridSpec.stretch) == "number" and gridSpec.stretch or 1)
			stretchTotal = stretchTotal + stretchFactor
			-- Add to stretched groups
			stretchGroups[i] = group
			return
		end
		
		-- Measure group
		local groupFlow, groupFix = self:gridMeasureGroup(group, primary, remainingSpec, fixSpec, fixSizes)
		
		-- Set group size
		groupSizes[i] = groupFlow
		-- Update remaining size
		remainingSpec = remainingSpec - groupFlow
	end)
	
	-- Stretch groups
	local remaining = remainingSpec.value
	local stretchUnit = math.floor(remaining / stretchTotal)
	local stretchExtra = remaining % stretchTotal
	for i,group in pairs(stretchGroups) do
		local gridSpec = gridSpecs[i]
		local stretchFactor = (type(gridSpec.stretch) == "number" and gridSpec.stretch or 1)
		local groupSize = stretchUnit * stretchFactor + (i == 1 and stretchExtra or 0)
		local groupFlowSpec = DimensionSpec:new("=", groupSize)
		
		-- Measure group
		self:gridMeasureGroup(group, primary, groupFlowSpec, fixSpec, fixSizes)
		
		-- Set group size
		groupSizes[i] = groupSize
	end
	
	return groupSizes
end

--[[

	Measure grid with exact sizes

]]--
function GridContainer:gridMeasureExact(primSizes, secSizes)
	local flowDim, fixDim = self:getDimensions(true)
	local flowSpacing = self:getSpacing(true)
	local flowSize, fixSize = 0, 0
	
	-- Measure groups
	self:eachGroup(true, function(group, i, n)
		local spacing = (i < n and flowSpacing) or 0
		local flowSpec = DimensionSpec:new("=", primSizes[i])
		-- Measure group
		local groupFlow, groupFix = self:gridMeasureGroupExact(group, true, flowSpec, secSizes)
		-- Update sizes
		flowSize = flowSize + groupFlow + spacing
		fixSize = math.max(fixSize, groupFix)
	end)
	
	return flowSize, fixSize
end

--[[

	Measure group

]]--
function GridContainer:gridMeasureGroup(group, primary, flowSpec, fixSpec, fixSizes)
	if fixSizes then
		return self:gridMeasureGroupExact(group, primary, flowSpec, fixSizes)
	else
		return self:gridMeasureGroupSpec(group, primary, flowSpec, fixSpec)
	end
end

--[[

	Measure group with fixed dimension specification (first pass)

]]--
function GridContainer:gridMeasureGroupSpec(group, primary, flowSpec, fixSpec)
	local flowDim, fixDim = self:getDimensions(primary)
	local fixSpacing = self:getSpacing(not primary)
	local fixSpecs = self:getSpecs(not primary)
	
	local remainingSpec = self:makeRemaining(fixSpec)
	local maxFlow, totalFix = 0, 0
	local stretchChildren = {}
	local stretchTotal = 0
	
	self.class.forEach(group, function(child, i, n)
		-- Remove spacing
		local spacing = (i < n and fixSpacing) or 0
		totalFix = totalFix + spacing
		remainingSpec = remainingSpec - spacing
		if not child then return end
		-- Handle stretched children later
		local gridSpec = fixSpecs[i]
		if gridSpec.stretch then
			-- Add to stretch total
			local stretchFactor = (type(gridSpec.stretch) == "number" and gridSpec.stretch or 1)
			stretchTotal = stretchTotal + stretchFactor
			-- Add to stretched children
			stretchChildren[i] = child
			return
		end
		-- Measure child
		child:measure(MeasureSpec:new{
			[flowDim] = flowSpec,
			[fixDim] = remainingSpec
		})
		-- Remove child size
		local childSize = child.size[fixDim]
		totalFix = totalFix + childSize
		remainingSpec = remainingSpec - childSize
		-- Update maximum flow size
		maxFlow = math.max(maxFlow, child.size[flowDim])
	end)
	
	-- Stretch children
	local remaining = remainingSpec.value
	local stretchUnit = math.floor(remaining / stretchTotal)
	local stretchExtra = remaining % stretchTotal
	for i,child in pairs(stretchChildren) do
		local gridSpec = fixSpecs[i]
		local stretchFactor = (type(gridSpec.stretch) == "number" and gridSpec.stretch or 1)
		local childSize = stretchUnit * stretchFactor + (i == 1 and stretchExtra or 0)
		-- Measure child
		child:measure(MeasureSpec:new{
			[flowDim] = flowSpec,
			[fixDim] = DimensionSpec:new("=", childSize)
		})
		-- Add child size to total fix
		totalFix = totalFix + childSize
		-- Update maximum flow size
		maxFlow = math.max(maxFlow, child.size[flowDim])
	end
	
	return maxFlow, totalFix
end

--[[

	Measure group with known exact sizes for fixed dimension (second pass)

]]--
function GridContainer:gridMeasureGroupExact(group, primary, flowSpec, fixSizes)
	local flowDim, fixDim = self:getDimensions(primary)
	local fixSpacing = self:getSpacing(not primary)

	local maxFlow, totalFix = 0, 0
	self.class.forEach(group, function(child, i, n)
		-- Remove spacing
		local spacing = (i < n and fixSpacing) or 0
		totalFix = totalFix + spacing
		if not child then return end
		-- Measure child
		child:measure(MeasureSpec:new{
			[flowDim] = flowSpec,
			[fixDim] = DimensionSpec:new("=", fixSizes[i])
		})
		-- Add child size to total fix
		local childSize = child.size[fixDim]
		totalFix = totalFix + childSize
		-- Update maximum flow size
		maxFlow = math.max(maxFlow, child.size[flowDim])
	end)
	
	return maxFlow, totalFix
end

function GridContainer:makeRemaining(dimSpec)
	-- Use at most specification for remaining
	return dimSpec:isExact() and DimensionSpec:new("<", dimSpec.value) or dimSpec
end

function GridContainer:layout(bbox)
	super.layout(self, bbox)

	-- Get inner box for children bounding box
	local cbox = self:inner(bbox)

	-- Dimensions and coordinates
	local primDim, secDim, primCoord, secCoord = self:getDimensions(true)
	local primSpacing, secSpacing = self:getSpacing(true), self:getSpacing(false)
	
	-- Update layout of children
	local secPos = cbox[secCoord]
	self:eachGroup(false, function(group, iGroup)
		local groupSize = self.secSizes[iGroup]
		-- Layout group
		local primPos = cbox[primCoord]
		self.class.forEach(group, function(child, iChild)
			local childSize = self.primSizes[iChild]
			-- Layout child
			if child then
				child:layout(Rectangle:new{
					[primCoord] = primPos,
					[secCoord] = secPos,
					[primDim] = childSize,
					[secDim] = groupSize
				})
			end
			primPos = primPos + childSize + primSpacing
		end)
		secPos = secPos + groupSize + secSpacing
	end)
end

-- Exports
return GridContainer