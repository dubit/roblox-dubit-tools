--[[
	Roblox Provider - Handling the transaction between datastores, offline/mock datastores and our surface module
]]
--

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local MockDataStoreService = require(script.MockDataStoreService)
local TaskQueueObject = require(script.TaskQueueObject)

local Validator = require(script.Parent.Validator)
local Console = require(script.Parent.Console)

local Promise = require(script.Parent.Parent.Promise)

local UPDATE_ASYNC_PER_REQUEST_YIELD = 2
local GET_ASYNC_PER_REQUEST_YIELD = 5

local MAXIMUM_INTERNAL_HTTP_REQUESTS_PER_MIN = 500
local MAXIMUM_DATASTORE_REQUESTS_PER_MIN = MAXIMUM_INTERNAL_HTTP_REQUESTS_PER_MIN / 3
local NETWORK_QUEUE_FREQUENCY = 0.1

local QUEUE_WORKER_COUNT = 5

local PRODUCTION_BUILD_CHANNEL_NAME = "Production"

local Provider = {}

Provider.reporter = Console:CreateReporter("DubitStore-Provider")

Provider.offlineOrderedDataStorePage = {}

Provider.offlineDataStores = {}
Provider.onlineDataStores = {}

Provider.keysCooldown = {}

Provider.internal = {}
Provider.interface = {}

Provider.networkQueue = TaskQueueObject.new(QUEUE_WORKER_COUNT)

Provider.interface.onlineState = true
Provider.interface.isOffline = RunService:IsStudio() and game.PlaceId == 0
Provider.interface.channel = PRODUCTION_BUILD_CHANNEL_NAME
Provider.interface.datastoreTypes = {
	["Ordered"] = "Ordered",
	["Normal"] = "Normal",
}

Provider.networkQueue:SetFrequency(NETWORK_QUEUE_FREQUENCY)
Provider.networkQueue:SetLimit(MAXIMUM_DATASTORE_REQUESTS_PER_MIN)

--[[
	Wraps our transform function with a validation check to ensure that we can write to the datastore.
]]
--
function Provider.internal:GenerateSessionTransformFunction(datastoreKey, transformFunction)
	return function(value, keyInfo)
		local data, userIds, metadata = transformFunction(value)

		if metadata and metadata.OverwriteSessionId then
			metadata.OverwriteSessionId = nil

			return data, userIds, metadata
		elseif Validator:ValidateSessionIdFromKeyInfo(keyInfo) then
			return data, userIds, metadata
		end

		Provider.reporter:Warn(`Failed to set key "{datastoreKey}" :: Session is already consumed!`)

		metadata = keyInfo and keyInfo:GetMetadata()
		userIds = keyInfo and keyInfo:GetUserIds()

		return value, userIds, metadata
	end
end

--[[
	Wraps our transformFunction into a lambada function that'll be called from inside of a promise.
]]
--
function Provider.internal:WrapSessionTransformFunctionIntoPromise(transformFunction, reject)
	return function(data, keyInfo)
		local information = { pcall(transformFunction, data, keyInfo) }
		local success = table.remove(information, 1)

		if success then
			return table.unpack(information, 1, 3)
		end

		reject(information[1])

		return data, keyInfo and keyInfo:GetUserIds(), keyInfo and keyInfo:GetMetadata()
	end
end

