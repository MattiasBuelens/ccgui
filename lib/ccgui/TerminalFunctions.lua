--[[

	ComputerCraft GUI
	Terminal element

--]]

local Object			= require "objectlua.Object"
local BufferedScreen	= require "ccgui.paint.BufferedScreen"

local TerminalFunctions = Object:subclass("ccgui.TerminalFunctions")
function TerminalFunctions:initialize(term, parentEnv)
	super.initialize(self)

	term.native = term
	local env = {
		term = term
	}
	env._G = env
	setmetatable(env, { __index = parentEnv })
	self.env = env

	self:envIO()
	self:envOS()
	self:loadAPIs()
end

function TerminalFunctions:envIO()
	local env = self.env
	local term = env.term

	local function write( sText )
		local w,h = term.getSize()		
		local x,y = term.getCursorPos()
		
		local nLinesPrinted = 0
		local function newLine()
			if y + 1 <= h then
				term.setCursorPos(1, y + 1)
			else
				term.setCursorPos(1, h)
				term.scroll(1)
			end
			x, y = term.getCursorPos()
			nLinesPrinted = nLinesPrinted + 1
		end
		
		-- Print the line with proper word wrapping
		while string.len(sText) > 0 do
			local whitespace = string.match( sText, "^[ \t]+" )
			if whitespace then
				-- Print whitespace
				term.write( whitespace )
				x,y = term.getCursorPos()
				sText = string.sub( sText, string.len(whitespace) + 1 )
			end
			
			local newline = string.match( sText, "^\n" )
			if newline then
				-- Print newlines
				newLine()
				sText = string.sub( sText, 2 )
			end
			
			local text = string.match( sText, "^[^ \t\n]+" )
			if text then
				sText = string.sub( sText, string.len(text) + 1 )
				if string.len(text) > w then
					-- Print a multiline word				
					while string.len( text ) > 0 do
						if x > w then
							newLine()
						end
						term.write( text )
						text = string.sub( text, (w-x) + 2 )
						x,y = term.getCursorPos()
					end
				else
					-- Print a word normally
					if x + string.len(text) - 1 > w then
						newLine()
					end
					term.write( text )
					x,y = term.getCursorPos()
				end
			end
		end
		
		return nLinesPrinted
	end

	local function print( ... )
		local nLinesPrinted = 0
		for n,v in ipairs( { ... } ) do
			nLinesPrinted = nLinesPrinted + write( tostring( v ) )
		end
		nLinesPrinted = nLinesPrinted + write( "\n" )
		return nLinesPrinted
	end

	local function printError( ... )
		if term.isColour() then
			term.setTextColour( colours.red )
		end
		print( ... )
		term.setTextColour( colours.white )
	end

	local function read( _sReplaceChar, _tHistory )
		term.setCursorBlink( true )

		local sLine = ""
		local nHistoryPos = nil
		local nPos = 0
		if _sReplaceChar then
			_sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
		end
		
		local w, h = term.getSize()
		local sx, sy = term.getCursorPos()	
		
		local function redraw( _sCustomReplaceChar )
			local nScroll = 0
			if sx + nPos >= w then
				nScroll = (sx + nPos) - w
			end
				
			term.setCursorPos( sx, sy )
			local sReplace = _sCustomReplaceChar or _sReplaceChar
			if sReplace then
				term.write( string.rep( sReplace, string.len(sLine) - nScroll ) )
			else
				term.write( string.sub( sLine, nScroll + 1 ) )
			end
			term.setCursorPos( sx + nPos - nScroll, sy )
		end
		
		while true do
			local sEvent, param = os.pullEvent()
			if sEvent == "char" then
				sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
				nPos = nPos + 1
				redraw()
				
			elseif sEvent == "key" then
				if param == keys.enter then
					-- Enter
					break
					
				elseif param == keys.left then
					-- Left
					if nPos > 0 then
						nPos = nPos - 1
						redraw()
					end
					
				elseif param == keys.right then
					-- Right				
					if nPos < string.len(sLine) then
						redraw(" ")
						nPos = nPos + 1
						redraw()
					end
				
				elseif param == keys.up or param == keys.down then
					-- Up or down
					if _tHistory then
						redraw(" ")
						if param == keys.up then
							-- Up
							if nHistoryPos == nil then
								if #_tHistory > 0 then
									nHistoryPos = #_tHistory
								end
							elseif nHistoryPos > 1 then
								nHistoryPos = nHistoryPos - 1
							end
						else
							-- Down
							if nHistoryPos == #_tHistory then
								nHistoryPos = nil
							elseif nHistoryPos ~= nil then
								nHistoryPos = nHistoryPos + 1
							end						
						end
						if nHistoryPos then
							sLine = _tHistory[nHistoryPos]
							nPos = string.len( sLine ) 
						else
							sLine = ""
							nPos = 0
						end
						redraw()
					end
				elseif param == keys.backspace then
					-- Backspace
					if nPos > 0 then
						redraw(" ")
						sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
						nPos = nPos - 1					
						redraw()
					end
				elseif param == keys.home then
					-- Home
					redraw(" ")
					nPos = 0
					redraw()		
				elseif param == keys.delete then
					if nPos < string.len(sLine) then
						redraw(" ")
						sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )				
						redraw()
					end
				elseif param == keys["end"] then
					-- End
					redraw(" ")
					nPos = string.len(sLine)
					redraw()
				end
			end
		end
		
		term.setCursorBlink( false )
		term.setCursorPos( w + 1, sy )
		print()
		
		return sLine
	end
	
	-- Add to environment
	env.write		= write
	env.print		= print
	env.printError	= printError
	env.read		= read
