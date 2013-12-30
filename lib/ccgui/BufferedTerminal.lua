--[[

	ComputerCraft GUI
	Buffered terminal

	IBuffer API, by Symmetryc
	https://github.com/Symmetryc/Buffer

--]]

local Object	= require "objectlua.Object"
local Rectangle	= require "ccgui.geom.Rectangle"

local BufferedTerminal = {}
function BufferedTerminal.new(out, text, back, shift_x, shift_y)
	out = out or term
	text = text or colors.white
	back = back or colors.black
	shift_x = shift_x or 0
	shift_y = shift_y or 0
	act = {}
	cur_x, cur_y = 0, 0
	blink = false

	local result = {
		getBounds = function()
			local width, height = out.getSize()
			return Rectangle:new(1, 1, width, height)
		end,

		write = function(_str, _x, _y, _text, _back)
			local pos_x = _x or act.pos_x
			local pos_y = _y or act.pos_y
			local text = _text or act.text
			local back = _back or act.back
			local append = true
			if pos_x ~= act.pos_x or pos_y ~= act.pos_y then
				act[#act + 1] = {out.setCursorPos, pos_x, pos_y}
				append = false
			end
			if back ~= act.back then
				act[#act + 1] = {out.setBackgroundColor, back}
				act.back = back
				append = false
			end
			if text ~= act.text then
				act[#act + 1] = {out.setTextColor, text}
				act.text = text
				append = false
			end
			if #act == 0 then
				append = false
			end
			for line, nl in _str:gmatch("([^\n]*)(\n?)") do
				if append then
					act[#act][2] = act[#act][2]..line
					append = false
				else
					act[#act + 1] = {out.write, line}
				end
				if nl == "\n" then
					pos_y = pos_y + 1
					act[#act + 1] = {out.setCursorPos, pos_x, pos_y}
				else
					pos_x = pos_x + #line
				end
			end
			act.pos_x, act.pos_y = pos_x, pox_y
			return self
		end,

		setCursorPos = function(_x, _y)
			cur_x, act.pos_x = _x, _x
			cur_y, act.pos_y = _y, _y
			out.setCursorPos(_x, _y)
		end,

		setTextColor = function(_text)
			act.text = _text
			out.setTextColor(act.text)
		end,

		setBackgroundColor = function(_back)
			act.back = _back
			out.setBackgroundColor(act.back)
		end,

		setCursorBlink = function(_blink)
			blink = _blink
			out.setCursorBlink(blink)
		end,

		clear = function()
			out.setBackgroundColor(back)
			out.clear()
			act = {}
			act.back = back
		end,

		draw = function()
			out.setCursorBlink(false)
			for i, v in ipairs(act) do
				if v[3] then
					v[1](v[2] + shift_x, v[3] + shift_y)
				else
					v[1](v[2])
				end
			end
			act = {}
			out.setCursorPos(cur_x, cur_y)
			out.setCursorBlink(blink)
		end
	}
	result.setTextColour = result.setTextColor
	result.setBackgroundColour = result.setBackgroundColor

	-- Delegate unimplemented functions to output
	for k,v in pairs(out) do
		if result[k] == nil and type(v) == "function" then
			result[k] = v
		end
	end
	
	return result
end

-- Exports
_G.ccgui.BufferedTerminal = BufferedTerminal
return BufferedTerminal