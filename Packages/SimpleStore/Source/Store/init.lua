local Players = game:GetService("Players")

local DubitStore = require(script.Parent.Parent.DubitStore)
local Sift = require(script.Parent.Parent.Sift)
local Signal = require(script.Parent.Parent.Signal)

local AUTOSAVE_INTERVAL = 5 * 60
local DEFAULT_SPLITTER = "."

local DATA_SCHEMA = "DefaultDataSchema"

DubitStore:CreateDataSchema(DATA_SCHEMA, {
	Data = DubitStore.Container.new(0),
})

--[=[
	@class PlayerDataStore

	A simple wrapper for Player orientated datastores, this is the primary datastore object that developers will be interacting with, it's goal is to make the interaction between loading, saving and manipulating player datastores easier for developers.

	PlayerDataStore's also rely on Session Locking, after 60 seconds, the Session Lock will be overwritten so that the players data isn't stuck forever. A players data is only released when `:Destroy` has been called from the active server.
]=]
local Store = {}

Store.interface = {}
Store.prototype = {}
Store.constructed = {}
Store.constructing = {}

--[=[
	@prop Changed RbxScriptSignal
	@within PlayerDataStore
]=]

--[=[
	Get's the players data from datastore, provides a fallback so if no data is found, the fallback is returned instead.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	local defaultPlayerData = {
		progression = {
			experience = 0,
			level = 0
		}
	}

	local playerData = playerStore:Get(defaultPlayerData)

	local playerExperience = playerData.progression.experience
	local playerLevel = playerData.progression.level
	```

	:::caution warning
		There is no reconciliation happening in the background, meaning if a players data changes over time,
		there's no guarantee that the new data exists for older users.

	---

		A fix for this is running unsanitized data through `Sift.Dictionary.mergeDeep`
		to update old data with new data values!
	:::

	@yields

	@method Get
	@within PlayerDataStore

	@param fallback any -- optional, in case the player has no data, this data will be returned instead.

	@return any, boolean
]=]
--
function Store.prototype:Get(fallback: any?)
	local data = DubitStore:GetDataAsync(self.Datastore, self.Key):expect()
	local dataExists = data ~= nil

	if not dataExists then
		data = DubitStore:ReconcileData(data, DATA_SCHEMA)
		data.Data = fallback

		DubitStore:SetDataAsync(self.Datastore, self.Key, data)
	end

	return data.Data, dataExists
end

--[=[
	If the players data represents a table, you can use this function to get specific parts of that players data. 

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	local defaultPlayerData = {
		progression = {
			experience = 0,
			level = 0
		}
	}

	playerStore:Set(defaultPlayerData)

	local experience = playerStore:GetKey("progression.experience", 0)
	local level = playerStore:GetKey("progression.level", 1)
	```

	@yields

	@method GetKey
	@within PlayerDataStore

	@param path string -- the path will be split by each occurrence of a period (".")
	@param fallback string? -- optional, a fallback to result too if we're unable to index the player data.

	@return any
]=]
--
function Store.prototype:GetKey(path: string, fallback: string?)
	local data = self:Get({})
	local splitPath = string.split(path, DEFAULT_SPLITTER)
	local headNode = data

	for _, nextNode in splitPath do
		if headNode[nextNode] == nil then
			return fallback
		end

		headNode = headNode[nextNode]
	end

	return headNode
end

