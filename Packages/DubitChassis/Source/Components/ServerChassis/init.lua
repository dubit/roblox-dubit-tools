local package = script.Parent.Parent

local SharedChassis = require(package.Components.SharedChassis)

local Trove = require(package.Parent.Trove)
local Signal = require(package.Parent.Signal)
local TableUtil = require(package.Parent.TableUtil)

local ChassisAttributes = require(package.Enums.ChassisAttributes)
local ChassisAttachments = require(package.Enums.ChassisAttachments)
local DefaultLifeCycleMethods = require(package.Enums.DefaultLifeCycleMethods)
local ChassisDefaultData = require(package.Data.ChassisDefaultData)

local Types = require(package.Types)

local CHASSIS_LIFE_CYCLE_METHODS =
	TableUtil.Reconcile(DefaultLifeCycleMethods, { ["OnVehicleSeatOccupantChanged"] = "OnVehicleSeatOccupantChanged" })

--[=[
	@class ServerChassis

	@server

	ServerChassis handles all server-side component functionality of the DubitChassis.
]=]

local ServerChassis = {}

ServerChassis.internal = {}
ServerChassis.prototype = {}
ServerChassis.interface = {
	ChassisAdded = Signal.new(),
	ChassisRemoved = Signal.new(),
}

local function toggleMassless(character: Model, toggle: boolean)
	for _, descendant in character:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end

		descendant.Massless = toggle
	end
end

function ServerChassis.internal:ComputeRaycastSuspension(prototype: any, attachment: string, deltaTime: number)
	local currentAttachment = prototype._tireAttachments[attachment]

	local springOffset = currentAttachment.SpringOffset
	local tirePosition = currentAttachment.AttachmentPosition
	local tireRadius = prototype._chassisProperties.TireObject.Size.Y / 2

	local chassis = prototype.Chassis
	local chassisPrimaryPart = chassis.PrimaryPart
	local carCFrame = chassisPrimaryPart.CFrame

	local rayOrigin = carCFrame:ToWorldSpace(CFrame.new(tirePosition)).Position
	local rayDirection = -Vector3.new(0, 1, 0)
		* (prototype._chassisProperties[ChassisAttributes.SpringRestLength] + tireRadius)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { chassis, SharedChassis.getActiveCharacters() }

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	if raycastResult then
		local offset = math.clamp(
			prototype._chassisProperties[ChassisAttributes.SpringRestLength] - (raycastResult.Distance - tireRadius),
			0,
			prototype._chassisProperties[ChassisAttributes.SpringRestLength]
		)

		--[[ Multiply spring offset by a spring constant (Hooke's Law) ]]
		local springForce = prototype._chassisProperties[ChassisAttributes.Stiffness] * offset
		--[[ Divide by deltatime, to account for variable frame rate ]]
		local springVelocity = (springOffset - offset) / deltaTime
		--[[ Multiply the spring velocity by damper constant (Damper Force) ]]
		local dampForce = prototype._chassisProperties[ChassisAttributes.Damper] * springVelocity
		--[[ Get the difference of the two forces to calculate magnitude of the Dampened Spring Force ]]
		local suspensionForce = springForce - dampForce

		--[[ We get the rotational matrices since we ONLY want to get the rotation of
		 the carCFrame. By getting the entire CFrame, it would add a arbitrary velocity (Vector matrices) to
		 our calculations later on which will create discrepencies in our physic simulations ]]
		local steerDirection = carCFrame.Rotation
		local steerVelocity =
			steerDirection:ToObjectSpace(CFrame.new(chassisPrimaryPart:GetVelocityAtPosition(raycastResult.Position)))

		--[[ A lateral directional force to push in opposite direction of the tires to prevent them from slipping ]]
		local slipForce = (steerDirection.RightVector * -steerVelocity.X)
			* prototype._chassisProperties[ChassisAttributes.Friction]

		--[[ A longitudinal directional force that applies a ServerEngineBrake force to prevent car from moving forward. (When stopped) ]]
		local longitudinalForce = (carCFrame.LookVector * steerVelocity.Z) * ChassisDefaultData.ServerEngineBrake

		currentAttachment.SpringOffset = offset

		chassisPrimaryPart[attachment].VectorForce.Force = (
			(suspensionForce * Vector3.new(0, 1, 0))
			+ slipForce
			+ longitudinalForce
		) * prototype._chassisWeight
	else
		chassisPrimaryPart[attachment].VectorForce.Force = Vector3.new(0, 0, 0)
		currentAttachment.SpringOffset = 0
	end
end

--[=[
	`Construct` is called before the component is started, and should be used to construct the component instance.

	```lua
	local ServerChassis = Component.new({Tag = "ServerChassis"})

	function ServerChassis:Construct()
		self.SomeData = 32
		self.OtherStuff = "HelloWorld"
	end
	```

	@method Construct
	@within ServerChassis

	@return ()
]=]
--

function ServerChassis.prototype:Construct()
	--[=[
	@prop Chassis Instance
	@within ServerChassis
]=]
	--
	--[=[
	@prop VehicleSeat VehicleSeat
	@within ServerChassis
]=]
	--
	--[=[
	@prop TireObject ObjectValue
	@within ServerChassis
]=]
	--
	self._trove = Trove.new() :: table
	self._vehicleSeatOccupantChanged =
		Signal.Wrap(self.Instance.VehicleSeat:GetPropertyChangedSignal("Occupant")) :: table
	self._lastOccupant = nil :: Humanoid?
	self._chassisProperties = { ["TireObject"] = self.Instance.TireObject.Value } :: Types.ChassisProperties
	self._chassisWeight = 0 :: number
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

	self.Chassis = self.Instance :: Model
	self.VehicleSeat = self.Chassis.VehicleSeat :: VehicleSeat
	self.TireObject = self.Chassis.TireObject :: ObjectValue

	--[[ Sets chassis attributes and remaining internal props ]]
	for _, attribute in ChassisAttributes do
		self.Chassis:SetAttribute(attribute, self.Chassis:GetAttribute(attribute) or ChassisDefaultData[attribute])
		self._chassisProperties[attribute] = self.Chassis:GetAttribute(attribute)
	end

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Construct)
end

--[=[
	`Start` is called when the component is started. At this point in time, it is safe to grab other components also bound to the same instance.

	```lua
	local ServerChassis = Component.new({Tag = "ServerChassis"})
	local AnotherComponent = require(somewhere.AnotherComponent)

	function ServerChassis:Start()
		-- e.g., grab another component:
		local another = self:GetComponent(AnotherComponent)
	end
	```

	@method Start
	@within ServerChassis

	@return ()
]=]
--

function ServerChassis.prototype:Start()
	self:SetTireInstances()
	self:ListenToAttributeChangedEvents()

	self._trove:Add(self._vehicleSeatOccupantChanged:Connect(function()
		self:OnVehicleSeatOccupantChanged()
	end))

	ServerChassis.interface.ChassisAdded:Fire(self)

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Start)
end

--[=[
	`Stop` is called when the component is stopped. This occurs either when the bound instance is removed from one of 
	the whitelisted ancestors or when the matching tag is removed from the instance. This also means that the instance might be destroyed, 
	and thus it is not safe to continue using the bound instance (e.g. `self.Instance`) any longer.

	```lua
	local ServerChassis = Component.new({Tag = "ServerChassis"})

	function ServerChassis:Stop()
		self.SomeStuff:Destroy()
	end
	```

	@method Stop
	@within ServerChassis

	@return ()
]=]
--

function ServerChassis.prototype:Stop()
	--[[ Defer action to ensure it doesn't interfere with the current frame's rendering or other processes ]]
	task.defer(function()
		if self.Instance and self.Instance.PrimaryPart then
			self.Instance:Destroy()
		end
	end)

	ServerChassis.interface.ChassisRemoved:Fire(self)

	self._trove:Destroy()

	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Stop)
