local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(script.Parent.Parent.Signal)

local DEFAULT_PICKUP_MODEL_RANGE = 10
local SERVER_SIDE_RANGE_VALIDATION_TOLERANCE = 20

--[=[
	@class DubitPickups.Server

	The primary class developers will use to replicate and manipulate pickup objects, this class is responsible for;
	
	- Handling both Player and Global pickups
	- Registering Pickup objects
	- Creating Pickup objects
	- Destroying Pickup objects
]=]
local DubitPickups = {}

DubitPickups.internal = {}
DubitPickups.interface = {}
DubitPickups.objects = {} :: { [Vector3]: { Instance } }
DubitPickups.pickups = {} :: { [string]: internalPickupObject }
DubitPickups.keys = {} :: { [string]: Instance }

DubitPickups.globalPickups = {} :: { keys: { [string]: Model }, positions: { [Vector3]: Model } }
DubitPickups.playerPickups = {} :: { [Player]: { keys: { [string]: Model }, positions: { [Vector3]: Model } } }

DubitPickups.pickupsFolder = ReplicatedStorage:FindFirstChild("ReplicatedDubitPickups") or Instance.new("Folder")
DubitPickups.pickupsFolder.Parent = ReplicatedStorage
DubitPickups.pickupsFolder.Name = "ReplicatedDubitPickups"

DubitPickups.globalPickupsFolder = DubitPickups.pickupsFolder:FindFirstChild("-1") or Instance.new("Folder")
DubitPickups.globalPickupsFolder.Parent = DubitPickups.pickupsFolder
DubitPickups.globalPickupsFolder.Name = "-1"

DubitPickups.pickupRequestEvent = DubitPickups.pickupsFolder:FindFirstChild("PickupRequest")
	or Instance.new("RemoteEvent")
DubitPickups.pickupRequestEvent.Parent = DubitPickups.pickupsFolder
DubitPickups.pickupRequestEvent.Name = "PickupRequest"

DubitPickups.pickupsRemovedCache = {}

DubitPickups.interface.InteractedWith = Signal.new()

function DubitPickups.internal.OnPlayerAdded(_, player: Player)
	local playerFolder = Instance.new("Folder")

	playerFolder.Name = player.UserId
	playerFolder.Parent = DubitPickups.pickupsFolder

	DubitPickups.playerPickups[player] = {
		keys = {},
		positions = {},
	}
end

function DubitPickups.internal.OnPlayerRemoving(_, player: Player)
	local playerFolder = DubitPickups.pickupsFolder:FindFirstChild(tostring(player.UserId))

	if not playerFolder then
		return
	end

	DubitPickups.playerPickups[player] = nil

	playerFolder:Destroy()
end

function DubitPickups.internal.SpawnPickupAt(
	_,
	player: Player?,
	pickupType: string,
	position: Vector3,
	attributes: attributeTypes
)
	local modelContext = DubitPickups.pickups[pickupType]
	local modelReference = modelContext.pickupModelReference
	local modelRange = modelContext.pickupModelRange
	local modelClone = modelReference:Clone() :: Model

	local modelCloneParent = DubitPickups.globalPickupsFolder
	local ownershipTable = DubitPickups.globalPickups

	if player then
		modelClone.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
		modelClone:AddPersistentPlayer(player)

		-- skipping a frame here due to nasty race-conditions, if a game's `PlayerAdded` connection calls
		--     SpawnPickupAt before the libraries `PlayerAdded` connection can setup the player replicated folder
		-- 	   then the library will error out.

		task.wait()

		ownershipTable = DubitPickups.playerPickups[player]
		modelCloneParent = DubitPickups.pickupsFolder:FindFirstChild(tostring(player.UserId))
	end

	modelClone:AddTag(`DubitPickups_PickupObject`)

	modelClone:SetAttribute("PickupType", pickupType)
	modelClone:SetAttribute("PickupPosition", position)
	modelClone:SetAttribute("PickupRange", modelRange)

	if attributes then
		for attribute, value in attributes do
			modelClone:SetAttribute(attribute, value)
		end

		if attributes.Key then
			ownershipTable.keys[attributes.Key] = modelClone
		else
			ownershipTable.positions[position] = modelClone
		end
	else
		ownershipTable.positions[position] = modelClone
	end

	modelClone:PivotTo(CFrame.new(position))

	modelClone.Parent = modelCloneParent