--[=[
	Overwrite the current players data with a new set of data.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	playerStore:Set({ text = "Hello, World!" })

	print(playerStore:GetKey("text")) -- "Hello, World!"

	playerStore:Set({ text = "Hello, Something else!" })

	print(playerStore:GetKey("text")) -- "Hello, Something else!"
	```

	@yields

	@method Set
	@within PlayerDataStore

	@param data any -- player data can support any input, but inputting a table will allow you to take advantage over things such as `:Merge` and `:GetKey`

	@return ()
]=]
--
function Store.prototype:Set(data: any)
	DubitStore:SetDataAsync(self.Datastore, self.Key, {
		Data = data,
	})

	self.Changed:Fire(self:Get(), data)
end

--[=[
	If the players data represents a table, you can use this function to overwrite specific parts of that players data. 

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	playerStore:Set({
		pets = {
			currentAnimal = {
				animalName = "Fluffy"
			}
		}
	})

	playerStire:GetKey("pets.currentAnimal.animalName") -- Fluffy
	playerStore:SetKey("pets.currentAnimal.animalName", "Joey")
	playerStire:GetKey("pets.currentAnimal.animalName") -- Joey
	```

	@yields

	@method SetKey
	@within PlayerDataStore

	@param path string -- the path will be split by each occurance of a period (".")
	@param data any -- player data can support any input, but inputting a table will allow you to take advantage over things such as `:Merge` and `:GetKey`

	@return ()
]=]
--
function Store.prototype:SetKey(path: string, value: any)
	local updatedData = self:Get()
	local splitPath = string.split(path, DEFAULT_SPLITTER)
	local headNode = updatedData
	local lastNode

	for index, nextNode in splitPath do
		if index ~= 1 then
			lastNode = splitPath[index - 1]
		end

		if headNode[nextNode] == nil then
			error(`Unable to ':SetKey' for player '{self.Key}', unable to find '{nextNode}' in {lastNode or "data"}`)
		end

		if index ~= #splitPath then
			headNode = headNode[nextNode]
		end
	end

	headNode[splitPath[#splitPath]] = value

	self:Set(updatedData)
end

--[=[
	Merge the current player data with an input table, the input table takes priority so it'll overwrite keys in the current player data.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	playerStore:Set({
		text = "Hello, World!",
		boolean = true
	})

	playerStire:GetKey("text") -- "Hello, World!"
	playerStire:GetKey("boolean") -- "true"

	playerStore:Merge({
		text = "Hello, Something else!"
	})

	playerStire:GetKey("text") -- "Hello, Something else!"
	playerStire:GetKey("boolean") -- "true"
	```

	@yields

	@method Merge
	@within PlayerDataStore

	@param tableToBeMerged { [any]: any }

	@return ()
]=]
--
function Store.prototype:Merge(tableToBeMerged: { [any]: any })
	local data = self:Get()

	if typeof(data) ~= "table" then
		error(`Invalid DataType! Expected Table, got '{typeof(data)}'`)
	end

	local updatedData = Sift.Dictionary.mergeDeep(data, tableToBeMerged)

	self:Set(updatedData)
end

--[=[
	If the players data represents a table, you can use this function to merge tables under the player data together, the input table takes priority so it'll overwrite keys in the current player data.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	playerStore:Set({
		pets = {
			currentAnimal = {
				animalName = "Fluffy",
				animalLevel = 0,
				animalExperience = 0,
			}
		}
	})

	playerStore:GetKey("pets.currentAnimal.animalLevel") -- 0
	playerStore:GetKey("pets.currentAnimal.animalName") -- "Fluffy"

	playerStore:MergeKey("pets.currentAnimal", {
		animalLevel = 1
	})

	playerStore:GetKey("pets.currentAnimal.animalLevel") -- 1
	playerStore:GetKey("pets.currentAnimal.animalName") -- "Fluffy"

	```

	@yields

	@method MergeKey
	@within PlayerDataStore

	@param path string -- the path will be split by each occurance of a period (".")
	@param tableToBeMerged { [any]: any }

	@return ()
]=]
--
function Store.prototype:MergeKey(path: string, tableToBeMerged: { [any]: any })
	local data = self:GetKey(path)

	if typeof(data) ~= "table" then
		error(`Invalid DataType! Expected Table, got '{typeof(data)}'`)
	end

	data = Sift.Dictionary.mergeDeep(data, tableToBeMerged)

	return self:SetKey(path, data)
end

