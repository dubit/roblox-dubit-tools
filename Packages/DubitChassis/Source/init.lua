local RunService = game:GetService("RunService")

local package = script

local Console = require(package.Parent.Console)
local Signal = require(package.Parent.Signal)

local Types = require(script.Types)

local ChassisAttributes = require(script.Enums.ChassisAttributes)

--[=[
	@class DubitChassis

	DubitChassis is a robust automobile physics system that utilizes raycasting to simulate realistic vehicle suspension.

	---

	DubitChassis offers quite a bit of flexibility, as it lets our developers to build on top its component inherited functionality to
	create adaptable automobile components for any project.

	An brief overview on what DubitChassis offers:
	- **Raycast Suspension Physics**
		- DubitChassis uses Raycast Suspension by casting rays and applying VectorForces on each corner of the vehicle to simulate realistic suspension.
		- The raycast suspension method was chosen for this tool, since is  more performant in replicating suspension physics, 
			removes any sleeping constraint/part issues, and offers easier customization and tuning of the chassis.
	- **Attribute-Based Design**
		- With Attributes introduced in this system, it allows developers to dynamically configure the chassis constants in realtime.

	Some of the DubitChassis background handywork:
	- **Network Ownership**
		- DubitChassis uses Network Ownership to distribute physics computations between individual clients and server. This
			reduces client latency for replicating movement for the chassis while also optimizing server performance.
	- **Inheritance Design**
		- The DubitChassis follows the philospohy of being able to provide the logic of the tooling but not BE the logic.
		- With this in mind, DubitChassis uses an inheritance oriented design following a prototype-based class structure. This allows developers 
			to generate a new components with inherited functionality of the DubitChassis while giving them the freedom to customize
			the tool further.
]=]

local DubitChassis = {}

DubitChassis.internal = {
	ChassisRegistry = {},

	ServerSteppedConnection = nil,
	ClientSteppedConnection = nil,
}
DubitChassis.prototype = {}
DubitChassis.interface = {
	OnChassisRegistered = Signal.new(),
	OnChassisRemoved = Signal.new(),
	OnStepPhysicsSuccessful = Signal.new(),
	OnStartPhysicsStep = Signal.new(),
	OnStopPhysicsStep = Signal.new(),

	--[[ We expose the Reporter class so our TestEz Runner scripts can access it ]]
	Reporter = Console.new("DubitChassis"),
}

function DubitChassis.internal:AddChassisToRegistry(prototype: any)
	self.ChassisRegistry[prototype.Chassis] = prototype

	local platform = if RunService:IsServer() then "Server" else "Client"

	DubitChassis.interface.Reporter:Log(
		platform .. " " .. tostring(prototype.Chassis) .. " has been added to the ChassisRegistry!"
	)

	DubitChassis.interface.OnChassisRegistered:Fire()
end

function DubitChassis.internal:RemoveChassisToRegistry(prototype: any)
	if not prototype.Chassis or not self.ChassisRegistry[prototype.Chassis] then
		DubitChassis.interface.Reporter:Warn(
			tostring(prototype.Chassis) .. " removed does not exist in the ChassisRegistry!"
		)
		return
	end

	self.ChassisRegistry[prototype.Chassis] = nil

	local platform = if RunService:IsServer() then "Server" else "Client"

	DubitChassis.interface.Reporter:Log(
		platform .. " " .. tostring(prototype.Chassis) .. " has been removed from the ChassisRegistry!"
	)

	DubitChassis.interface.OnChassisRemoved:Fire()
end

--[=[
	This function will loop through existing object classes from the ChassisRegistry table and invokes the passed method.
	This function is called internally via the `:StartPhysicsStep()` function.

	```lua
	-- Server implementation
	DubitChassis:StepPhysics(deltaTime, "ServerStepPhysics")

	-- Client implementation
	DubitChassis:StepPhysics(deltaTime, "ClientStepPhysics")
	```

	@method StepPhysics
	@within DubitChassis


	@return ()
]=]
--

function DubitChassis.interface:StepPhysics(deltaTime: number, method: string)
	for instance, prototype in pairs(DubitChassis.internal.ChassisRegistry) do
		if instance == nil or prototype == nil then
			DubitChassis.interface.Reporter:Log("Detected an empty instance index in ChassisRegistry: ", prototype)
			continue
		end

		prototype[method](prototype, deltaTime)

		self.OnStepPhysicsSuccessful:Fire()
	end
end

--[=[
	This function will start `Stepped` functions for handling physics in a global scope.

	```lua
	-- Must be started on both the Server and Client
	DubitChassis:StartPhysicsStep()
	```

	@method StartPhysicsStep
	@within DubitChassis


	@return ()
]=]
--

function DubitChassis.interface:StartPhysicsStep()
	if RunService:IsServer() then
		DubitChassis.internal.ServerSteppedConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
			self:StepPhysics(deltaTime, "ServerStepPhysics")
		end)
	else
		DubitChassis.internal.ClientSteppedConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
			self:StepPhysics(deltaTime, "ClientStepPhysics")
		end)
	end

	self.OnStartPhysicsStep:Fire()
end

--[=[
	This function will stop any active `Stepped` connections.

	```lua
	DubitChassis:StopPhysicsStep()
	```

	@method StopPhysicsStep
	@within DubitChassis


	@return ()
]=]
--