end

--[=[
	`OnVehicleSeatOccupantChanged` is invoked when the components `VehicleSeat`'s occupant property has been changed.

	```lua
	local ServerChassis = Component.new({Tag = "ServerChassis"})

	function ServerChassis:OnVehicleSeatOccupantChanged()
		print("VehicleSeat occupant changed to: "..tostring(self.VehicleSeat.Occupant.Parent))
	end
	```

	@method OnVehicleSeatOccupantChanged
	@within ServerChassis

	@return ()
]=]
--

function ServerChassis.prototype:OnVehicleSeatOccupantChanged()
	self:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.OnVehicleSeatOccupantChanged)
end

--[=[
	This will seat the specified character in the components `VehicleSeat`.

	```lua
	ServerChassis:StartDrivingVehicle(player.Character)
	```

	@method StartDrivingVehicle
	@within ServerChassis

	@param character Model

	@return ()
]=]
--

function ServerChassis.prototype:StartDrivingVehicle(character: Model)
	self.VehicleSeat:Sit(character.Humanoid)
end

--[=[
	This will set the Chassis tire instances based on its TireObject value.

	```lua
	ServerChassis:SetTireInstances()
	```

	@method SetTireInstances
	@within ServerChassis

	@return ()
]=]
--

function ServerChassis.prototype:SetTireInstances()
	if self.Chassis:FindFirstChild("TiresFolder") then
		self.Chassis:FindFirstChild("TiresFolder"):Destroy()
	end

	if not self.TireObject.Value then
		return
	end

	local tiresFolder = Instance.new("Folder")
	tiresFolder.Parent = self.Chassis
	tiresFolder.Name = "TiresFolder"

	for tireIndex, tireData in self._tireAttachments do
		local clonedTire = self.TireObject.Value:Clone()
		clonedTire.Parent = tiresFolder
		clonedTire.Name = tireIndex
		clonedTire.CanCollide = false

		local weld = Instance.new("Weld")
		weld.Parent = clonedTire
		weld.Part0 = self.Chassis.PrimaryPart
		weld.Part1 = clonedTire
		weld.C0 = CFrame.new(tireData.AttachmentPosition)

		if tireData.AttachmentPosition.X > 0 then
			weld.C0 = weld.C0 * CFrame.Angles(0, math.rad(180), 0)
		end
	end

	for _, v in self.Chassis:GetDescendants() do
		if not v:IsA("BasePart") then
			continue
		end

		v:SetNetworkOwner(nil)
	end

	self._chassisWeight = self.Instance.PrimaryPart:GetMass()
		+ self.Instance.COG:GetMass()
		+ ((self.Instance.TireObject.Value:GetMass() * #self.Instance.TiresFolder:GetChildren()) / 2)
end

--[=[
	This will set the `NetworkOwner` of the chassis to the `Humanoid` specified in the params. If `nil` is passed, it will set the `NetworkOwner` to the server.

	```lua
	ServerChassis:SetNetworkOwnership(self.VehicleSeat.Occupant)
	```

	@method SetNetworkOwnership
	@within ServerChassis

	@param occupant Humanoid

	@return ()
]=]
--

function ServerChassis.prototype:SetNetworkOwnership(occupant: Humanoid)
	self:ResetChassisForces()

	for _, descendant in (self.Chassis:GetDescendants()) do
		if descendant:IsA("VectorForce") then
			descendant.Force = Vector3.new(0, 0, 0)
		end
	end

	self.VehicleSeat.ProximityPrompt.Enabled = not occupant

	if occupant then
		local player = game.Players:GetPlayerFromCharacter(occupant.Parent)

		self.Chassis:SetAttribute(ChassisAttributes.ChassisOwnerId, player.UserId)

		for _, descendant in (self.Chassis:GetDescendants()) do
			if not descendant:IsA("BasePart") then
				continue
			end

			descendant:SetNetworkOwner(player)
		end

		self._lastOccupant = occupant.Parent

		toggleMassless(self._lastOccupant, true)
	else
		self.Chassis:SetAttribute(ChassisAttributes.ChassisOwnerId, 0)

		for _, descendant in (self.Chassis:GetDescendants()) do
			if not descendant:IsA("BasePart") then
				continue
			end

			descendant:SetNetworkOwner(nil)
		end

		toggleMassless(self._lastOccupant, false)

		self._lastOccupant = nil
	end
end

--[=[
	This method computes and handles the server-side raycast suspension physics and functions within a global scope.
	This method is already invoked within the `DubitChassis:InitPhysicsStep()` method so it should not be called
	externally by the component. One of the few exceptions is unless it is used as an alternative manual implementation of the `DubitChassis:InitPhysicsStep()` method.
	```lua
	-- DubitChassis interface function example
	function DubitChassis.interface:InitPhysicsStep()
		RunService.Heartbeat:Connect(function(deltaTime: number)
			for _, prototype in pairs(DubitChassis.internal.ChassisRegistry) do
				prototype:ServerStepPhysics(deltaTime)
			end
		end)
	end
	```

	@method ServerStepPhysics
	@within ServerChassis

	@param deltaTime number

	@return ()
]=]
--

function ServerChassis.prototype:ServerStepPhysics(deltaTime: number)
	local primaryPart = self.Chassis.PrimaryPart

	if not primaryPart or (not primaryPart.Anchored and primaryPart:GetNetworkOwner()) then
		return
	end

	for _, attachmentName in ChassisAttachments do
		ServerChassis.internal:ComputeRaycastSuspension(self, attachmentName, deltaTime)
	end
end

--[=[
	This function constructs a new `ServerChassis` component class.

	```lua
	local DubitChassis = require(path-to-module)

	local ServerChassis = DubitChassis.Component.new({
		Tag = "ServerChassis",
	})

	return ServerChassis
	```

	@function new
	@within ServerChassis

	@param data any
	@return ChassisComponent
]=]
--

function ServerChassis.interface.new(...): Types.ChassisComponent
	local chassisComponent = SharedChassis.new(...)

	chassisComponent._internalLifecycleMethods = {}

	for index, object in ServerChassis.prototype do
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

return ServerChassis.interface :: typeof(ServerChassis.interface) & {}
