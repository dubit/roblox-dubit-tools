local ChassisAttributes = {
	["SpringRestLength"] = "SpringRestLength",
	["Stiffness"] = "Stiffness",
	["Damper"] = "Damper",
	["Friction"] = "Friction",
	["Torque"] = "Torque",
	["MaxSpeed"] = "MaxSpeed",
	["EngineBrake"] = "EngineBrake",
	["ServerEngineBrake"] = "ServerEngineBrake",
	["SteerAngleLimiter"] = "SteerAngleLimiter",
	["MaxSteerAngle"] = "MaxSteerAngle",
	["ChassisOwnerId"] = "ChassisOwnerId",
	["SteerSpeedAlpha"] = "SteerSpeedAlpha",
}

table.freeze(ChassisAttributes)

export type ChassisAttributes = typeof(ChassisAttributes)

return ChassisAttributes