end

--[=[
	Register a 'Pickup' that we can reference to when spawning pickups in the game world.

	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	DubitPickups.Server:RegisterPickup(PickupType.GoldCoin, {
		pickupModel = ReplicatedStorage.Assets.Pickups.GoldCoin,
		pickupRange = 10
	})
	```

	@method RegisterPickup
	@within DubitPickups.Server

	@param pickupType string
	@param pickupSettings { pickupModel: Model, pickupRange: number? }

	@return ()
]=]
--
function DubitPickups.interface.RegisterPickup(
	_,
	pickupType: string,
	pickupSettings: {
		pickupModel: Model,
		pickupRange: number?,
	}
)
	assert(type(pickupSettings.pickupModel) == "userdata", `Expected 'pickupModel' to be an Model Instance!`)
	assert(pickupSettings.pickupModel:IsA("Model"), `Expected 'pickupModel' to be an Model Instance!`)
	assert(pickupSettings.pickupModel.PrimaryPart, `Expected 'pickupModel' to have a PrimaryPart!`)

	assert(not DubitPickups.pickups[pickupType], `Expected '{pickupType}' to be unique! Is this a duplicate pickup?`)

	local internalPickupObject = {}

	internalPickupObject.pickupModelReference = pickupSettings.pickupModel

	internalPickupObject.pickupModelRange = pickupSettings.pickupRange or DEFAULT_PICKUP_MODEL_RANGE

	DubitPickups.pickups[pickupType] = internalPickupObject
end

--[=[
	Create a pickup that should be rendered in the game world, this pickup will spawn at the position passed in as the first argument

	Additionally, this function allows the developer to pass in additional attributes that relate to the model, one of the
		entries in this table can play a role in the persistance of the Pickup, the 'Key' entry - when this is defined
		we can call `:RemovePickup` on a pickup that has this Key

	
	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	DubitPickups.Server:SpawnPickup(PickupType.GoldCoin, Vector3.new(10, 0, 10))

	DubitPickups.Server:SpawnPickup(PickupType.GoldCoin, Vector3.new(10, 10, 10), {
		Key = "SpecialGoldCoin"
	})
	```

	@method SpawnPickup
	@within DubitPickups.Server

	@param pickupType string
	@param position Vector3
	@param attributes { Key: string?, [string]: any }

	@return ()
]=]
--
function DubitPickups.interface.SpawnPickup(_, pickupType: string, position: Vector3, attributes: attributeTypes)
	assert(
		DubitPickups.pickups[pickupType] ~= nil,
		`Expected pickup '{pickupType}' to exist! Unable to find pickup type!`
	)

	DubitPickups.internal:SpawnPickupAt(nil, pickupType, position, attributes)
end

