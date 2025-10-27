local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local package = script.Parent.Parent

local Component = require(package.Parent.Component)

local ChassisAttributes = require(package.Enums.ChassisAttributes)

local Types = require(package.Types)

local ITERATION_STEP_VALUE: number = 0.25

--[=[
	@class SharedChassis

	SharedChassis handles any functions shared across both components of the DubitChassis.
]=]

local SharedChassis = {}

SharedChassis.internal = {
	SmoothingAttributes = { ChassisAttributes.SpringRestLength } :: { string },
	PlayerInstances = {} :: { [Player]: Model },
	CharacterIgnoreList = {} :: { Model },
}
SharedChassis.prototype = {}
SharedChassis.interface = {}

function SharedChassis.internal:ListenToPlayerEvents()
	for _, player in (Players:GetPlayers()) do
		SharedChassis.internal:onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		SharedChassis.internal:onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		SharedChassis.internal:onPlayerRemoved(player)
	end)
end

function SharedChassis.internal:onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		SharedChassis.internal.PlayerInstances[player] = character

		table.insert(SharedChassis.internal.CharacterIgnoreList, character)
	end)
end

function SharedChassis.internal:onPlayerRemoved(player: Player)
	player.CharacterAdded:Connect(function(_: Model)
		for index, oldCharacter in SharedChassis.internal.CharacterIgnoreList do
			if oldCharacter ~= SharedChassis.internal.PlayerInstances[player] then
				continue
			end

			table.remove(SharedChassis.internal.CharacterIgnoreList, index)
		end

		SharedChassis.internal.PlayerInstances[player] = nil
	end)
end

function SharedChassis.internal:UpdateAttributeValue(attribute: string, prototype: any)
	local instance = prototype.Chassis

	task.spawn(function()
		local lastAttributeValue = prototype._chassisProperties[attribute]
		local newAttributeValue = instance:GetAttribute(attribute)

		if not table.find(SharedChassis.internal.SmoothingAttributes, attribute) then
			prototype._chassisProperties[attribute] = newAttributeValue

			return
		end

		local iterationValue = if lastAttributeValue > newAttributeValue
			then -ITERATION_STEP_VALUE
			else ITERATION_STEP_VALUE

		for i = lastAttributeValue, newAttributeValue, iterationValue do
			if newAttributeValue ~= instance:GetAttribute(attribute) then
				return
			end

			prototype._chassisProperties[attribute] = i

			RunService.Heartbeat:Wait()
		end
	end)
end

function SharedChassis.internal:UpdateChassisOwnerId(attribute: string, prototype: any)
	local vehicleSeat = prototype.VehicleSeat
	local instance = prototype.Chassis

	task.spawn(function()
		if vehicleSeat.Occupant then
			vehicleSeat.Occupant.Jump = true
		end

		for _, player in Players:GetChildren() do
			if player.UserId ~= instance:GetAttribute(attribute) then
				continue
			end

			local character = player.Character or player.CharacterAdded:Wait()

			prototype:StartDrivingVehicle(character)
			break
		end
	end)
end

--[=[
	Resets all forces currently being applied on the Chassis.

	```lua
	SharedChassis:ResetChassisForces()
	```

	@method ResetChassisForces
	@within SharedChassis

	@return ()
]=]
--

function SharedChassis.prototype:ResetChassisForces()
	if self.Chassis == nil then
		return
	end

	if RunService:IsClient() then
		self._downForceTrackingData.ApplyDownForce = false
		self._downForceTrackingData.TrackingTorque = 0
		self._downForceTrackingData.CurrentDownForce = 0
	end

	for attachmentName, _ in self._tireAttachments do
		self.Chassis.PrimaryPart[attachmentName].VectorForce.Force = Vector3.new(0, 0, 0)
	end

	self.Chassis.PrimaryPart.AlignOrientation.Enabled = false
end

--[=[
	Listens to any attribute changes from the Chassis and replicates the modified data to the components internal properties

	```lua
	SharedChassis:ListenToAttributeChangedEvents()
	```

	@method ListenToAttributeChangedEvents
	@within SharedChassis

	@return ()
]=]
--

function SharedChassis.prototype:ListenToAttributeChangedEvents()
	self._trove:Add(self.TireObject.Changed:Connect(function()
		self.TireObject.Value = self.TireObject.Value

		if RunService:IsServer() then
			self:SetTireInstances()
		end

		self._chassisProperties.TireObject = self.TireObject.Value
		self._chassisWeight = self.Chassis.PrimaryPart:GetMass()
			+ self.Chassis.COG:GetMass()
			+ ((self.TireObject.Value:GetMass() * #self.Chassis.TiresFolder:GetChildren()) / 2)
	end))

	for _, attribute: string in ChassisAttributes do
		self._trove:Add(self.Chassis:GetAttributeChangedSignal(attribute):Connect(function()
			if RunService:IsServer() then
				if attribute == ChassisAttributes.ChassisOwnerId then
					SharedChassis.internal:UpdateChassisOwnerId(attribute, self)
				end
			end

			SharedChassis.internal:UpdateAttributeValue(attribute, self)
		end))
	end
end

--[=[
	Invokes any existing lifecycle methods from the components external counterpart

	```lua
	-- Will invoke the Start lifecycle method from the ServerChassis's external component counterpart
	function ServerChassis.prototype:Start()
		ServerChassis:InvokeLifecycleMethods(CHASSIS_LIFE_CYCLE_METHODS.Start)
	end
	```

	@method InvokeLifecycleMethods
	@within SharedChassis

	@return ()
]=]
--

function SharedChassis.prototype:InvokeLifecycleMethods(lifecycleMethod: string)
	if not self._internalLifecycleMethods or not self._internalLifecycleMethods[lifecycleMethod] then
		return
	end

	self._internalLifecycleMethods[lifecycleMethod](self)
end

--[=[
	This function constructs a new `SharedChassis` component class. This is used within the `ServerChassis` and `ClientChassis` components to inherit the `SharedChassis` component class methods.

	```lua
	-- ServerChassis example
	function ServerChassis.interface.new(...): Types.ChassisComponent
		local chassisComponent = SharedChassis.new(...)
	end

	-- ClientChassis example
	function ClientChassis.interface.new(...): Types.ChassisComponent
		local chassisComponent = SharedChassis.new(...)
	end
	```

	@function new
	@within SharedChassis

	@param data any
	@return ChassisComponent
]=]
--

function SharedChassis.interface.new(...): Types.ChassisComponent
	local chassisComponent = Component.new(...)

	for index, object in SharedChassis.prototype do
		chassisComponent[index] = object
	end

	return setmetatable({}, {
		__index = chassisComponent,
		__newindex = function(_, index, value)
			chassisComponent[index] = value
		end,
	})
end

--[=[
	Returns the `CharacterIgnoreList` internal table

	```lua
	SharedChassis.getActiveCharacters()
	```

	@function getActiveCharacters
	@within SharedChassis

	@return { [Player]: Model }
]=]
--

function SharedChassis.interface:getActiveCharacters(): { [Player]: Model }
	return table.clone(SharedChassis.internal.CharacterIgnoreList)
end

function SharedChassis.interface:Init()
	SharedChassis.internal:ListenToPlayerEvents()

	return SharedChassis.interface
end

return SharedChassis.interface:Init() :: typeof(SharedChassis.interface) & {}
