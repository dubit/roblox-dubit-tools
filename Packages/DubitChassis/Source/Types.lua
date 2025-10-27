export type ChassisProperties = {
	TireObject: ObjectValue,
	SpringRestLength: number,
	Stiffness: number,
	Damper: number,
	Friction: number,
	Torque: number,
	MaxSpeed: number,
	EngineBrake: number,
	ServerEngineBrake: number,
	SteerAngleLimiter: number,
	MaxSteerAngle: number,
	ChassisOwnerId: number,
	SteerSpeedAlpha: number,
}

export type TireAttachments = {
	FL: TireAttachmentData,
	FR: TireAttachmentData,
	RL: TireAttachmentData,
	RR: TireAttachmentData,
}

export type TireAttachmentData = { Position: Vector3, SpringOffset: number }

export type DownForceTrackingData = {
	ChassisSteerRotation: number,
	ApplyDownForce: boolean,
	TrackingTorque: number,
	CurrentDownForce: number,
	CurrentSteerAngle: number,
	RaycastCount: number,
	OnRamp: boolean,
	LastOrientation: CFrame,
}

export type TireRotations = {
	FL: number,
	FR: number,
	RL: number,
	RR: number,
}

export type DubitChassis = {
	StepPhysics: (self: DubitChassis, deltaTime: number, method: string) -> (),
	StartPhysicsStep: (self: DubitChassis) -> (),
	StopPhysicsStep: (self: DubitChassis) -> (),
	FromInstance: (self: DubitChassis, instance: Model) -> (),
	GetChassisCount: (self: DubitChassis) -> number,
	GetAllChassisInstances: (self: DubitChassis) -> { Model? },
	GetPlayerOwnedChassis: (self: DubitChassis, player: Player) -> Model?,
	RemoveAllChassis: (self: DubitChassis) -> (),
	SetGlobalChassisAttributes: (self: DubitChassis, chassisAttributes: { [string]: number }) -> (),
	Init: (self: DubitChassis) -> DubitChassis,
}

export type ChassisComponent = {
	--[[ Properties ]]
	Chassis: Model & { VehicleSeat: VehicleSeat, TireObject: ObjectValue },
	VehicleSeat: VehicleSeat,
	TireObject: ObjectValue,
	-- Client
	RaycastConnection: RBXScriptConnection,

	--[[ Lifecycle methods ]]
	Construct: (self: ChassisComponent) -> (),
	Start: (self: ChassisComponent) -> (),
	Stop: (self: ChassisComponent) -> (),
	HeartbeatUpdate: (self: ChassisComponent) -> (),
	SteppedUpdate: (self: ChassisComponent) -> (),
	RenderSteppedUpdate: (self: ChassisComponent) -> (),
	-- Server
	OnVehicleSeatOccupantChanged: (self: ChassisComponent) -> (),
	-- Client
	OnLocalPlayerSeated: (self: ChassisComponent) -> (),
	OnLocalPlayerExited: (self: ChassisComponent) -> (),
	StreamedIn: (self: ChassisComponent) -> (),
	StreamedOut: (self: ChassisComponent) -> (),

	--[[ Interface Functions ]]
	new: (data: any) -> ChassisComponent,
	-- Shared
	getActiveCharacters: () -> { [Player]: Model },
	Init: () -> (),

	--[[ Prototype Functions ]]
	-- Server
	StartDrivingVehicle: (self: ChassisComponent, character: Model) -> (),
	SetTireInstances: (self: ChassisComponent) -> (),
	SetNetworkOwnership: (self: ChassisComponent, occupant: Humanoid) -> (),
	ServerStepPhysics: (self: ChassisComponent, deltaTime: number) -> (),
	-- Client
	StepPhysics: (self: ChassisComponent, deltaTime: number) -> (),
	ClientStepPhysics: (self: ChassisComponent) -> (),
	-- Shared
	ResetChassisForces: (self: ChassisComponent) -> (),
	ListenToAttributeChangedEvents: (self: ChassisComponent) -> (),
	InvokeLifecycleMethods: (self: ChassisComponent, lifecycleMethod: string) -> (),
}

export type DubitChassisComponent = {
	ServerChassis: { (self: ChassisComponent) -> () },
	ClientChassis: { (self: ChassisComponent) -> () },
	SharedChassis: { (self: ChassisComponent) -> () },
}

return {}