end

function TerminalFunctions:envOS()
	local env = self.env
	local _os, os = os, {}

	-- Add to environment
	env.os = os
	-- Delegate to original OS
	setmetatable(os, { __index = _os })

	setfenv(1, env)

	-- Install the rest of the OS api
	function os.run( _tEnv, _sPath, ... )
		local tArgs = { ... }
		local fnFile, err = loadfile( _sPath )
		if fnFile then
			local tEnv = _tEnv
			--setmetatable( tEnv, { __index = function(t,k) return _G[k] end } )
			setmetatable( tEnv, { __index = _G } )
			setfenv( fnFile, tEnv )
			local ok, err = pcall( function()
				fnFile( unpack( tArgs ) )
			end )
			if not ok then
				if err and err ~= "" then
					printError( err )
				end
				return false
			end
			return true
		end
		if err and err ~= "" then
			printError( err )
		end
		return false
	end

	local tAPIsLoading = {}
	function os.loadAPI( _sPath )
		local sName = fs.getName( _sPath )
		if tAPIsLoading[sName] == true then
			printError( "API "..sName.." is already being loaded" )
			return false
		end
		tAPIsLoading[sName] = true
			
		local tEnv = {}
		setmetatable( tEnv, { __index = _G } )
		local fnAPI, err = loadfile( _sPath )
		if fnAPI then
			setfenv( fnAPI, tEnv )
			fnAPI()
		else
			printError( err )
			tAPIsLoading[sName] = nil
			return false
		end
		
		local tAPI = {}
		for k,v in pairs( tEnv ) do
			tAPI[k] =  v
		end
		
		_G[sName] = tAPI	
		tAPIsLoading[sName] = nil
		return true
	end
end

function TerminalFunctions:loadAPIs()
	setfenv(1, self.env)

	-- Load APIs
	local tApis = fs.list( "rom/apis" )
	for n,sFile in ipairs( tApis ) do
		if string.sub( sFile, 1, 1 ) ~= "." then
			local sPath = fs.combine( "rom/apis", sFile )
			if not fs.isDir( sPath ) then
				os.loadAPI( sPath )
			end
		end
	end

	if turtle then
		local tApis = fs.list( "rom/apis/turtle" )
		for n,sFile in ipairs( tApis ) do
			if string.sub( sFile, 1, 1 ) ~= "." then
				local sPath = fs.combine( "rom/apis/turtle", sFile )
				if not fs.isDir( sPath ) then
					os.loadAPI( sPath )
				end
			end
		end
	end
end

return TerminalFunctions