function DubitChassis.interface:StopPhysicsStep()
	if RunService:IsServer() then
		if not DubitChassis.internal.ServerSteppedConnection then
			DubitChassis.interface.Reporter:Error("ServerSteppedConnection connection does not exist!")
			return
		end

		DubitChassis.internal.ServerSteppedConnection:Disconnect()
	else
		if not DubitChassis.internal.ClientSteppedConnection then
			DubitChassis.interface.Reporter:Error("ClientSteppedConnection connection does not exist!")
			return
		end

		DubitChassis.internal.ClientSteppedConnection:Disconnect()
	end

	self.OnStopPhysicsStep:Fire()
end

--[=[
	Gets the prototype of a component from the given Roblox instance. Returns nil if not found.

	```lua
	DubitChassis:FromInstance(instance)
	```

	@method FromInstance
	@within DubitChassis

	@return ()
]=]
--

function DubitChassis.interface:FromInstance(instance: Model)
	return DubitChassis.internal.ChassisRegistry[instance]
end

--[=[
	This function will return the number of chassis currently active

	```lua
	DubitChassis:GetChassisCount()
	```

	@method GetChassisCount
	@within DubitChassis

	@server

	@return number
]=]
--

function DubitChassis.interface:GetChassisCount(): number
	DubitChassis.interface.Reporter:Assert(RunService:IsServer(), "Attempted to invoke a server method on the client.")

	return #DubitChassis.interface:GetAllChassisInstances()
end

--[=[
	This function will return all chassis instances in the game

	```lua
	DubitChassis:GetAllChassisInstances()
	```

	@method GetAllChassisInstances
	@within DubitChassis

	@server

	@return { Instance? }
]=]
--

function DubitChassis.interface:GetAllChassisInstances(): { Model? }
	DubitChassis.interface.Reporter:Assert(RunService:IsServer(), "Attempted to invoke a server method on the client.")

	local instanceTable: { Model? } = {}

	for instance, _ in DubitChassis.internal.ChassisRegistry do
		table.insert(instanceTable, instance)
	end

	table.freeze(instanceTable)

	return instanceTable
end

--[=[
	This function will return the chassis instance given the player

	```lua
	DubitChassis:GetPlayerOwnedChassis(player)
	```

	@method GetPlayerOwnedChassis
	@within DubitChassis

	@server

	@return Instance?
]=]
--

function DubitChassis.interface:GetPlayerOwnedChassis(player: Player): Model?
	DubitChassis.interface.Reporter:Assert(RunService:IsServer(), "Attempted to invoke a server method on the client.")
	DubitChassis.interface.Reporter:Assert(player, "'player' parameter is empty!")

	for instance, _ in DubitChassis.internal.ChassisRegistry do
		if not instance:GetAttribute(ChassisAttributes.ChassisOwnerId) then
			continue
		end

		if instance:GetAttribute(ChassisAttributes.ChassisOwnerId) == player.UserId then
			return instance
		end
	end
end

--[=[
	This function will remove all chassis in game

	```lua
	DubitChassis:RemoveAllChassis()
	```

	@method RemoveAllChassis
	@within DubitChassis

	@server

	@return ()
]=]
--

function DubitChassis.interface:RemoveAllChassis(): ()
	DubitChassis.interface.Reporter:Assert(RunService:IsServer(), "Attempted to invoke a server method on the client.")

	for _, prototype in DubitChassis.internal.ChassisRegistry do
		prototype:Stop()
	end
end

--[=[
	This function will globally set attributes for all active chassis in-game. 

	```lua
	DubitChassis:SetGlobalChassisAttributes({SpringRestLength = 3, Stiffness = 170, MaxSpeed = 25})
	```

	@method SetGlobalChassisAttributes
	@within DubitChassis

	@server

	@param chassisAttributes { [string]: number }

	@return ()
]=]
--

function DubitChassis.interface:SetGlobalChassisAttributes(attributes: { [string]: number }): ()
	DubitChassis.interface.Reporter:Assert(RunService:IsServer(), "Attempted to invoke a server method on the client.")

	for attributeName, value in attributes do
		if not ChassisAttributes[attributeName] then
			DubitChassis.interface.Reporter:Error(attributeName .. " does not exist.")
			return
		end

		if not tonumber(value) then
			DubitChassis.interface.Reporter:Error("value passed is not a [number] type.")
			return
		end
	end

	for instance, _ in DubitChassis.internal.ChassisRegistry do
		for attributeName, value in attributes do
			if not instance:GetAttribute(attributeName) then
				DubitChassis.interface.Reporter:warn(
					attributeName .. " does not exist under " .. tostring(instance) .. "!"
				)

				continue
			end

			if attributeName == ChassisAttributes.ChassisOwnerId then
				DubitChassis.interface.Reporter:warn(ChassisAttributes.ChassisOwnerId .. " cannot be set globally!")
				continue
			end

			instance:SetAttribute(attributeName, value)
		end
	end
end

function DubitChassis.interface:Init()
	--[=[
	@prop Component ServerChassis | ClientChassis
	@within DubitChassis
	]=]
	--
	if RunService:IsServer() then
		self.Component = require(script.Components.ServerChassis)
	elseif RunService:IsClient() then
		self.Component = require(script.Components.ClientChassis)
	end

	self.Component.ChassisAdded:Connect(function(prototype: any)
		DubitChassis.internal:AddChassisToRegistry(prototype)
	end)

	self.Component.ChassisRemoved:Connect(function(prototype: any)
		DubitChassis.internal:RemoveChassisToRegistry(prototype)
	end)

	return self
end

return DubitChassis.interface:Init() :: Types.DubitChassis & {
	Component: Types.DubitChassisComponent,
}