--[=[
	Functionally the same as `:SpawnPickup`, however allows the developer to spawn a pickup for a specific player
	
	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	local player = Players.APlayerName

	DubitPickups.Server:SpawnPickupFor(player, PickupType.GoldCoin, Vector3.new(10, 0, 10))

	DubitPickups.Server:SpawnPickupFor(player, PickupType.GoldCoin, Vector3.new(10, 10, 10), {
		Key = "SpecialGoldCoin"
	})
	```

	@method SpawnPickupFor
	@within DubitPickups.Server

	@param player Player
	@param pickupType string
	@param position Vector3
	@param attributes { Key: string?, [string]: any }

	@return ()
]=]
--
function DubitPickups.interface.SpawnPickupFor(
	_,
	player: Player,
	pickupType: string,
	position: Vector3,
	attributes: attributeTypes
)
	assert(
		DubitPickups.pickups[pickupType] ~= nil,
		`Expected pickup '{pickupType}' to exist! Unable to find pickup type!`
	)

	DubitPickups.internal:SpawnPickupAt(player, pickupType, position, attributes)
end

--[=[
	Remove a pickup that is rendered in the game world, if no 'Key' was provided in the `:SpawnPickup` method, then 
		we will remove the pickups at a position instead

	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	DubitPickups.Server:RemovePickup(PickupType.GoldCoin, Vector3.new(10, 0, 10))

	DubitPickups.Server:RemovePickup(PickupType.GoldCoin, "SpecialGoldCoin")
	```

	@method RemovePickup
	@within DubitPickups.Server

	@param pickupType string
	@param positionOrKey Vector3 | string

	@return ()
]=]
--
function DubitPickups.interface.RemovePickup(_, pickupType: string, positionOrKey: Vector3 | string)
	assert(
		DubitPickups.pickups[pickupType] ~= nil,
		`Expected pickup '{pickupType}' to exist! Unable to find pickup type!`
	)

	local ownershipTable = DubitPickups.globalPickups

	if ownershipTable.keys[positionOrKey] then
		table.insert(DubitPickups.pickupsRemovedCache, ownershipTable.keys[positionOrKey])

		ownershipTable.keys[positionOrKey]:Destroy()
		ownershipTable.keys[positionOrKey] = nil
	elseif ownershipTable.positions[positionOrKey] then
		local object = ownershipTable.positions[positionOrKey]

		table.insert(DubitPickups.pickupsRemovedCache, object)
		object:Destroy()

		ownershipTable.positions[positionOrKey] = nil
	end
end

--[=[
	Functionally the same as `:RemovePickup`, however allows the developer to destroy a pickup for a specific player
	
	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	local player = Players.APlayerName

	DubitPickups.Server:RemovePickupFor(player, PickupType.GoldCoin, Vector3.new(10, 0, 10))

	DubitPickups.Server:RemovePickupFor(player, PickupType.GoldCoin, "SpecialGoldCoin")
	```

	@method RemovePickupFor
	@within DubitPickups.Server

	@param player Player
	@param pickupType string
	@param positionOrKey Vector3 | string

	@return ()
]=]
--
function DubitPickups.interface.RemovePickupFor(_, player: Player, pickupType: string, positionOrKey: Vector3 | string)
	assert(
		DubitPickups.pickups[pickupType] ~= nil,
		`Expected pickup '{pickupType}' to exist! Unable to find pickup type!`
	)

	local ownershipTable = DubitPickups.playerPickups[player]

	if ownershipTable.keys[positionOrKey] then
		table.insert(DubitPickups.pickupsRemovedCache, ownershipTable.keys[positionOrKey])

		ownershipTable.keys[positionOrKey]:Destroy()
		ownershipTable.keys[positionOrKey] = nil
	elseif ownershipTable.positions[positionOrKey] then
		local object = ownershipTable.positions[positionOrKey]

		table.insert(DubitPickups.pickupsRemovedCache, object)
		object:Destroy()

		ownershipTable.positions[positionOrKey] = nil
	end
end

--[=[
	Will remove all pickups for a specific type
	
	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	DubitPickups.Server:RemoveAllPickups(PickupType.GoldCoin)
	```

	@method RemoveAllPickups
	@within DubitPickups.Server

	@param pickupType string

	@return ()
]=]
--
function DubitPickups.interface.RemoveAllPickups(_, pickupType: string)
	assert(
		DubitPickups.pickups[pickupType] ~= nil,
		`Expected pickup '{pickupType}' to exist! Unable to find pickup type!`
	)

	local ownershipTable = DubitPickups.globalPickups

	for position, object in ownershipTable.positions do
		if object:GetAttribute("PickupType") ~= pickupType then
			continue
		end

		DubitPickups.interface:RemovePickup(pickupType, position)
	end

	for key, object in ownershipTable.keys do
		if object:GetAttribute("PickupType") ~= pickupType then
			continue
		end

		DubitPickups.interface:RemovePickup(pickupType, key)
	end
end

