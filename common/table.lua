--[[

	Common utilities
	Table functions

--]]

common = common or {}

function common.find(haystack, needle)
	assert(type(haystack) == "table", "invalid haystack")

	for k, v in ipairs(haystack) do
		if v == needle then
			return k
		end
	end

	return nil
end

function common.ifind(haystack, needle)
	assert(type(haystack) == "table", "invalid haystack")

	for i, v in ipairs(haystack) do
		if v == needle then
			return i
		end
	end

	return nil
end

function common.clear(t)
	assert(type(t) == "table", "invalid table")

	for k in pairs(t) do
		t[k] = nil
	end
end

function common.clone(t)
	if type(t) ~= "table" then
		return t
	end

	local c = { }
	for k, v in pairs(t) do
		c[k] = v
	end

	return setmetatable(c, getmetatable(t))
end

function common.serialize(t)
	return textutils.serialize(t)
end

function common.getKeys(src)
	local out = {}
	for key in pairs(src) do
		table.insert(out, key)
	end
	return out
end

function common.getValues(src)
	local out = {}
	for _, value in pairs(src) do
		table.insert(out, value)
	end
	return out
end

function common.combine(keys, values)
	assert(type(keys) == "table", "invalid keys table")
	local out = {}
	if type(values) == "table" then
		-- Match keys with values
		for i, key in ipairs(keys) do
			out[key] = values[i]
		end
	else
		-- Single value for all keys
		for i, key in ipairs(keys) do
			out[key] = values
		end
	end
	return out
end

-- Randomly shuffle a list using the Fisher-Yates shuffle
--
-- Adapted from Wikipedia
-- http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_.22inside-out.22_algorithm
function common.shuffle(src)
	assert(type(src) == "table", "invalid source")
	local out = { src[1] }
	local j
	for i = 2, #src do
		j = math.random(i) -- 1 <= j <= i
		out[i] = out[j]
		out[j] = src[i]
	end
	return out
end

-- Randomly cycle a list using Sattolo's algorithm
--
-- This differs from shuffling the list because
-- no element can ever end up on its original position
function common.randomCycle(src)
	assert(type(src) == "table", "invalid source")
	local out = { src[1] }
	local j
	for i = 2, #src do
		j = math.random(i-1) -- 1 <= j <= i-1
		out[i] = out[j]
		out[j] = src[i]
	end
	return out
end