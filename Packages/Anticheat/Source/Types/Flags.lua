--[[
	Flags are how we define the mutability of the anticheat, if a developer wants to change something about the anticheat
		they can do so by setting a flag.

	As an example, if you were to set the `SchedulerTick` flag, you could change what the interval is that the anticheat
		runs at, this could be good for performance.
]]

export type Enum =
	"SchedulerTick"
	| "DecrementTick"
	| "DecrementAmount"
	| "AntiSpeedTargetSpeed"
	| "AntiSpeedPunishment"
	| "AntiSpeedLeniencySpeed"
	| "AntiSpeedLeniencySeated"
	| "AntiSpeedScore"
	| "AntiNoclipTick"
	| "AntiNoclipPunishment"
	| "AntiNoclipScore"
	| "AntiFlyRaycastDistance"
	| "AntiFlyMaxTime"
	| "AntiFlyCentralTrajectoryBuffer"
	| "AntiFlyAnchoredBuffer"
	| "AntiFlyPunishment"
	| "AntiFlyScore"
	| "AntiSwimTerrainRadius"
	| "AntiSwimPunishment"
	| "AntiSwimScore"
	| "AntiClimbQueryRange"
	| "AntiClimbStepHeight"
	| "AntiClimbPunishment"
	| "AntiClimbScore"
	| "HoneypotPunishment"
	| "HoneypotScore"
	| "ProximityPromptLeniency"
	| "ProximityPromptPunishment"
	| "ProximityPromptScore"
	| "MaxScore"

return nil