--[=[
	Given a transform function, this function will call the transform function with the most up-to-date player data, and will save the return of the transform function.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	playerStore:Update(function(latestPlayerData)
		latestPlayerData.SomethingHasChnaged = true

		return latestPlayerData
	end)
	```

	@yields

	@method Update
	@within PlayerDataStore

	@param transformFunction (serverData: any) -> any

	@return ()
]=]
--
function Store.prototype:Update(transformFunction: (serverData: any) -> any)
	DubitStore:UpdateDataAsync(self.Datastore, self.Key, function(data)
		data = DubitStore:ReconcileData(data, DATA_SCHEMA)
		data = transformFunction(data.Data)

		return data
	end):expect()
end

--[=[
	Given a transform function, this function will call the transform function with the most up-to-date player data, and will save the return of the transform function.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	--[[
		for example, our player data on the datastore is:

		{
			pets = {
				currentAnimal = {
					animalName = "Fluffy",
					animalLevel = 0,
					animalExperience = 0,
				}
			}
		}
	]]
	
	playerStore:UpdateKey("pets.currentAnimal", function(currentAnimalData)
		currentAnimalData.animalName = "Joey"

		return currentAnimalData
	end)
	```

	:::caution warning
		This function will read and write directly to the datastore, and therefore not cache any sort of data!
	:::

	@yields

	@method UpdateKey
	@within PlayerDataStore

	@param path string -- the path will be split by each occurance of a period (".")
	@param transformFunction (serverData: any) -> any

	@return ()
]=]
--
function Store.prototype:UpdateKey(path: string, transformFunction: (serverData: any) -> any)
	DubitStore:UpdateDataAsync(self.Datastore, self.Key, function(data)
		data = DubitStore:ReconcileData(data, DATA_SCHEMA)

		local splitPath = string.split(path, DEFAULT_SPLITTER)
		local headNode = data.Data
		local lastNode

		for index, nextNode in splitPath do
			if index ~= 1 then
				lastNode = splitPath[index - 1]
			end

			if headNode[nextNode] == nil then
				error(
					`Unable to ':UpdateKey' for player '{self.Key}', unable to find '{nextNode}' in {lastNode or "data"}`
				)
			end

			if index ~= #splitPath then
				headNode = headNode[nextNode]
			end
		end

		headNode[splitPath[#splitPath]] = transformFunction(headNode[splitPath[#splitPath]])

		return data
	end):expect()
end

--[=[
	Save the player data to datastore.

	```lua
	local function onPlayerRequestedSave(player)
		local playerStore = SimpleStore:GetPlayerStore(player)
		
		playerStore:Save()
	end
	```

	@yields

	@method Save
	@within PlayerDataStore

	@return ()
]=]
--
function Store.prototype:Save()
	DubitStore:PushAsync(self.Datastore, self.Key, {
		self.Id,
	}):expect()
end

--[=[
	Destroys this player data's instance on this server. Should be called when the player leaves the game.

	```lua
	local function onPlayerRemoving(player)
		local playerStore = SimpleStore:GetPlayerStore(player)
		
		playerStore:Destroy()
	end
	```

	@yields

	@method Destroy
	@within PlayerDataStore

	@return ()
]=]
--
function Store.prototype:Destroy()
	self:Save()

	Store.constructed[self.Datastore][self.Id] = nil

	self.AutosaveConnection:Disconnect()
	self.PlayersConnection:Disconnect()

	DubitStore:CancelAutosave(self.AutosaveId)
	DubitStore:SetDataSessionLocked(self.Datastore, self.Key, false)
end

function Store.interface.new(datastore: string, player: Player): Store
	if not Store.constructing[datastore] then
		Store.constructing[datastore] = {}
	end

	if not Store.constructed[datastore] then
		Store.constructed[datastore] = {}
	end

	while Store.constructing[datastore][player.UserId] do
		task.wait(0.25)
	end

	if Store.constructed[datastore][player.UserId] then
		return Store.constructed[datastore][player.UserId]
	end

	Store.constructing[datastore][player.UserId] = true

	local self = setmetatable({}, {
		__index = Store.prototype,
	})

	--[=[
		@private
		@prop Datastore string
		@within PlayerDataStore
	]=]
	self.Datastore = datastore

	--[=[
		@private
		@prop Id number
		@within PlayerDataStore
	]=]
	self.Id = player.UserId

	--[=[
		@private
		@prop Key string
		@within PlayerDataStore
	]=]
	self.Key = tostring(self.Id)

	--[=[
		@private
		@prop AutosaveId string
		@within PlayerDataStore
	]=]
	self.AutosaveId = `{datastore}_{self.Key}`

	--[=[
		@prop Changed Signal
		@within PlayerDataStore
	]=]
	self.Changed = Signal.new()

	local isSessionUnlocked = false

	task.delay(60, function()
		DubitStore:OverwriteDataSessionLocked(self.Datastore, self.Key, false)

		isSessionUnlocked = true
	end)

	task.spawn(function()
		DubitStore:YieldUntilDataUnlocked(self.Datastore, self.Key)

		isSessionUnlocked = true
	end)

	repeat
		task.wait()
	until isSessionUnlocked

	DubitStore:SetAutosaveInterval(self.AutosaveId, AUTOSAVE_INTERVAL)
	DubitStore:SetDataSessionLocked(self.Datastore, self.Key, true)

	local _, hadDataInDatastore = self:Get({})
	self:Save()

	--[=[
		@prop IsNewPlayer boolean
		@within PlayerDataStore
	]=]
	self.IsNewPlayer = not hadDataInDatastore

	self.AutosaveConnection = DubitStore:OnAutosave(self.AutosaveId):Connect(function()
		self:Save()
	end)

	self.PlayersConnection = Players.PlayerRemoving:Connect(function(leavingPlayer: Player)
		if leavingPlayer.UserId ~= self.Id then
			return
		end

		self:Destroy()
	end)

	Store.constructed[datastore][player.UserId] = self
	Store.constructing[datastore][player.UserId] = nil

	return self
end

export type Store = typeof(Store.prototype)

return Store.interface