--[=[
	Functionally the same as `:RemoveAllPickups`, however allows the developer to destroy all pickup for a specific player
	
	```lua
	local PickupType = require(ReplicatedStorage.Shared.Enums.PickupType)

	local player = Players.APlayerName

	DubitPickups.Server:RemoveAllPickupsFor(player, PickupType.GoldCoin)
	```

	@method RemoveAllPickupsFor
	@within DubitPickups.Server

	@param player Player
	@param pickupType string

	@return ()
]=]
--
function DubitPickups.interface.RemoveAllPickupsFor(_, player: Player, pickupType: string)
	assert(
		DubitPickups.pickups[pickupType] ~= nil,
		`Expected pickup '{pickupType}' to exist! Unable to find pickup type!`
	)

	local ownershipTable = DubitPickups.playerPickups[player]

	for position, object in ownershipTable.positions do
		if object:GetAttribute("PickupType") ~= pickupType then
			continue
		end

		DubitPickups.interface:RemovePickupFor(player, pickupType, position)
	end

	for key, object in ownershipTable.keys do
		if object:GetAttribute("PickupType") ~= pickupType then
			continue
		end

		DubitPickups.interface:RemovePickupFor(player, pickupType, key)
	end
end

function DubitPickups.interface.Initialize(_)
	Players.PlayerRemoving:Connect(function(player: Player)
		DubitPickups.internal:OnPlayerRemoving(player)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		DubitPickups.internal:OnPlayerAdded(player)
	end)

	for _, player: Player in Players:GetPlayers() do
		DubitPickups.internal:OnPlayerAdded(player)
	end

	DubitPickups.pickupRequestEvent.OnServerEvent:Connect(function(player: Player, pickupModels: { Model })
		local playerFolder = DubitPickups.pickupsFolder:FindFirstChild(tostring(player.UserId))
		local globalFolder = DubitPickups.globalPickupsFolder
		local validPickups = {}

		if #pickupModels == 0 then
			return
		end

		for _, model in pickupModels do
			if table.find(DubitPickups.pickupsRemovedCache, model) then
				--[[
					in the rare chance we call `:RemovePickup` and the client had JUST collected that pickup, we should
						not error, but just not acknowledge that pickup.
				]]

				continue
			end

			-- sanity check that the object we have, is a Model - and was instantiated by dubit pickups.
			assert(type(model) == "userdata", `Expected Model, client sent wrong datatype`)
			assert(model:IsA("Model"), `Expected Model, client sent wrong instance`)
			assert(
				model:IsDescendantOf(DubitPickups.pickupsFolder),
				`Expected Model to be owned by DubitPickups, client sent an unknown model`
			)

			local pickupType = model:GetAttribute("PickupType")

			assert(DubitPickups.pickups[pickupType] ~= nil, `Expected Pickup, client sent unknown pickup type`)
			assert(
				model:IsDescendantOf(playerFolder) or model:IsDescendantOf(globalFolder),
				`Expected Pickup to be either owned by the player or the server.`
			)

			local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			assert(humanoidRootPart ~= nil, `Player must have humanoid root part to pick up a pickup`)

			local distance = (model.PrimaryPart.CFrame.Position - humanoidRootPart.CFrame.Position).Magnitude
			local range = DubitPickups.pickups[pickupType].pickupModelRange or DEFAULT_PICKUP_MODEL_RANGE
			assert(
				distance <= range + SERVER_SIDE_RANGE_VALIDATION_TOLERANCE,
				`Player is too far away from the pickup!`
			)

			table.insert(validPickups, model)
		end

		for _, model in validPickups do
			local pickupType = model:GetAttribute("PickupType")

			DubitPickups.interface.InteractedWith:Fire(player, pickupType, model)
		end

		task.defer(function()
			for _, model in validPickups do
				table.insert(DubitPickups.pickupsRemovedCache, model)

				task.delay(60, function()
					local index = table.find(DubitPickups.pickupsRemovedCache, model)

					if index then
						table.remove(DubitPickups.pickupsRemovedCache, index)
					end
				end)

				model:Destroy()
			end
		end)
	end)
end

export type DubitPickups = typeof(DubitPickups.interface)

type attributeTypes = {
	Key: string?,
	[string]: any,
}?

type internalPickupObject = {
	pickupModelReference: Model,
	pickupModelRange: number,
}

return DubitPickups.interface
