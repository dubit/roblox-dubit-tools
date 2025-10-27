local ChassisAttachments = {
	FL = "FL",
	FR = "FR",
	RL = "RL",
	RR = "RR",
}

table.freeze(ChassisAttachments)

export type ChassisAttachments = typeof(ChassisAttachments)

return ChassisAttachments
