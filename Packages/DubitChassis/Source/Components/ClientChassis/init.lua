local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local package = script.Parent.Parent

local SharedChassis = require(package.Components.SharedChassis)

local Trove = require(package.Parent.Trove)
local Signal = require(package.Parent.Signal)
local TableUtil = require(package.Parent.TableUtil)
local Streamable = require(package.Parent.Streamable).Streamable

local DefaultLifeCycleMethods = require(package.Enums.DefaultLifeCycleMethods)
local ChassisAttributes = require(package.Enums.ChassisAttributes)
local ChassisAttachments = require(package.Enums.ChassisAttachments)

local Types = require(package.Types)

local TIRE_NEGATIVE_OFFSET: number = -0.5

local MAX_RAYCAST_COUNT: number = 4

local UPVECTOR_THRESHOLD: number = 0.75
local TRACKING_TORQUE = 350

local DOWNFORCE_OFFSET: number = 10
local DOWNFORCE_DAMPER: number = 10
local DOWNFORCE_STIFFNESS: number = 135
local MAXIMUM_DOWNFORCE: number = 12.5

local MAX_RAMP_VELOCITY: number = -25
local MAX_DEFAULT_VELOCITY: number = -200

local RAMP_TAG: string = "Ramp"
local LOOP_TAG: string = "Loop"

local STEER_ATTACHMENTS: { string } = { ChassisAttachments.FR, ChassisAttachments.FL }

local CHASSIS_LIFE_CYCLE_METHODS = TableUtil.Reconcile(DefaultLifeCycleMethods, {
	["OnLocalPlayerSeated"] = "OnLocalPlayerSeated",
	["OnLocalPlayerExited"] = "OnLocalPlayerExited",
	["StreamedIn"] = "StreamedIn",
	["StreamedOut"] = "StreamedOut",
})

--[=[
	@class ClientChassis

	@client

	ClientChassis handles all client-side component functionality of the DubitChassis.
]=]

local ClientChassis = {}

ClientChassis.internal = {}
ClientChassis.prototype = {}
ClientChassis.interface = {
	ChassisAdded = Signal.new(),
	ChassisRemoved = Signal.new(),
	--[[ Signal for TestEz unit tests ]]
	OnStepPhysicsSuccessful = Signal.new(),
}

local function lerp(a, b, t): number
	return a + (b - a) * t
end

function ClientChassis.internal:ToggleAlignOrientation(prototype: any)
	local carCFrame = prototype.Chassis.PrimaryPart.CFrame
	local alignAttachment = prototype.Chassis.PrimaryPart.AlignAttachment

	local rayOrigin = carCFrame:ToWorldSpace(CFrame.new(alignAttachment.Position)).Position
	local rayDirection = -carCFrame.UpVector
		* (
			prototype._chassisProperties[ChassisAttributes.SpringRestLength]
			+ prototype._chassisProperties.TireObject.Size.Y / 2
		)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { prototype.Chassis, SharedChassis.getActiveCharacters() }
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	--[[ Checks if RaycastCount has reached the max value to ensure the chassis is parallel towards the ground ]]
	if prototype._downForceTrackingData.RaycastCount == MAX_RAYCAST_COUNT then
		--[[ Checks if raycast instance is tagged as RampTag ]]
		if raycastResult and CollectionService:HasTag(raycastResult.Instance, RAMP_TAG) then
			prototype._downForceTrackingData.OnRamp = true
		else
			prototype._downForceTrackingData.OnRamp = false
		end
	end

	if prototype._downForceTrackingData.RaycastCount == 0 then
		--[[ If chassis is not touching the ground, we reset any tracking and downforce forces ]]
		prototype._downForceTrackingData.TrackingTorque = 0
		prototype._downForceTrackingData.CurrentDownForce = 0

		--[[ If AlignOrientation is enabled, we limit the Y Velocity of the chassis so it falls linearly and smoothly.
            If velocity is not limited, acceleration of the chassis causes unpredictable behaviour ]]
		local maxVelocityY = if prototype.Chassis.PrimaryPart.AlignOrientation.Enabled
			then MAX_RAMP_VELOCITY
			else MAX_DEFAULT_VELOCITY

		prototype.Chassis.PrimaryPart.AssemblyLinearVelocity = Vector3.new(
			prototype.Chassis.PrimaryPart.AssemblyLinearVelocity.X,
			math.clamp(prototype.Chassis.PrimaryPart.AssemblyLinearVelocity.Y, maxVelocityY, math.abs(maxVelocityY)),
			prototype.Chassis.PrimaryPart.AssemblyLinearVelocity.Z
		)

		if prototype._downForceTrackingData.OnRamp and not prototype.Chassis.PrimaryPart.AlignOrientation.Enabled then
			prototype.Chassis.PrimaryPart.AlignOrientation.Enabled = true
			prototype.Chassis.PrimaryPart.AlignOrientation.CFrame = prototype._downForceTrackingData.LastOrientation
		end
	end

	if prototype.Chassis.PrimaryPart.AlignOrientation.Enabled and prototype._downForceTrackingData.RaycastCount > 0 then
		prototype.Chassis.PrimaryPart.AlignOrientation.Enabled = false
	end