--[[
	QoL method used to fetch an offline/offline datastore based on the 'datastoreType', datastoreType being defined as either an ordered datastore or a generic datastore.
]]
--
function Provider.internal:FetchDataStore(datastoreIdentifier, datastoreType)
	Provider.reporter:Debug(`Fetching datastore '{datastoreIdentifier}' of type '{datastoreType}'`)

	if not Provider.interface.onlineState or Provider.interface.isOffline then
		if Provider.offlineDataStores[datastoreIdentifier] then
			if datastoreType == Provider.interface.datastoreTypes.Normal then
				assert(
					Provider.offlineDataStores[datastoreIdentifier].ClassName == "DataStore",
					`Expected datastore {datastoreIdentifier} to be a generic datastore, instead got ordered datastore.`
				)
			elseif datastoreType == Provider.interface.datastoreTypes.Ordered then
				assert(
					Provider.offlineDataStores[datastoreIdentifier].ClassName == "OrderedDataStore",
					`Expected datastore {datastoreIdentifier} to be a ordered datastore, instead got generic datastore.`
				)
			end
		else
			local datastoreInstance

			if datastoreType == Provider.interface.datastoreTypes.Normal then
				datastoreInstance = MockDataStoreService:GetDataStore(datastoreIdentifier)
			else
				datastoreInstance = MockDataStoreService:GetOrderedDataStore(datastoreIdentifier)
			end

			Provider.offlineDataStores[datastoreIdentifier] = datastoreInstance
		end

		return Provider.offlineDataStores[datastoreIdentifier]
	else
		if Provider.onlineDataStores[datastoreIdentifier] then
			if datastoreType == Provider.interface.datastoreTypes.Normal then
				assert(
					Provider.onlineDataStores[datastoreIdentifier].ClassName == "DataStore",
					`Expected datastore {datastoreIdentifier} to be a generic datastore, instead got ordered datastore.`
				)
			elseif datastoreType == Provider.interface.datastoreTypes.Ordered then
				assert(
					Provider.onlineDataStores[datastoreIdentifier].ClassName == "OrderedDataStore",
					`Expected datastore {datastoreIdentifier} to be a ordered datastore, instead got generic datastore.`
				)
			end
		else
			local datastoreInstance

			if datastoreType == Provider.interface.datastoreTypes.Normal then
				datastoreInstance = DataStoreService:GetDataStore(datastoreIdentifier)
			else
				datastoreInstance = DataStoreService:GetOrderedDataStore(datastoreIdentifier)
			end

			Provider.onlineDataStores[datastoreIdentifier] = datastoreInstance
		end

		return Provider.onlineDataStores[datastoreIdentifier]
	end
end

--[[
	QoL method used to get the state of a key cooldown, cooldowns are used in helping to avoid over-budgeting the Roblox API with requests.
]]
--
function Provider.internal:GetKeyCooldownState(datastoreIdentifier, datastoreKey)
	if not Provider.keysCooldown[datastoreIdentifier] then
		Provider.keysCooldown[datastoreIdentifier] = {}
	end

	return Provider.keysCooldown[datastoreIdentifier][datastoreKey]
end

--[[
	QoL method used to set key cooldown times.
]]
--
function Provider.internal:SetKeyCooldownState(datastoreIdentifier, datastoreKey, state)
	if not Provider.keysCooldown[datastoreIdentifier] then
		Provider.keysCooldown[datastoreIdentifier] = {}
	end

	Provider.keysCooldown[datastoreIdentifier][datastoreKey] = state
end

--[[
	fetches the budget request type for either offline or online datastores.
]]
--
function Provider.interface:GetBudgetForRequestType(DataStoreRequestType)
	if self.isOffline then
		return MockDataStoreService:GetRequestBudgetForRequestType(DataStoreRequestType)
	else
		return DataStoreService:GetRequestBudgetForRequestType(DataStoreRequestType)
	end
end

--[[
	interacting with either datastore or mock datastore to to fetch a DataStorePages instance

	https://create.roblox.com/docs/reference/engine/classes/DataStorePages
]]
--
function Provider.interface:GetSortedAsync(datastoreIdentifier, ascending, pageSize, minValue, maxValue)
	local datastoreInstance = Provider.internal:FetchDataStore(datastoreIdentifier, self.datastoreTypes.Ordered)

	if not self.onlineState or self.isOffline then
		return Promise.new(function(resolve)
			Provider.networkQueue:AddTaskAsync(function()
				resolve(datastoreInstance:GetSortedAsync(ascending, pageSize, minValue, maxValue))
			end)
		end)
	else
		return Promise.new(function(resolve)
			Provider.networkQueue:AddTaskAsync(function()
				resolve(datastoreInstance:GetSortedAsync(ascending, pageSize, minValue, maxValue))
			end)
		end)
	end
