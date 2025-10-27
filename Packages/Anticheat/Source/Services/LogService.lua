--[[
	LogService - simple singleton responsible for choosing weather to render the logs for the anticheat or not
]]

local Package = script.Parent.Parent

local isVerbose = false

local LogService = {}

--[[
	Set verbocity of the anticheat, if set to true -> anticheat the will create logs.
]]
function LogService.SetVerbose(_: LogService, verbose: boolean)
	isVerbose = verbose
end

--[[
	Will create some sort of output -> the console.
]]
function LogService.Log(_: LogService, message: any)
	if isVerbose then
		warn(`[Dubit][AntiCheat]:`, message)
	end
end

function LogService.OnStart(self: LogService)
	Package.Events.SetVerbose.Event:ConnectParallel(function(verbose)
		self:SetVerbose(verbose)
	end)
end

export type LogService = typeof(LogService)

return LogService