end

function ClientChassis.internal:ComputeRaycastSuspension(prototype: any, attachmentName: string, deltaTime: number)
	local attachmentData = prototype._tireAttachments[attachmentName]

	local springOffset = attachmentData.SpringOffset
	local attachmentPosition = attachmentData.AttachmentPosition

	local chassisPrimaryPart = prototype.Chassis.PrimaryPart
	local carCFrame = chassisPrimaryPart.CFrame

	local rayOrigin = carCFrame:ToWorldSpace(CFrame.new(attachmentPosition)).Position
	local defaultSpringLength = prototype._chassisProperties[ChassisAttributes.SpringRestLength]
		+ prototype._chassisProperties.TireObject.Size.Y / 2
	local rayDirection = -carCFrame.UpVector
		* (defaultSpringLength * (if prototype._downForceTrackingData.ApplyDownForce then DOWNFORCE_OFFSET else 1))
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { prototype.Chassis, SharedChassis.getActiveCharacters() }
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	--[[ Checks if ray casted is smaller then the defaultSpringLength ]]
	if rayDirection.Y < defaultSpringLength and rayDirection.Y > -defaultSpringLength then
		rayDirection = Vector3.new(
			rayDirection.X,
			(rayDirection.Y / math.abs(rayDirection.Y)) * defaultSpringLength,
			rayDirection.Z
		)
	end

	if raycastResult then
		prototype._downForceTrackingData.RaycastCount += 1

		local offset = math.clamp(
			prototype._chassisProperties[ChassisAttributes.SpringRestLength]
				- (raycastResult.Distance - prototype._chassisProperties.TireObject.Size.Y / 2),
			0,
			prototype._chassisProperties[ChassisAttributes.SpringRestLength]
		)
		local springForce = if prototype._downForceTrackingData.ApplyDownForce
			then DOWNFORCE_STIFFNESS * offset
			else prototype._chassisProperties[ChassisAttributes.Stiffness] * offset

		local springVelocity = (springOffset - offset) / deltaTime

		local dampForce = if prototype._downForceTrackingData.ApplyDownForce
			then DOWNFORCE_DAMPER * springVelocity
			else prototype._chassisProperties[ChassisAttributes.Damper] * springVelocity

		local suspensionForce = springForce - dampForce

		local steerDirection = carCFrame.Rotation

		--[[ Only SteerAttachments indexes should be applying the steer velocity ]]
		if table.find(STEER_ATTACHMENTS, attachmentName) then
			--[[ We apply a steerLimiter value so as the chassis moves faster, the steer angles become tighter ]]
			local steerLimiter = math.clamp(
				1
					- (
						prototype.VehicleSeat.AssemblyLinearVelocity.Magnitude
						/ prototype._chassisProperties[ChassisAttributes.MaxSpeed]
					),
				prototype._chassisProperties[ChassisAttributes.SteerAngleLimiter],
				1
			)

			steerDirection *= CFrame.Angles(
				0,
				-math.rad(
					prototype._downForceTrackingData.CurrentSteerAngle
						* (prototype._chassisProperties[ChassisAttributes.MaxSteerAngle] * steerLimiter)
				),
				0
			)
		end

		local steerVelocity =
			steerDirection:ToObjectSpace(CFrame.new(chassisPrimaryPart:GetVelocityAtPosition(raycastResult.Position)))
		local slipForce = (steerDirection.RightVector * -steerVelocity.X)
			* prototype._chassisProperties[ChassisAttributes.Friction]
		--[[ We use the maxSpeedLimiter to constrain the Cars speed in correspondance to the MAX_SPEED
		 	1 means there is no movement on the car, 0 means it has reached MAX_SPEED value
		 	and a value below 0 means the velocity has went past the MAX_SPEED value.
			The longitudinalForceLimiter value limits the longitudinalForce so it does not exceed the MaxSpeed ]]
		local longitudinalForceLimiter: number = 1
			- (math.abs(steerVelocity.Z) / prototype._chassisProperties[ChassisAttributes.MaxSpeed])

		local longitudinalForce: number = steerDirection.LookVector
			* (prototype.VehicleSeat.Throttle * (prototype._chassisProperties[ChassisAttributes.Torque] + prototype._downForceTrackingData.TrackingTorque))
			* longitudinalForceLimiter

		--[[ If player does not have the W key held down, we instead apply a ENGINE_BRAKE force
		 	on the Z-Axis in the direction the player is steering in.
		 	This is similar to how the slipForce is calculated, but instead pushing in the Z-Axis.]]
		if longitudinalForce == Vector3.zero then
			longitudinalForce = (carCFrame.LookVector * steerVelocity.Z)
				* prototype._chassisProperties[ChassisAttributes.EngineBrake]
		end

		attachmentData.SpringOffset = offset

		if
			CollectionService:HasTag(raycastResult.Instance, LOOP_TAG)
			and math.abs(steerVelocity.Z) > (prototype._chassisProperties[ChassisAttributes.MaxSpeed] / 10)
		then
			if carCFrame.UpVector.Y <= UPVECTOR_THRESHOLD then
				prototype._downForceTrackingData.ApplyDownForce = true
				prototype._downForceTrackingData.TrackingTorque =
					lerp(prototype._downForceTrackingData.TrackingTorque, TRACKING_TORQUE, 0.1)
				prototype._downForceTrackingData.CurrentDownForce = lerp(
					prototype._downForceTrackingData.CurrentDownForce,
					-math.abs(MAXIMUM_DOWNFORCE) * carCFrame.UpVector.Y,
					0.1
				)
			else
				if
					prototype._downForceTrackingData.CurrentDownForce < 1
					and prototype._downForceTrackingData.CurrentDownForce > -1
				then
					prototype._downForceTrackingData.ApplyDownForce = false
					prototype._downForceTrackingData.CurrentDownForce = 0
				end

				prototype._downForceTrackingData.TrackingTorque =
					lerp(prototype._downForceTrackingData.TrackingTorque, 0, 0.1)
				prototype._downForceTrackingData.CurrentDownForce =
					lerp(prototype._downForceTrackingData.CurrentDownForce, 0, 0.1)
			end
		else
			prototype._downForceTrackingData.ApplyDownForce = false

			prototype._downForceTrackingData.TrackingTorque = 0
			prototype._downForceTrackingData.CurrentDownForce = 0
		end
		local fps = 1 / deltaTime
		local chassisWeight

		if prototype._downForceTrackingData.ApplyDownForce then
			chassisWeight = if fps >= 30
				then prototype._chassisWeight
				else prototype._chassisWeight / (1 + (1 - fps / 60))
		else
			chassisWeight = prototype._chassisWeight
		end

		prototype._currentChassisWeight = lerp(prototype._currentChassisWeight, chassisWeight, 0.1)

		local finalChassisForce = (
			((suspensionForce * carCFrame.UpVector) + slipForce + longitudinalForce)
			+ (Vector3.new(0, prototype._downForceTrackingData.CurrentDownForce, 0))
		) * prototype._currentChassisWeight

		chassisPrimaryPart[attachmentName].VectorForce.Force = finalChassisForce
	else
		attachmentData.SpringOffset = 0

		prototype._downForceTrackingData.ApplyDownForce = false
		prototype._downForceTrackingData.TrackingTorque = 0
		prototype._downForceTrackingData.CurrentDownForce = 0

		chassisPrimaryPart[attachmentName].VectorForce.Force = Vector3.new(0, 0, 0)
	end
