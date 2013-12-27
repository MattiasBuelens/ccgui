--[[

	Common utilities
	String functions

--]]

common = common or {}

function common.startsWith(haystack, needle)
	return needle == "" or string.sub(haystack, 1, string.len(needle)) == needle
end

function common.endsWith(haystack, needle)
	return needle == "" or string.sub(haystack, -string.len(needle)) == needle
end