--[[
	FlagService is responsible for handling the default flag values/configuration for the anticheat, alongside this
		it is also responsible for emitting events as to when the configuration of the anticheat changes.
]]

local StarterPlayer = game:GetService("StarterPlayer")

local Package = script.Parent.Parent

local Signal = require(Package.Parent.Signal)

local LogService = require(Package.Services.LogService)

local Flags = require(Package.Types.Flags)

local flags = {
	SchedulerTick = 0.5,

	AntiSpeedPunishment = "Standard",
	AntiSpeedTargetSpeed = StarterPlayer.CharacterWalkSpeed,
	AntiSpeedLeniencySpeed = 10,
	AntiSpeedLeniencySeated = 20,
	AntiSpeedScore = 2,

	AntiNoclipTick = 0.1,
	AntiNoclipPunishment = "Standard",
	AntiNoclipScore = 1,

	AntiFlyRaycastDistance = 7.5,
	AntiFlyMaxTime = 3,
	AntiFlyCentralTrajectoryBuffer = 6,
	AntiFlyAnchoredBuffer = 0.5,
	AntiFlyPunishment = "Standard",
	AntiFlyScore = 2,

	AntiSwimTerrainRadius = 10,
	AntiSwimPunishment = "Standard",
	AntiSwimScore = 2,

	AntiClimbQueryRange = 5,
	AntiClimbStepHeight = 2,
	AntiClimbScore = 2,
	AntiClimbPunishment = "Standard",

	HoneypotPunishment = "Standard",
	HoneypotScore = 100,

	ProximityPromptLeniency = 5,
	ProximityPromptPunishment = "Standard",
	ProximityPromptScore = 5,

	MaxScore = 10,

	DecrementAmount = 1,
	DecrementTick = 5,
}

local flagsClone = table.freeze(table.clone(flags))

local FlagService = {}

FlagService.FlagsUpdated = Signal.new()

--[[
	Fetches that flags value.
]]
function FlagService.GetFlag(_: FlagService, flag: Flags.Enum)
	return flags[flag]
end

--[[
	Will set a flags value
]]
function FlagService.SetFlag(self: FlagService, flag: Flags.Enum, value: Generic)
	flags[flag] = value

	LogService:Log(`Flag '{flag}' has been set to: '{value}'`)

	self.FlagsUpdated:Fire()
end

--[[
	Will reset a flag back to it's default state
]]
function FlagService.ResetFlag(self: FlagService, flag: string)
	flags[flag] = flagsClone[flag]

	LogService:Log(`Flag '{flag}' has been reset`)

	self.FlagsUpdated:Fire()
end

function FlagService.OnStart(self: FlagService)
	Package.Events.SetFlag.Event:ConnectParallel(function(flag, value)
		self:SetFlag(flag, value)
	end)

	Package.Events.ResetFlag.Event:ConnectParallel(function(flag)
		self:ResetFlag(flag)
	end)
end

export type FlagService = typeof(FlagService)
export type Generic = boolean | string | number | nil

return FlagService