end

--[[
	interacting with either datastore or mock datastore to to fetch a DataStoreVersionPages instance

	https://create.roblox.com/docs/reference/engine/classes/DataStoreVersionPages
]]
--
function Provider.interface:ListVersionsAsync(
	datastoreIdentifier,
	datastoreKey,
	sortDirection,
	minDate,
	maxDate,
	pageSize
)
	local datastoreInstance = Provider.internal:FetchDataStore(datastoreIdentifier, self.datastoreTypes.Normal)

	if not self.onlineState or self.isOffline then
		return Promise.new(function(resolve)
			Provider.networkQueue:AddTaskAsync(function()
				resolve(datastoreInstance:ListVersionsAsync(datastoreKey, sortDirection, minDate, maxDate, pageSize))
			end)
		end)
	else
		return Promise.new(function(resolve)
			Provider.networkQueue:AddTaskAsync(function()
				resolve(
					Provider.onlineDataStores[datastoreIdentifier]:ListVersionsAsync(
						datastoreKey,
						sortDirection,
						minDate,
						maxDate,
						pageSize
					)
				)
			end)
		end)
	end
end

--[[
	interacting with either datastore or mock datastore to get the data of a key based on it's version.
]]
--
function Provider.interface:GetVersionAsync(datastoreIdentifier, datastoreKey, version)
	local datastoreInstance =
		Provider.internal:FetchDataStore(datastoreIdentifier, Provider.interface.datastoreTypes.Normal)
	local cooldownKeyName = `GetVersion_{datastoreKey}`

	if not self.onlineState or self.isOffline then
		return Promise.new(function(resolve)
			while Provider.internal:GetKeyCooldownState(datastoreIdentifier, cooldownKeyName) do
				task.wait()
			end

			if Provider.interface.channel == PRODUCTION_BUILD_CHANNEL_NAME then
				Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, true)
			end

			Provider.networkQueue:AddTaskAsync(function()
				task.delay(GET_ASYNC_PER_REQUEST_YIELD, function()
					Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, nil)
				end)

				resolve(datastoreInstance:GetVersion(datastoreKey, version))
			end)
		end)
	else
		return Promise.new(function(resolve)
			while Provider.internal:GetKeyCooldownState(datastoreIdentifier, cooldownKeyName) do
				task.wait()
			end

			local getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)

			while getAsyncBudget < 0 do
				task.wait()

				getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
			end

			Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, true)
			Provider.networkQueue:AddTaskAsync(function()
				task.delay(GET_ASYNC_PER_REQUEST_YIELD, function()
					Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, nil)
				end)

				resolve(datastoreInstance:GetVersionAsync(datastoreKey, version))
			end)
		end)
	end
end

--[[
	interacting with either datastore or mock datastore to get the data of a key.
]]
--
function Provider.interface:GetAsync(datastoreIdentifier, datastoreKey, datastoreType)
	local datastoreInstance = Provider.internal:FetchDataStore(datastoreIdentifier, datastoreType)
	local cooldownKeyName = `Get_{datastoreKey}`

	if not self.onlineState or self.isOffline then
		return Promise.new(function(resolve)
			while Provider.internal:GetKeyCooldownState(datastoreIdentifier, cooldownKeyName) do
				task.wait()
			end

			if Provider.interface.channel == PRODUCTION_BUILD_CHANNEL_NAME then
				Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, true)
			end

			Provider.networkQueue:AddTaskAsync(function()
				task.delay(GET_ASYNC_PER_REQUEST_YIELD, function()
					Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, nil)
				end)

				resolve(datastoreInstance:Get(datastoreKey))
			end)
		end)
	else
		return Promise.new(function(resolve)
			while Provider.internal:GetKeyCooldownState(datastoreIdentifier, cooldownKeyName) do
				task.wait()
			end

			local getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)

			while getAsyncBudget < 0 do
				task.wait()

				getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
			end

			Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, true)
			Provider.networkQueue:AddTaskAsync(function()
				task.delay(GET_ASYNC_PER_REQUEST_YIELD, function()
					Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, nil)
				end)

				resolve(datastoreInstance:GetAsync(datastoreKey))
			end)
		end)
	end
