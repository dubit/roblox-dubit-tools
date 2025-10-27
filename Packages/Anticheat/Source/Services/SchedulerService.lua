--[[
	SchedulerService is responsible for handling the core loop for all Nodes/Detections from within the anticheat.

	All anticheat detection/nodes require a loop of some sorts, and so the SchedulerService provides this, as well
		as handling their states, for example - if you don't want AntiSpeed to run - disable it's loop.
]]

local RunService = game:GetService("RunService")

local Package = script.Parent.Parent

local FlagService = require(Package.Services.FlagService)
local LogService = require(Package.Services.LogService)

local isRunning: boolean = false
local schedulerFunctions: { ScheduledFunction } = {}
local heartbeatConnection: RBXScriptConnection?

local SchedulerService = {}

--[[
	Heartbeat is responsible for calling all of the looped functions within the anticheat, when this is called - all 
		loops that can be invoked will be. 

	It's the primary method for handling the loops.
]]
function SchedulerService.Heartbeat(_: SchedulerService, deltaTime: number)
	local timenow = workspace:GetServerTimeNow()

	for _, scheduledFunction in schedulerFunctions do
		if scheduledFunction.timeSinceLastCall then
			if timenow - scheduledFunction.timeSinceLastCall > scheduledFunction.delay then
				scheduledFunction.callback(deltaTime)

				scheduledFunction.timeSinceLastCall = timenow
			end
		else
			scheduledFunction.callback(deltaTime)

			scheduledFunction.timeSinceLastCall = timenow
		end
	end
end

--[[
	Spawn creates a new thread `heartbeat` connection which is responsible for calling the `:Heartbeat` method
]]
function SchedulerService.Spawn(self: SchedulerService)
	local deltaTime = 0

	heartbeatConnection = RunService.Heartbeat:ConnectParallel(function(delta)
		deltaTime += delta

		if isRunning then
			return
		end

		self:Heartbeat(deltaTime)

		deltaTime = 0
	end)
end

--[[
	Create, creates a loop that is called by the `:Heartbeat` method whenever it's next able to.
]]
function SchedulerService.Create(_: SchedulerService, callback: (deltaTime: number) -> (), delay: number?)
	local anticheatTickSpeed = FlagService:GetFlag("SchedulerTick")

	table.insert(schedulerFunctions, {
		callback = callback,
		delay = delay or anticheatTickSpeed,
	})
end

--[[
	Resume is responsible for starting the scheduler after it's been paused.
]]
function SchedulerService.Resume(self: SchedulerService)
	assert(heartbeatConnection == nil, `Attempted to resume scheduler when scheduler is active!`)

	LogService:Log(`Resuming anti-cheat scheduler, expect all nodes to start up again`)

	self:Spawn()
end

--[[
	Pause is responsible for stopping the scheduler, and by consequence disabling all nodes within the anticheat
]]
function SchedulerService.Pause(_: SchedulerService)
	assert(heartbeatConnection ~= nil, `Attempted to pause scheduler when scheduler is not active!`)

	LogService:Log(`Pausing anti-cheat scheduler, expect all nodes to be disabled`)

	task.synchronize()

	heartbeatConnection:Disconnect()
	heartbeatConnection = nil

	task.desynchronize()
end

function SchedulerService.OnStart(self: SchedulerService)
	self:Spawn()
end

export type SchedulerService = typeof(SchedulerService)
export type ScheduledFunction = {
	callback: (deltaTime: number) -> (),
	delay: number,
	timeSinceLastCall: number?,
}

return SchedulerService
