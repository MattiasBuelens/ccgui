--[[

	ComputerCraft GUI
	Windows demonstration

--]]


local root = fs.combine(shell.getRunningProgram(), "../lib/")
dofile(fs.combine(root, "/compat.lua"))
package.root = root

local concurrent	= require "concurrent"

local s = concurrent.Scheduler:new()
-- Change text color
local tColor = concurrent.Thread:new(function()
	local tColorLookup = {}
	for n=1,16 do
		tColorLookup[string.sub("0123456789abcdef",n,n)] = bit.blshift(1, n-1) -- 2^(n-1)
	end
	while true do
		local event, char = os.pullEvent("char")
		local color = tColorLookup[char]
		if color then
			term.setTextColor(color)
		end
	end
end)
-- Read text
local tRead = concurrent.Thread:new(function()
	local str = read()
	return str
end)
-- Output text
local tWrite = concurrent.Thread:new(function()
	while true do
		tRead:start(s)
		local str = tRead:join()
		print("Read: "..str)
	end
end)
tColor:start(s)
tWrite:start(s)
s:run()