end

--[[
	interacting with either datastore or mock datastore to remove data.
]]
--
function Provider.interface:RemoveAsync(datastoreIdentifier, datastoreKey, datastoreType)
	local datastoreInstance = Provider.internal:FetchDataStore(datastoreIdentifier, datastoreType)

	if not self.onlineState or self.isOffline then
		return Promise.new(function(resolve)
			Provider.networkQueue:AddTaskAsync(function()
				resolve(datastoreInstance:Remove(datastoreKey))
			end)
		end)
	else
		return Promise.new(function(resolve)
			Provider.networkQueue:AddTaskAsync(function()
				resolve(datastoreInstance:RemoveAsync(datastoreKey))
			end)
		end)
	end
end

--[[
	interacting with either datastore or mock datastore to upload data. This method is used for both ordered and normal datastores,
		annotated by the `datastoreType` parameter
]]
--
function Provider.interface:UpdateAsync(datastoreIdentifier, datastoreKey, transformFunction, datastoreType)
	transformFunction = Provider.internal:GenerateSessionTransformFunction(datastoreKey, transformFunction)

	local datastoreInstance = Provider.internal:FetchDataStore(datastoreIdentifier, datastoreType)
	local cooldownKeyName = `Update_{datastoreKey}`

	if not self.onlineState or self.isOffline then
		return Promise.new(function(resolve, reject)
			while Provider.internal:GetKeyCooldownState(datastoreIdentifier, cooldownKeyName) do
				task.wait()
			end

			if Provider.interface.channel == PRODUCTION_BUILD_CHANNEL_NAME then
				Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, true)
			end

			Provider.networkQueue:AddTaskAsync(function()
				transformFunction = Provider.internal:WrapSessionTransformFunctionIntoPromise(transformFunction, reject)

				resolve(datastoreInstance:Update(datastoreKey, transformFunction))

				task.delay(UPDATE_ASYNC_PER_REQUEST_YIELD, function()
					Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, nil)
				end)
			end)
		end)
	else
		return Promise.new(function(resolve, reject)
			while Provider.internal:GetKeyCooldownState(datastoreIdentifier, cooldownKeyName) do
				task.wait()
			end

			local getAsyncBudget
			local setAsyncBudget

			if datastoreType == self.datastoreTypes.Ordered then
				getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
				setAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)

				while getAsyncBudget < 0 or setAsyncBudget < 0 do
					task.wait()

					getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
					setAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)
				end
			else
				getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
				setAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementAsync)

				while getAsyncBudget < 0 or setAsyncBudget < 0 do
					task.wait()

					getAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
					setAsyncBudget = self:GetBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)
				end
			end

			Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, true)
			Provider.networkQueue:AddTaskAsync(function()
				transformFunction = Provider.internal:WrapSessionTransformFunctionIntoPromise(transformFunction, reject)

				resolve(datastoreInstance:UpdateAsync(datastoreKey, transformFunction))

				task.delay(UPDATE_ASYNC_PER_REQUEST_YIELD, function()
					Provider.internal:SetKeyCooldownState(datastoreIdentifier, cooldownKeyName, nil)
				end)
			end)
		end)
	end
end

--[[
	function is called once the game server is starting to shut down, this method will stop all workers under a queue and then block the game
		server from shutting down until all task jobs have been completed
]]
--
function Provider.interface:OnBindToClose()
	if RunService:IsStudio() then
		return
	end

	for _ = 1, QUEUE_WORKER_COUNT do
		Provider.networkQueue:StopWorker()
	end

	while true do
		Provider.networkQueue:Cycle()

		if not Provider.networkQueue:IsActive() then
			return
		end
	end
end

return Provider.interface :: typeof(Provider.interface)
