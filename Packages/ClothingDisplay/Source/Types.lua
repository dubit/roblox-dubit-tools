export type Hanger = {
	Instance: Model,
	AccessoryID: number,
	Scale: number,

	ChangeTo: (self: Hanger, accessoryID: number) -> (),

	GetPivot: (self: Hanger) -> CFrame,
	PivotTo: (self: Hanger, cframe: CFrame) -> (),

	GetScale: (self: Hanger) -> number,
	ScaleTo: (self: Hanger, scale: number) -> (),

	Destroy: (self: Hanger) -> (),
}

export type MannequinHead = {
	Instance: Model,

	AddAccessory: (self: MannequinHead, accessoryID: number) -> (),
	RemoveAccessory: (self: MannequinHead, accessoryID: number) -> (),
	RemoveAllAccessories: (self: MannequinHead) -> (),
	GetAccessories: (self: MannequinHead) -> { number },

	GetPivot: (self: MannequinHead) -> CFrame,
	PivotTo: (self: MannequinHead, cframe: CFrame) -> (),

	GetScale: (self: MannequinHead) -> number,
	ScaleTo: (self: MannequinHead, scale: number) -> (),

	Destroy: (self: MannequinHead) -> (),
}

return nil
