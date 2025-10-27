local ChassisAttributes = require(script.Parent.Parent.Enums.ChassisAttributes)

local ChassisDefaultData = {
	[ChassisAttributes.SpringRestLength] = 1.2,
	[ChassisAttributes.Stiffness] = 100,
	[ChassisAttributes.Damper] = 4,
	[ChassisAttributes.Friction] = 4,
	[ChassisAttributes.Torque] = 75,
	[ChassisAttributes.MaxSpeed] = 150,
	[ChassisAttributes.EngineBrake] = 0.5,
	[ChassisAttributes.ServerEngineBrake] = 3,
	[ChassisAttributes.SteerAngleLimiter] = 0.25,
	[ChassisAttributes.MaxSteerAngle] = 45,
	[ChassisAttributes.ChassisOwnerId] = 0,
	[ChassisAttributes.SteerSpeedAlpha] = 0.05,
}

table.freeze(ChassisDefaultData)

export type ChassisDefaultData = typeof(ChassisDefaultData)

return ChassisDefaultData