end

function ClientChassis.internal:ComputeTireReplicationRaycast(prototype: any, attachmentName: string)
	local chassis = prototype.Chassis
	local chassisPrimaryPart = chassis.PrimaryPart

	local tireRadius = prototype._chassisProperties.TireObject.Size.Y / 2
	local attachmentData = prototype._tireAttachments[attachmentName]

	local carCFrame = chassisPrimaryPart.CFrame

	local rayOrigin = carCFrame:ToWorldSpace(CFrame.new(attachmentData.AttachmentPosition)).Position
	local rayDirection = -carCFrame.UpVector
		* (prototype._chassisProperties[ChassisAttributes.SpringRestLength] + tireRadius)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { chassis, SharedChassis.getActiveCharacters() }
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	local weld = chassis.TiresFolder[attachmentName].Weld
	local initialCFrame: CFrame?

	if raycastResult then
		local steerDirection = carCFrame.Rotation
		local steerVelocity =
			steerDirection:ToObjectSpace(CFrame.new(chassisPrimaryPart:GetVelocityAtPosition(raycastResult.Position)))

		local offset = raycastResult.Distance - tireRadius
		offset = math.clamp(
			offset,
			if prototype._downForceTrackingData.ApplyDownForce then 0 else TIRE_NEGATIVE_OFFSET,
			math.abs(offset)
		)

		initialCFrame = CFrame.new(attachmentData.AttachmentPosition - Vector3.new(0, offset, 0))

		prototype._tireRotations[attachmentName] += math.rad(steerVelocity.Z)

		ClientChassis.internal:ApplyTireSteerRotation(prototype, attachmentName, weld, initialCFrame)

		if attachmentData.AttachmentPosition.X > 0 then
			weld.C0 = weld.C0
				* CFrame.Angles(0, math.rad(180), 0)
				* CFrame.Angles(-prototype._tireRotations[attachmentName], 0, 0)
			return
		end

		weld.C0 = weld.C0 * CFrame.Angles(prototype._tireRotations[attachmentName], 0, 0)
	else
		initialCFrame = CFrame.new(
			attachmentData.AttachmentPosition
				- Vector3.new(0, prototype._chassisProperties[ChassisAttributes.SpringRestLength], 0)
		)

		chassis.TiresFolder[attachmentName].Weld.C0 = initialCFrame

		ClientChassis.internal:ApplyTireSteerRotation(prototype, attachmentName, weld, initialCFrame)

		if attachmentData.AttachmentPosition.X > 0 then
			chassis.TiresFolder[attachmentName].Weld.C0 = chassis.TiresFolder[attachmentName].Weld.C0
				* CFrame.Angles(0, math.rad(180), 0)
		end
	end
