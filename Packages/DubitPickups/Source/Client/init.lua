local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Signal = require(script.Parent.Parent.Signal)

local SpatialHashGrid = require(script.SpatialHashGrid)

local QUERY_PICKUP_RANGE = 100

--[=[
	@class DubitPickups.Client

	DubitPickups Client implementation has two purposes:

	- Rendering the Pickups that are replicated in from the Server.
	- Handling the proximity to a pickup object.

	As of writing this (v0.1.0), there is not much of an Api for the client - as all pickups should be instantiated and handled through
		the server API
]=]
local DubitPickups = {}

DubitPickups.hashGrid = SpatialHashGrid.new()

DubitPickups.internal = {}
DubitPickups.interface = {}
DubitPickups.attributes = {}

DubitPickups.worldPickupFolder = Instance.new("Folder")
DubitPickups.worldPickupFolder.Name = "DubitPickups"
DubitPickups.worldPickupFolder.Parent = workspace

DubitPickups.pickupsFolder = ReplicatedStorage:WaitForChild("ReplicatedDubitPickups") :: Folder
DubitPickups.pickupRequestEvent = DubitPickups.pickupsFolder:WaitForChild("PickupRequest") :: RemoteEvent
DubitPickups.globalPickupsFolder = DubitPickups.pickupsFolder:WaitForChild("-1") :: Folder
DubitPickups.localPlayerPickupsFolder =
	DubitPickups.pickupsFolder:WaitForChild(tostring(Players.LocalPlayer.UserId)) :: Folder

--[=[
	@prop InteractedWith Signal<Model>
	@within DubitPickups.Client
]=]
DubitPickups.interface.InteractedWith = Signal.new()

--[=[
	@prop PickupSpawned Signal<Model, string>
	@within DubitPickups.Client
]=]
DubitPickups.interface.PickupSpawned = Signal.new()

function DubitPickups.internal.OnPickupAdded(_, pickupModel: Model, pickupContext: string)
	local attributesTable = {}

	attributesTable = table.clone(pickupModel:GetAttributes())

	DubitPickups.attributes[pickupModel] = attributesTable

	local modelWorldPosition = attributesTable.PickupPosition

	pickupModel.Name = `DubitPickup-{pickupContext}`
	pickupModel.Destroying:Once(function()
		DubitPickups.hashGrid:RemoveObject(pickupModel)
	end)

	local pickupType = pickupModel:GetAttribute("PickupType")

	task.defer(function()
		pickupModel.Parent = DubitPickups.worldPickupFolder
	end)

	DubitPickups.hashGrid:AddObject(modelWorldPosition, pickupModel)

	DubitPickups.interface.PickupSpawned:Fire(pickupModel, pickupType)
end

--[=[
	Updates the internal PickupPosition attribute for this particular model

	This is useful if the client plays effects to distribute the pickups in slightly different locations
	from what the server provides (for example, the client may animate the position of the pickup to a slightly new
	location)

	@method UpdatePickupPosition
	@within DubitPickups.Client

	@param pickupModel Model
	@param newPosition Vector3

	@return ()
]=]
function DubitPickups.interface.UpdatePickupPosition(_, pickupModel: Model, newPosition: Vector3)
	if not DubitPickups.attributes[pickupModel] then
		return
	end

	DubitPickups.attributes[pickupModel].PickupPosition = newPosition
	pickupModel:SetAttribute("PickupPosition", newPosition)

	DubitPickups.hashGrid:RemoveObject(pickupModel)
	DubitPickups.hashGrid:AddObject(newPosition, pickupModel)
end

function DubitPickups.interface.Initialize(_)
	DubitPickups.localPlayerPickupsFolder.ChildAdded:Connect(function(child: Instance)
		DubitPickups.internal:OnPickupAdded(child, "Local")
	end)

	DubitPickups.globalPickupsFolder.ChildAdded:Connect(function(child: Instance)
		DubitPickups.internal:OnPickupAdded(child, "Global")
	end)

	for _, pickupModel in DubitPickups.localPlayerPickupsFolder:GetChildren() do
		task.defer(function()
			DubitPickups.internal:OnPickupAdded(pickupModel, "Local")
		end)
	end

	for _, pickupModel in DubitPickups.globalPickupsFolder:GetChildren() do
		task.defer(function()
			DubitPickups.internal:OnPickupAdded(pickupModel, "Global")
		end)
	end

	task.defer(function()
		while true do
			RunService.Heartbeat:Wait()

			local character = Players.LocalPlayer.Character

			if not character or not character.PrimaryPart then
				continue
			end

			local characterWorldPosition = character.PrimaryPart.Position
			local objects = DubitPickups.hashGrid:InRange(characterWorldPosition, QUERY_PICKUP_RANGE)

			local objectsToDestruct = {}
			local doDestructAnyObjects = false

			for _, object in objects do
				local attributes = DubitPickups.attributes[object]

				if (characterWorldPosition - attributes.PickupPosition).Magnitude > attributes.PickupRange then
					continue
				end

				table.insert(objectsToDestruct, object)
				doDestructAnyObjects = true

				DubitPickups.interface.InteractedWith:Fire(attributes.PickupType :: string, object :: Model)
			end

			if doDestructAnyObjects then
				-- we wait a frame here to allow the developer to clone the object, and animate that object in any given way.
				task.wait()

				local objectsThatExist = {}

				for _, object in objectsToDestruct do
					if not object.Parent then
						continue
					end

					table.insert(objectsThatExist, object)
				end

				DubitPickups.pickupRequestEvent:FireServer(objectsThatExist)

				for _, object in objectsThatExist do
					DubitPickups.hashGrid:RemoveObject(object)
					object:Destroy()
				end
			end
		end
	end)
end

return DubitPickups.interface
