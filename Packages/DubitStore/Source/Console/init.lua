--[[
	Roblox Console - small module to wrap all reporters created by the Console lib
]]
--

local ConsoleLib = require(script.Parent.Parent.Console)

local Console = {}

Console.reporters = {}
Console.interface = {}

Console.logLevel = ConsoleLib.LogLevel.Warn

--[[
	Set the log level for all DubitStore reporters
]]
--
function Console.interface:SetLogLevel(logLevel)
	Console.logLevel = logLevel

	for _, object in Console.reporters do
		object.reporter:SetLogLevel(Console.logLevel)
	end
end

--[[
	Generates a new Reporter object that can be used to log/output to the console.
]]
--
function Console.interface:CreateReporter(reporterName)
	local reporterObject = ConsoleLib.new(reporterName)

	table.insert(Console.reporters, {
		name = reporterName,
		reporter = reporterObject,
	})

	reporterObject:SetLogLevel(Console.logLevel)

	return reporterObject
end

return Console.interface :: typeof(Console.interface)