end

function ClientChassis.internal:ApplyTireSteerRotation(
	prototype: any,
	attachmentName: string,
	weld: Weld,
	initialCFrame: CFrame
)
	if table.find(STEER_ATTACHMENTS, attachmentName) then
		prototype._downForceTrackingData.ChassisSteerRotation = lerp(
			prototype._downForceTrackingData.ChassisSteerRotation,
			prototype.Chassis.VehicleSeat.SteerFloat,
			prototype._chassisProperties.SteerSpeedAlpha
		)

		weld.C0 = initialCFrame
			* CFrame.Angles(
				0,
				-math.rad(
					prototype._downForceTrackingData.ChassisSteerRotation
						* prototype._chassisProperties[ChassisAttributes.MaxSteerAngle]
				),
				0
			)
	else
		weld.C0 = initialCFrame
	end
end

--[=[
	`Construct` is called before the component is started, and should be used to construct the component instance. This lifecycle methods yields
	until the Instance's `PrimaryPart` exists to accomodate for the `StreamingEnabled` feature.

	```lua
	local ClientChassis = Component.new({Tag = "ClientChassis"})

	function ClientChassis:Construct()
		self.SomeData = 32
		self.OtherStuff = "HelloWorld"
	end
	```

	@method Construct
	@within ClientChassis

	@yields

	@return ()
]=]
--

