--[[

	Common utilities
	Program base

--]]

program = {
	directory = shell.resolve("/"..shell.getRunningProgram().."/..")
}

function program.load(...)
	for i,relativePath in ipairs({...}) do
		local currentDir = program.directory
		local filePath = fs.combine(currentDir, relativePath..".lua")
		local fileDir = shell.resolve("/"..filePath.."/..")

		program.directory = fileDir
		dofile(filePath)
		program.directory = currentDir
	end
end