--[[

	Common utilities
	Persistent storage

--]]

common = common or {}

local Store = common.newClass({
	___path = nil,
	___data = nil,
	___defaults = nil
})
common.Store = Store

function common.newStore(path, defaults)
	assert(type(path) == "string", "path must be a string")
	return Store:new{
		___path = path,
		___data = {},
		___defaults = defaults or {}
	}
end

function common.loadStore(path, defaults)
	local store = common.newStore(path, defaults)
	store:load()
	return store:getAll()
end

function Store:get(key)
	local result = self.___data[key]
	if result == nil then
		result = self.___defaults[key]
	end
	return result
end

function Store:getAll()
	local t = {}
	for k,v in pairs(self.___defaults) do
		t[k] = v
	end
	for k,v in pairs(self.___data) do
		t[k] = v
	end
	return t
end

function Store:set(key, value)
	self.___data[key] = value
end

function Store:serialize()
	return textutils.serialize(self:getAll())
end

function Store:unserialize(data)
	self.___data = textutils.unserialize(data)
end

function Store:load()
	if not fs.exists(self.___path) then
		return false
	end

	-- Load from file
	local file = fs.open(self.___path, "r")
	if file == nil then
		return false
	end

	self:unserialize(file.readAll())
	file.close()
	return true
end

function Store:save()
	-- Make directory
	local dir = "/"..shell.resolve("/"..self.___path.."/..")
	if not (fs.exists(dir) and fs.isDir(dir)) then
		fs.makeDir(dir)
	end

	-- Write to file
	local file = fs.open(self.___path, "w")
	if file == nil then
		return false
	end

	file.write(self:serialize())
	file.close()
	return true
end