function ClientChassis.prototype:Construct()
	--[=[
	@prop Chassis Instance
	@within ClientChassis
]=]
	--
	--[=[
	@prop VehicleSeat VehicleSeat
	@within ClientChassis
]=]
	--
	--[=[
	@prop TireObject ObjectValue
	@within ClientChassis
]=]
	--
	--[=[
	@prop RaycastConnection RBXScriptConnection
	@within ClientChassis
]=]
	--

	self._trove = Trove.new() :: table

	while self.Instance and self.Instance:FindFirstChild("VehicleSeat") == nil do
		task.wait(1)
	end

	self._streamable = Streamable.primary(self.Instance)

	self._chassisProperties = {
		["TireObject"] = self.Instance.TireObject.Value,
	} :: Types.ChassisProperties
	self._chassisWeight = self.Instance.PrimaryPart:GetMass()
		+ self.Instance.COG:GetMass()
		+ ((self.Instance.TireObject.Value:GetMass() * #self.Instance.TiresFolder:GetChildren()) / 2) :: number
	self._currentChassisWeight = self._chassisWeight :: number
	self._downForceTrackingData = {
		ChassisSteerRotation = 0,
		ApplyDownForce = false,
		TrackingTorque = 0,
		CurrentDownForce = 0,
		CurrentSteerAngle = 0,
		RaycastCount = 0,
		OnRamp = false,
		LastOrientation = nil,
	} :: Types.DownForceTrackingData
	self._tireAttachments = {
		[ChassisAttachments.FL] = {
			AttachmentPosition = self.Instance.PrimaryPart[ChassisAttachments.FL].Position,
			SpringOffset = 0.5,
		},
		[ChassisAttachments.FR] = {
			AttachmentPosition = self.Instance.PrimaryPart[ChassisAttachments.FR].Position,
			SpringOffset = 0.5,
		},
		[ChassisAttachments.RL] = {
			AttachmentPosition = self.Instance.PrimaryPart[ChassisAttachments.RL].Position,
			SpringOffset = 0.5,
		},
		[ChassisAttachments.RR] = {
			AttachmentPosition = self.Instance.PrimaryPart[ChassisAttachments.RR].Position,
			SpringOffset = 0.5,
		},
	} :: Types.TireAttachments
	self._tireRotations = {
		[ChassisAttachments.FL] = 0,
		[ChassisAttachments.FR] = 0,
		[ChassisAttachments.RL] = 0,
		[ChassisAttachments.RR] = 0,
	} :: Types.TireRotations
	self._onOccupantChanged =
		Signal.Wrap(self.Instance:WaitForChild("VehicleSeat"):GetPropertyChangedSignal("Occupant")) :: table
	self._lastOccupant = nil :: Model?

	self.Chassis = self.Instance :: Model
	self.VehicleSeat = self.Chassis.VehicleSeat :: VehicleSeat
	self.TireObject = self.Chassis.TireObject :: ObjectValue
	self.RaycastConnection = nil :: RBXScriptConnection

	--[[ Sets remaining internal props ]]
	for _, attribute in ChassisAttributes do
		self._chassisProperties[attribute] = self.Chassis:GetAttribute(attribute)
	end

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Construct)
end

--[=[
	`Start` is called when the component is started. At this point in time, it is safe to grab other components also bound to the same instance.

	```lua
	local ClientChassis = Component.new({Tag = "ClientChassis"})
	local AnotherComponent = require(somewhere.AnotherComponent)

	function ClientChassis:Start()
		-- e.g., grab another component:
		local another = self:GetComponent(AnotherComponent)
	end
	```

	@method Start
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:Start()
	self._streamable:Observe(function()
		self:StreamedIn()

		self._trove:Add(function()
			self:StreamedOut()
		end)
	end)

	self._trove:Add(self._onOccupantChanged:Connect(function()
		local character = Players.LocalPlayer.Character

		if self.VehicleSeat.Occupant == character.Humanoid then
			self:OnLocalPlayerSeated()
			self._lastOccupant = character

			return
		end

		if self._lastOccupant then
			self:OnLocalPlayerExited()
		end

		self._lastOccupant = nil
	end))

	self:ListenToAttributeChangedEvents()

	ClientChassis.interface.ChassisAdded:Fire(self)

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Start)
end

--[=[
	`Stop` is called when the component is stopped. This occurs either when the bound instance is removed from one of 
	the whitelisted ancestors or when the matching tag is removed from the instance. This also means that the instance might be destroyed, 
	and thus it is not safe to continue using the bound instance (e.g. `self.Instance`) any longer.

	This should be used to clean up the component.

	```lua
	local ClientChassis = Component.new({Tag = "ClientChassis"})

	function ClientChassis:Stop()
		self.SomeStuff:Destroy()
	end
	```

	@method Stop
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:Stop()
	--[[ Defer action to ensure it doesn't interfere with the current frame's rendering or other processes ]]
	task.defer(function()
		if self.Instance and self.Instance.PrimaryPart then
			self.Instance:Destroy()
		end
	end)

	self._trove:Destroy()

	ClientChassis.interface.ChassisRemoved:Fire(self)

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Stop)
end

--[=[
	`OnLocalPlayerSeated` is invoked when the `LocalPlayer` has seated in the components `VehicleSeat`.

	```lua
	function ClientChassis:OnLocalPlayerSeated()
		print(game.Players.LocalPlayer.Name.." has seated in the VehicleSeat!")
	end
	```

	@method OnLocalPlayerSeated
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:OnLocalPlayerSeated()
	self:ResetChassisForces()

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.OnLocalPlayerSeated)
end

--[=[
	`OnLocalPlayerExited` is invoked when the `LocalPlayer` has exited the components `VehicleSeat`.

	```lua
	function TestChassis:OnLocalPlayerExited()
		print(game.Players.LocalPlayer.Name.." has exited the VehicleSeat!")
	end
	```

	@method OnLocalPlayerExited
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:OnLocalPlayerExited()
	self:ResetChassisForces()

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.OnLocalPlayerExited)
end

--[=[
	`StreamedIn` is invoked when Instance is streamed in.

	```lua
	function TestChassis:StreamedIn()
		print("Chassis has been streamed in!")
	end
	```

	@method StreamedIn
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:StreamedIn()
	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.StreamedIn)
end

--[=[
	`StreamedOut` is invoked when Instance is streamed out.

	```lua
	function TestChassis:StreamedOut()
		print("Chassis has been streamed out!")
	end
	```

	@method StreamedOut
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:StreamedOut()
	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.StreamedOut)
end

--[=[
	This method computes and handles the client-side raycast suspension physics.
	This method should only be invoked when the `LocalPlayer` has been set as the `NetworkOwner` of the chassis.

	```lua
	-- Start RenderStepped function to update suspension physics if LocalPlayer is the NetworkOwner
	function ClientChassis:OnLocalPlayerSeated()
		self.RaycastConnection = RunService.RenderStepped:Connect(function(deltaTime)
			self:StepPhysics(deltaTime)
		end)
	end

	-- Disconnects RenderStepped function if LocalPlayer is no longer the NetworkOwner
	function TestChassis:OnLocalPlayerExited()
		self.RaycastConnection:Disconnect()
	end
	```

	@method StepPhysics
	@within ClientChassis

	@param deltaTime number

	@return ()
]=]
--

function ClientChassis.prototype:StepPhysics(deltaTime: number)
	local chassis = self.Chassis
	local vehicleSeat = self.VehicleSeat

	ClientChassis.interface.OnStepPhysicsSuccessful:Fire()

	if chassis == nil or chassis.PrimaryPart == nil or vehicleSeat.Occupant == nil then
		self:OnLocalPlayerExited()

		return
	end

	-- [[ Set values every frame ]]
	self._downForceTrackingData.RaycastCount = 0
	self._downForceTrackingData.LastOrientation = chassis.PrimaryPart.CFrame
	-- [[ Smoothen CurrentSteerAngle value based on SteerSpeedAlpha ]]
	self._downForceTrackingData.CurrentSteerAngle = lerp(
		self._downForceTrackingData.CurrentSteerAngle,
		vehicleSeat.SteerFloat,
		self._chassisProperties.SteerSpeedAlpha
	)

	for _, attachmentName in ChassisAttachments do
		ClientChassis.internal:ComputeRaycastSuspension(self, attachmentName, deltaTime)
	end

	ClientChassis.internal:ToggleAlignOrientation(self)
end

--[=[
	This method computes and handles the client-side raycast for Chassis tires and functions within a global scope.
	This method is already invoked within the `DubitChassis:InitPhysicsStep()` method so it should not be called
	externally by the component. One of the few exceptions is unless it is used as an alternative manual implementation of the `DubitChassis:InitPhysicsStep()` method.
	```lua
	-- DubitChassis interface function example
	function DubitChassis.interface:InitPhysicsStep()
		RunService.RenderStepped:Connect(function(_: number)
			for _, prototype in pairs(DubitChassis.internal.ChassisRegistry) do
				prototype:ClientStepPhysics()
			end
		end)
	end
	```

	@method ClientStepPhysics
	@within ClientChassis

	@return ()
]=]
--

function ClientChassis.prototype:ClientStepPhysics()
	if not self.Chassis:FindFirstChild("TiresFolder") then
		return
	end

	for _, attachmentName in ChassisAttachments do
		ClientChassis.internal:ComputeTireReplicationRaycast(self, attachmentName)
	end
end

--[=[
	This function constructs a new `ClientChassis` component class.

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitChassis = require(path-to-module)

	local TestChassis = DubitChassis.Component.new({
		Tag = "Chassis",
		Ancestors = {},
		Extensions = {},
	})

	return TestChassis
	```

	@function new
	@within ClientChassis

	@param data any
	@return ChassisComponent
]=]
--

function ClientChassis.interface.new(...): Types.ChassisComponent
	local chassisComponent = SharedChassis.new(...)

	chassisComponent._internalLifecycleMethods = {}

	for index, object in ClientChassis.prototype do
		chassisComponent[index] = object
	end

	return setmetatable({}, {
		__index = chassisComponent,
		__newindex = function(_, index, value)
			if CHASSIS_LIFE_CYCLE_METHODS[index] then
				chassisComponent._internalLifecycleMethods[index] = value
			else
				chassisComponent[index] = value
			end
		end,
	})
end

return ClientChassis.interface :: typeof(ClientChassis.interface) & {}
