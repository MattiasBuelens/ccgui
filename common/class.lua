--[[

	Common utilities
	Classes

--]]

common = common or {}

-- Lookup in list of tables
local function search(k, plist)
	for i=1, table.getn(plist) do
		local v = plist[i][k]
		if v ~= nil then return v end
	end
end

-- Define class with multiple inheritance
function common.newClass(...)
	local c = {}
	local parents = { ... }

	-- Class searches for each method
	-- in the list of its parents
	setmetatable(c, {
		__index = function(t, k)
			return search(k, parents)
		end
	})

	-- Prepare 'c' to be the metatable of its instances
	c.__index = c

	-- Define constructor for this new class
	function c:new(o)
		o = o or {}
		setmetatable(o, c)
		
		-- Call constructor
		if o.init then o:init() end

		return o
	end

	-- Return new class
	return c
end