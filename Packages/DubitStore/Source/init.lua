--[[
	Roblox DubitStore:
		A feature-rich Roblox DataStore wrapper.
]]
--

local HttpService = game:GetService("HttpService")

local Types = require(script.Types)
local Console = require(script.Console)

local ConsoleLib = require(script.Parent.Console)
local Promise = require(script.Parent.Promise)
local Sift = require(script.Parent.Sift)
local Signal = require(script.Parent.Signal)

local ROBLOX_GET_CACHE_TIME = 7
local TIMES_TO_RETRY_DATA_GET = 3
local YIELD_FOR_DATA_UNLOCKING = 4

local MIN_AUTOSAVE_INTERVAL = 10
local MAX_YIELD_FOR_SESSION_LOCKING = ROBLOX_GET_CACHE_TIME * TIMES_TO_RETRY_DATA_GET

local MAX_THREADS_AWAITING_FOR_GET = 5

local DubitStore = {}

DubitStore.reporter = Console:CreateReporter("DubitStore")

DubitStore.interface = {
	Provider = require(script.Provider),
	Validator = require(script.Validator),
	Serialisation = require(script.Serialisation),

	Container = require(script.Container),
	Middleware = require(script.Middleware),

	GetRequestFailed = Signal.new(),
	SetRequestFailed = Signal.new(),
	OrderedGetRequestFailed = Signal.new(),
	OrderedSetRequestFailed = Signal.new(),
	DataCorrupted = Signal.new(),
	PushCompleted = Signal.new(),
}
DubitStore.schemas = {}

DubitStore.middleware = {}

DubitStore.internal = {}

DubitStore.autosave = {}
DubitStore.cached = {}
DubitStore.metadata = {}
DubitStore.pulling = {}
DubitStore.awaitingThreads = {}

DubitStore.autosave.threads = {}
DubitStore.autosave.signals = {}

--[[
	Errors if the datastoreKey is neither a player or a string, will return the stringified version of a user id if the input is a player.
]]
--
function DubitStore.internal:AssertDataStoreKey(datastoreKey: string | Player)
	if type(datastoreKey) == "userdata" then
		assert(datastoreKey:IsA("Player"), "Expected parameter #2 'datastoreKey' to represent a string or player type")

		datastoreKey = tostring(datastoreKey.UserId)
	else
		assert(
			typeof(datastoreKey) == "string",
			"Expected parameter #2 'datastoreKey' to represent a string or player type"
		)
	end

	return datastoreKey
end

--[[
	Invoking a chain of middleware objects in order to mutate a state instance.
]]
--
function DubitStore.internal:InvokeMiddleware(state: { any: any }, middlewareActionType: Types.MiddlewareActionType)
	assert(
		DubitStore.interface.Middleware.action[middlewareActionType],
		"Expected parameter #2 'middlewareActionType' to represent a middlewareActionType"
	)

	if type(state) ~= "table" then
		return state
	end

	for _, middleware in DubitStore.middleware do
		local response = middleware:Call(state, middlewareActionType)

		if response then
			state = response
		end
	end

	return state
end

function DubitStore.interface:SetVerbosity(isVerbose: boolean): ()
	Console:SetLogLevel(isVerbose and ConsoleLib.LogLevel.Debug or ConsoleLib.LogLevel.Warn)
end

function DubitStore.interface:GetSizeInBytes(datastoreIdentifier: string, datastoreKey: string | Player): number
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	if not DubitStore.cached[datastoreIdentifier] then
		error(`Expected cache buildup, no cache found for {datastoreIdentifier}`)
	end

	if not DubitStore.cached[datastoreIdentifier][datastoreKey] then
		error(`Expected cache buildup for key, no cache found for {datastoreIdentifier}/{datastoreKey}`)
	end

	local success, dataSize =
		pcall(HttpService.JSONEncode, HttpService, DubitStore.cached[datastoreIdentifier][datastoreKey].data)

	if not success then
		return 0
	end

	return string.len(dataSize)
end

function DubitStore.interface:IsOffline(): boolean
	return DubitStore.interface.Provider.isOffline and not DubitStore.interface.Provider.onlineState
end

function DubitStore.interface:SetOnlineState(state: boolean): ()
	DubitStore.reporter:Debug(`Set 'offline' state to: {state}`)

	DubitStore.interface.Provider.onlineState = state
end

function DubitStore.interface:SetDevelopmentChannel(channel: string): ()
	DubitStore.reporter:Debug(`Set 'development' channel to: {channel}`)

	DubitStore.interface.Provider.channel = channel
end

function DubitStore.interface:GetDevelopmentChannel(): string
	return DubitStore.interface.Provider.channel
end

function DubitStore.interface:ImplementMiddleware(middleware: Types.MiddlewareObject): Types.MiddlewareObject
	assert(self.Middleware.is(middleware), "Expected parameter #1 'middleware' to represent a middleware type")

	table.insert(DubitStore.middleware, middleware)

	return middleware
end

function DubitStore.interface:RemoveMiddleware(middleware: Types.MiddlewareObject): Types.MiddlewareObject
	assert(self.Middleware.is(middleware), "Expected parameter #1 'middleware' to represent a middleware type")

	local setIndex = table.find(DubitStore.middleware.setters, middleware)

	if setIndex then
		table.remove(DubitStore.middleware, setIndex)
	end

	return middleware
end

function DubitStore.interface:GenerateRawTable(schemaTable: Types.Schema): { any }
	local success, exceptionMessage = self:ValidateDataSchema(schemaTable)

	assert(success, exceptionMessage)

	local generatedTable = {}

	for index, container in schemaTable do
		if container:ToDataType() == "table" then
			generatedTable[index] = self:GenerateRawTable(container:ToValue())
		else
			generatedTable[index] = container:ToValue()
		end
	end

	return generatedTable
end

function DubitStore.interface:ValidateDataSchema(schemaTable: Types.Schema): (boolean, string)
	for key, container in schemaTable do
		if typeof(key) ~= "string" then
			return false, `Expected 'key' in 'schemaTable' to be a 'string', got {typeof(key)} instead`
		end

		if not self.Container.is(container) then
			return false, `Expected 'value' in 'schemaTable' to be a 'Container', got {typeof(container)} instead`
		end

		if container:ToDataType() == "table" then
			local success, exceptionMessage = self:ValidateDataSchema(container:ToValue())

			if not success then
				return false, exceptionMessage
			end
		end
	end

	return true
end

function DubitStore.interface:CreateDataSchema(schemaIdentifier: string, schemaTable: Types.Schema): ()
	assert(
		DubitStore.schemas[schemaIdentifier] == nil,
		`Schema {schemaIdentifier} already exists in the DubitStore, please allocate a unique identifier.`
	)
	assert(typeof(schemaTable) == "table", "Expected parameter #2 'schemaTable' to represent a table type")

	local success, exceptionMessage = self:ValidateDataSchema(schemaTable)

	assert(success, exceptionMessage)

	DubitStore.schemas[schemaIdentifier] = schemaTable
	DubitStore.reporter:Debug(`Registered the '{schemaIdentifier}' data schema`)
end

function DubitStore.interface:GetDataSchema(schemaIdentifier: string): Types.Schema
	assert(
		DubitStore.schemas[schemaIdentifier] ~= nil,
		`Schema {schemaIdentifier} does not exist in DubitStore, please allocate a schema.`
	)

	return DubitStore.schemas[schemaIdentifier]
end

function DubitStore.interface:SchemaExists(schemaIdentifier: string): boolean
	return DubitStore.schemas[schemaIdentifier] ~= nil
end

function DubitStore.interface:ReconcileData(data: { any }, schemaIdentifier: string): { any }
	assert(typeof(schemaIdentifier) == "string", "Expected parameter #2 'schemaIdentifier' to represent a string type")
	assert(
		DubitStore.schemas[schemaIdentifier] ~= nil,
		`Schema {schemaIdentifier} does not exist in DubitStore, please allocate a schema.`
	)

	local schemaTable = self:GetDataSchema(schemaIdentifier)
	local rawSchemaTable = self:GenerateRawTable(schemaTable)

	if not data then
		return rawSchemaTable
	end

	return Sift.Dictionary.mergeDeep(rawSchemaTable, data)
end

function DubitStore.interface:OnAutosave(datastoreIdentifier: string): RBXScriptSignal
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	if not DubitStore.autosave.signals[datastoreIdentifier] then
		DubitStore.autosave.signals[datastoreIdentifier] = Signal.new()
	end

	return DubitStore.autosave.signals[datastoreIdentifier]
end

function DubitStore.interface:InvokeAutosave(datastoreIdentifier: string): ()
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	DubitStore.reporter:Debug(`Autosave '{datastoreIdentifier}' invoked`)

	if not DubitStore.autosave.signals[datastoreIdentifier] then
		return
	end

	DubitStore.autosave.signals[datastoreIdentifier]:Fire()
end

function DubitStore.interface:CancelAutosave(datastoreIdentifier: string): ()
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	if not DubitStore.autosave.threads[datastoreIdentifier] then
		return
	end

	task.cancel(DubitStore.autosave.threads[datastoreIdentifier])

	DubitStore.reporter:Debug(`Cancelled '{datastoreIdentifier}' autosave background task`)
	DubitStore.autosave.threads[datastoreIdentifier] = nil
end

function DubitStore.interface:SetAutosaveInterval(datastoreIdentifier: string, interval: number): ()
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(typeof(interval) == "number", "Expected parameter #2 'interval' to represent a number type")
	assert(
		interval >= MIN_AUTOSAVE_INTERVAL,
		`Expected parameter #2 'interval' to represent a number above or equal to {MIN_AUTOSAVE_INTERVAL}`
	)

	assert(DubitStore.autosave.threads[datastoreIdentifier] == nil, `{datastoreIdentifier} already an autosaving task`)

	DubitStore.reporter:Debug(`Spawned '{datastoreIdentifier}' autosave background task`)
	DubitStore.autosave.threads[datastoreIdentifier] = task.spawn(function()
		while true do
			task.wait(interval)

			self:InvokeAutosave(datastoreIdentifier)
		end
	end)
end

function DubitStore.interface:ClearCache(datastoreIdentifier: string, datastoreKey: string | Player): ()
	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Clearing cache for '{datastoreIdentifier}/{datastoreKey}'`)

	if datastoreKey then
		if DubitStore.awaitingThreads[datastoreIdentifier] then
			local awaitingThreads = DubitStore.awaitingThreads[datastoreIdentifier][datastoreKey] or 0

			if awaitingThreads ~= 0 then
				DubitStore.reporter:Warn(
					`Potential thread overload, please make sure you're adding a delay before clearing the cache. Thread count: {awaitingThreads}`
				)

				if awaitingThreads > MAX_THREADS_AWAITING_FOR_GET then
					DubitStore.reporter:Error(
						`Thread overload detected, please make sure you're adding a delay before clearing cache! Thread count: {awaitingThreads}`
					)
				end
			end
		end

		if DubitStore.cached[datastoreIdentifier] then
			DubitStore.cached[datastoreIdentifier][datastoreKey] = nil
		end

		if DubitStore.metadata[datastoreIdentifier] then
			DubitStore.metadata[datastoreIdentifier][datastoreKey] = nil
		end
	else
		DubitStore.cached[datastoreIdentifier] = nil
		DubitStore.metadata[datastoreIdentifier] = nil
	end
end

function DubitStore.interface:YieldUntilDataUnlocked(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	maximumYieldTime: number?
): boolean
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	local yielding = true

	local data, metadata
	local routine = coroutine.running()

	maximumYieldTime = maximumYieldTime or MAX_YIELD_FOR_SESSION_LOCKING

	task.delay(maximumYieldTime, function()
		if yielding then
			yielding = false

			coroutine.resume(routine, false)
		end
	end)

	task.spawn(function()
		while yielding do
			local success, response = self.Provider
				:GetAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Normal)
				:andThen(function(latestData, keyInfo)
					if self.Validator:ValidateSessionIdFromKeyInfo(keyInfo) then
						data = latestData
						metadata = keyInfo and keyInfo:GetMetadata()
						metadata = (metadata and metadata.devMetadata) or {}
						yielding = false

						coroutine.resume(routine, true)
					end
				end)
				:await()

			if not success then
				DubitStore.reporter:Warn(`Call ':YieldUntilDataUnlocked' failed, going to re-try! \n{response}`)
			end

			task.wait(YIELD_FOR_DATA_UNLOCKING)
		end
	end)

	local status = coroutine.yield()

	if status then
		if not DubitStore.cached[datastoreIdentifier] then
			DubitStore.cached[datastoreIdentifier] = {}
		end

		if not DubitStore.cached[datastoreIdentifier][datastoreKey] then
			data = DubitStore.internal:InvokeMiddleware(data, self.Middleware.action.Get)

			DubitStore.cached[datastoreIdentifier][datastoreKey] = { data = data, metadata = metadata }
		end
	end

	return status
end

function DubitStore.interface:SetDataSessionLocked(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	locked: boolean?
): ()
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(
		typeof(locked) == "boolean" or typeof(locked) == "nil",
		"Expected parameter #3 'locked' to represent a boolean/nil type"
	)

	if self.Provider.isOffline or not self.Provider.onlineState then
		DubitStore.reporter:Debug(`Not setting session lock! DubitStore is being ran under either Studio or Dev place!`)

		return
	end

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	if not DubitStore.metadata[datastoreIdentifier] then
		DubitStore.metadata[datastoreIdentifier] = {}
	end

	if not DubitStore.metadata[datastoreIdentifier][datastoreKey] then
		DubitStore.metadata[datastoreIdentifier][datastoreKey] = {}
	end

	DubitStore.reporter:Debug(
		`Set session lock for '{datastoreIdentifier}/{datastoreKey}' to {locked}, please ensure you call ':PushAsync'!`
	)

	if locked then
		DubitStore.metadata[datastoreIdentifier][datastoreKey].SessionId = game.JobId
	else
		DubitStore.metadata[datastoreIdentifier][datastoreKey].SessionId = nil
	end
end

function DubitStore.interface:OverwriteDataSessionLocked(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	locked: boolean?
): ()
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(
		typeof(locked) == "boolean" or typeof(locked) == "nil",
		"Expected parameter #3 'locked' to represent a boolean/nil type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	if not DubitStore.metadata[datastoreIdentifier] then
		DubitStore.metadata[datastoreIdentifier] = {}
	end

	if not DubitStore.metadata[datastoreIdentifier][datastoreKey] then
		DubitStore.metadata[datastoreIdentifier][datastoreKey] = {}
	end

	DubitStore.metadata[datastoreIdentifier][datastoreKey].OverwriteSessionId = true

	DubitStore.reporter:Debug(
		`Overwritten session lock for '{datastoreIdentifier}/{datastoreKey}' to {locked}, please ensure you call ':PushAsync'!`
	)

	if locked then
		DubitStore.metadata[datastoreIdentifier][datastoreKey].SessionId = game.JobId
	else
		DubitStore.metadata[datastoreIdentifier][datastoreKey].SessionId = nil
	end
end

function DubitStore.interface:SyncDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	reconciler: (data: any, response: any) -> any
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	return Promise.new(function(resolve, reject)
		if not DubitStore.cached[datastoreIdentifier] then
			reject(`Expected cache buildup, no cache found for {datastoreIdentifier}`)
		end

		if not DubitStore.cached[datastoreIdentifier][datastoreKey] then
			reject(`Expected cache buildup for key, no cache found for {datastoreIdentifier}/{datastoreKey}`)
		end

		local success, response =
			self.Provider:GetAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Normal):await()

		if not success then
			DubitStore.interface.GetRequestFailed:Fire(datastoreIdentifier, datastoreKey, response)

			reject(response)
		end

		response = DubitStore.internal:InvokeMiddleware(response, self.Middleware.action.Get)

		if reconciler then
			DubitStore.cached[datastoreIdentifier][datastoreKey][1] =
				reconciler(DubitStore.cached[datastoreIdentifier][datastoreKey].data, response)
		else
			DubitStore.cached[datastoreIdentifier][datastoreKey][1] =
				Sift.Dictionary.mergeDeep(response, DubitStore.cached[datastoreIdentifier][datastoreKey].data)
		end

		DubitStore.reporter:Debug(
			`Synced cache '{datastoreIdentifier}/{datastoreKey}' with latest data from DataStores!`
		)

		resolve()
	end)
end

function DubitStore.interface:GetMetaDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	return Promise.new(function(resolve)
		if not DubitStore.pulling[datastoreIdentifier] then
			DubitStore.pulling[datastoreIdentifier] = {}
		end

		while DubitStore.pulling[datastoreIdentifier][datastoreKey] do
			task.wait()
		end

		assert(
			DubitStore.cached[datastoreIdentifier] ~= nil,
			"Developers can only get metadata after data has been retrieved"
		)
		assert(
			DubitStore.cached[datastoreIdentifier][datastoreKey] ~= nil,
			"Developers can only get metadata after data has been retrieved"
		)

		resolve(Sift.Dictionary.copyDeep(DubitStore.cached[datastoreIdentifier][datastoreKey].metadata))
	end)
end

function DubitStore.interface:SetMetaDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	value: any
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(typeof(value) ~= "nil", "Expected parameter #3 'value' to represent any type except nil")

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	return Promise.new(function(resolve)
		assert(
			DubitStore.cached[datastoreIdentifier] ~= nil,
			"Developers can only set metadata after data has been retrieved"
		)
		assert(
			DubitStore.cached[datastoreIdentifier][datastoreKey] ~= nil,
			"Developers can only set metadata after data has been retrieved"
		)

		DubitStore.cached[datastoreIdentifier][datastoreKey] = {
			metadata = value,
			data = DubitStore.cached[datastoreIdentifier][datastoreKey].data,
		}

		DubitStore.reporter:Debug(`Updated the metadata for '{datastoreIdentifier}/{datastoreKey}'!`)

		resolve()
	end)
end

function DubitStore.interface:GetDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	version: string?
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	return Promise.new(function(resolve, reject)
		if not DubitStore.pulling[datastoreIdentifier] then
			DubitStore.pulling[datastoreIdentifier] = {}
		end

		DubitStore.reporter:Debug(`Requesting GET for '{datastoreIdentifier}/{datastoreKey}@{version or "latest"}'..`)

		if DubitStore.pulling[datastoreIdentifier][datastoreKey] then
			DubitStore.reporter:Debug(
				`Yielding GET for '{datastoreIdentifier}/{datastoreKey}@{version or "latest"}' until first GET is written to cache!`
			)

			if not DubitStore.awaitingThreads[datastoreIdentifier] then
				DubitStore.awaitingThreads[datastoreIdentifier] = {}
			end

			if not DubitStore.awaitingThreads[datastoreIdentifier][datastoreKey] then
				DubitStore.awaitingThreads[datastoreIdentifier][datastoreKey] = 0
			end

			DubitStore.awaitingThreads[datastoreIdentifier][datastoreKey] += 1

			repeat
				task.wait()
			until not DubitStore.pulling[datastoreIdentifier][datastoreKey]

			DubitStore.awaitingThreads[datastoreIdentifier][datastoreKey] -= 1
		end

		if DubitStore.cached[datastoreIdentifier] and DubitStore.cached[datastoreIdentifier][datastoreKey] then
			resolve(
				DubitStore.cached[datastoreIdentifier][datastoreKey].data,
				DubitStore.cached[datastoreIdentifier][datastoreKey].metadata
			)
		elseif version then
			local success, response, keyInfo =
				self.Provider:GetVersionAsync(datastoreIdentifier, datastoreKey, version):await()

			if not success then
				DubitStore.interface.GetRequestFailed:Fire(datastoreIdentifier, datastoreKey, response)

				reject(response)
			end

			resolve(response, keyInfo)
		else
			DubitStore.pulling[datastoreIdentifier][datastoreKey] = true

			local success, response, keyInfo =
				self.Provider:GetAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Normal):await()

			if not success then
				DubitStore.pulling[datastoreIdentifier][datastoreKey] = nil
				DubitStore.interface.GetRequestFailed:Fire(datastoreIdentifier, datastoreKey, response)

				reject(response)
			end

			local metadata = keyInfo and keyInfo:GetMetadata()
			metadata = (metadata and metadata.devMetadata) or {}

			response = DubitStore.internal:InvokeMiddleware(response, self.Middleware.action.Get)

			if not DubitStore.cached[datastoreIdentifier] then
				DubitStore.cached[datastoreIdentifier] = {}
			end

			DubitStore.cached[datastoreIdentifier][datastoreKey] = { data = response, metadata = metadata }
			DubitStore.pulling[datastoreIdentifier][datastoreKey] = nil

			if DubitStore.cached[datastoreIdentifier][datastoreKey].data then
				resolve(
					Sift.Dictionary.copyDeep(DubitStore.cached[datastoreIdentifier][datastoreKey].data),
					Sift.Dictionary.copyDeep(DubitStore.cached[datastoreIdentifier][datastoreKey].metadata)
				)
			else
				resolve()
			end
		end
	end)
end

function DubitStore.interface:GetDataVersionsAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	sortDirection: Enum.SortOrder?,
	minDate: number?,
	maxDate: number?,
	pageSize: number?
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting GET (versions) for '{datastoreIdentifier}/{datastoreKey}'..`)

	return Promise.new(function(resolve, reject)
		local success, response = self.Provider
			:ListVersionsAsync(datastoreIdentifier, datastoreKey, sortDirection, minDate, maxDate, pageSize)
			:await()

		if not success then
			DubitStore.interface.GetRequestFailed:Fire(datastoreIdentifier, datastoreKey, response)

			reject(response)
		end

		resolve(response)
	end)
end

function DubitStore.interface:SetDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	value: any
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(typeof(value) ~= "nil", "Expected parameter #3 'value' to represent any type except nil")

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	return Promise.new(function(resolve)
		if not DubitStore.cached[datastoreIdentifier] then
			DubitStore.cached[datastoreIdentifier] = {}
		end

		if not DubitStore.cached[datastoreIdentifier][datastoreKey] then
			DubitStore.cached[datastoreIdentifier][datastoreKey] = {}
		end

		DubitStore.cached[datastoreIdentifier][datastoreKey] = {
			metadata = DubitStore.cached[datastoreIdentifier][datastoreKey].metadata,
			data = value,
		}

		DubitStore.reporter:Debug(
			`Set cache for '{datastoreIdentifier}/{datastoreKey}'.. please make sure to call ':PushAsync'!`
		)

		resolve()
	end)
end

function DubitStore.interface:UpdateDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	callback: (remoteServerData: any, localServerData: any, remoteData: any) -> any
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting UPDATE for '{datastoreIdentifier}/{datastoreKey}'..`)

	return Promise.new(function(resolve, reject)
		if not DubitStore.cached[datastoreIdentifier] then
			local message = `Expected cache buildup, no cache found for {datastoreIdentifier}`

			DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, message)
			reject(message)
		end

		if not DubitStore.cached[datastoreIdentifier][datastoreKey] then
			local message = `Expected cache buildup for key, no cache found for {datastoreIdentifier}/{datastoreKey}`

			DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, message)
			reject(message)
		end

		self.Provider
			:UpdateAsync(datastoreIdentifier, datastoreKey, function(remoteServerData)
				local userIds = {}
				local metadata = DubitStore.metadata[datastoreIdentifier]
					and DubitStore.metadata[datastoreIdentifier][datastoreKey]

				local localServerData = DubitStore.cached[datastoreIdentifier]
					and DubitStore.cached[datastoreIdentifier][datastoreKey]
					and DubitStore.cached[datastoreIdentifier][datastoreKey].data

				local developerMetadata = DubitStore.cached[datastoreIdentifier]
					and DubitStore.cached[datastoreIdentifier][datastoreKey]
					and DubitStore.cached[datastoreIdentifier][datastoreKey].metadata

				metadata = metadata or {}
				metadata.devMetadata = developerMetadata

				remoteServerData = DubitStore.internal:InvokeMiddleware(remoteServerData, self.Middleware.action.Get)
				localServerData, userIds, metadata = callback(remoteServerData, metadata.devMetadata)

				if userIds then
					for index, object in userIds do
						if type(object) == "number" then
							continue
						end

						assert(type(object) == "userdata", "expected either 'Player' or 'number' for userIds")
						assert(object:IsA("Player"), "expected either 'Player' or 'number' for userIds")

						userIds[index] = object.UserId
					end
				end

				localServerData = DubitStore.internal:InvokeMiddleware(localServerData, self.Middleware.action.Set)

				return localServerData, userIds or {}, metadata
			end, self.Provider.datastoreTypes.Normal)
			:andThen(function(...)
				resolve(...)
			end)
			:catch(function(...)
				DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, ...)

				reject(...)
			end)
	end)
end

function DubitStore.interface:GetOrderedKeyAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting GET (ordered) for '{datastoreIdentifier}/{datastoreKey}'..`)

	return self.Provider
		:GetAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Ordered)
		:catch(function(response)
			DubitStore.interface.GetRequestFailed:Fire(datastoreIdentifier, response)

			return response
		end)
end

function DubitStore.interface:GetOrderedDataAsync(
	datastoreIdentifier: string,
	ascending: boolean,
	pageSize: number,
	minValue: number?,
	maxValue: number?
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(typeof(ascending) == "boolean", "Expected parameter #2 'ascending' to represent a boolean type")
	assert(typeof(pageSize) == "number", "Expected parameter #3 'pageSize' to represent a number type")

	DubitStore.reporter:Debug(`Requesting GET_SORTED (ordered) for '{datastoreIdentifier}'..`)

	return self.Provider
		:GetSortedAsync(datastoreIdentifier, ascending, pageSize, minValue, maxValue)
		:catch(function(response)
			DubitStore.interface.OrderedGetRequestFailed:Fire(datastoreIdentifier, response)

			return response
		end)
end

function DubitStore.interface:SetOrderedDataAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	value: any
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)
	assert(typeof(value) == "number", "Expected parameter #3 'value' to represent a number type")

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting SET (ordered) for '{datastoreIdentifier}/{datastoreKey}'..`)

	return self.Provider
		:UpdateAsync(datastoreIdentifier, datastoreKey, function()
			return value
		end, self.Provider.datastoreTypes.Ordered)
		:catch(function(response)
			DubitStore.interface.OrderedSetRequestFailed:Fire(datastoreIdentifier, response)

			return response
		end)
end

function DubitStore.interface:RemoveOrderedAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting REMOVE (ordered) for '{datastoreIdentifier}/{datastoreKey}'..`)

	return self.Provider:RemoveAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Ordered)
end

function DubitStore.interface:RemoveAsync(datastoreIdentifier: string, datastoreKey: string | Player): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting REMOVE for '{datastoreIdentifier}/{datastoreKey}'..`)

	return self.Provider:RemoveAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Normal)
end

function DubitStore.interface:PushAsync(
	datastoreIdentifier: string,
	datastoreKey: string | Player,
	userIds: { number | Player }?
): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	if userIds then
		for index, object in userIds do
			if type(object) == "number" then
				continue
			end

			assert(type(object) == "userdata", "expected either 'Player' or 'number' for userIds")
			assert(object:IsA("Player"), "expected either 'Player' or 'number' for userIds")

			userIds[index] = object.UserId
		end
	end

	return Promise.new(function(resolve, reject)
		if not DubitStore.cached[datastoreIdentifier] then
			local message = `Expected cache buildup, no cache found for {datastoreIdentifier}`

			DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, message)
			reject(message)
		end

		if not DubitStore.cached[datastoreIdentifier][datastoreKey] then
			local message = `Expected cache buildup for key, no cache found for {datastoreIdentifier}/{datastoreKey}`

			DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, message)
			reject(message)
		end

		if not DubitStore.cached[datastoreIdentifier][datastoreKey].data then
			local message = `Expected data to push, no data was found for {datastoreIdentifier}/{datastoreKey}`

			DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, message)
			reject(message)
		end

		DubitStore.reporter:Debug(`Requesting PUSH for '{datastoreIdentifier}/{datastoreKey}'..`)

		self.Provider
			:UpdateAsync(datastoreIdentifier, datastoreKey, function()
				local metadata = DubitStore.metadata[datastoreIdentifier]
					and DubitStore.metadata[datastoreIdentifier][datastoreKey]

				local data = DubitStore.cached[datastoreIdentifier]
					and DubitStore.cached[datastoreIdentifier][datastoreKey]
					and DubitStore.cached[datastoreIdentifier][datastoreKey].data

				local developerMetadata = DubitStore.cached[datastoreIdentifier]
					and DubitStore.cached[datastoreIdentifier][datastoreKey]
					and DubitStore.cached[datastoreIdentifier][datastoreKey].metadata

				data = data and Sift.Dictionary.copyDeep(data)
				developerMetadata = developerMetadata and Sift.Dictionary.copyDeep(developerMetadata)

				metadata = metadata or {}
				metadata.devMetadata = developerMetadata

				DubitStore.internal:InvokeMiddleware(data, self.Middleware.action.Set)

				return data, userIds or {}, metadata
			end, self.Provider.datastoreTypes.Normal)
			:andThen(function(...)
				DubitStore.interface.PushCompleted:Fire(datastoreIdentifier, datastoreKey)

				resolve(...)
			end)
			:catch(function(...)
				DubitStore.interface.SetRequestFailed:Fire(datastoreIdentifier, datastoreKey, ...)

				reject(...)
			end)
	end)
end

do
	local serialiseMiddlewareImplementation

	game:BindToClose(function()
		DubitStore.interface.Provider:OnBindToClose()
	end)

	serialiseMiddlewareImplementation =
		DubitStore.interface:ImplementMiddleware(DubitStore.interface.Middleware.new(function(data, actionType)
			if not data then
				return
			end

			if actionType == DubitStore.interface.Middleware.action.Get then
				for index, value in data do
					if type(value) ~= "table" then
						continue
					end

					if not value._isSerialised then
						data[index] = serialiseMiddlewareImplementation:Call(value, actionType)

						continue
					end

					local success, response = DubitStore.interface.Serialisation:Deserialise(value)

					if not success then
						DubitStore.interface.DataCorrupted:Fire(data)

						return DubitStore.reporter:Error(
							`Deserialisation failed for datatype: {value.objectType}: {response}`
						)
					end

					value._isSerialised = nil
					data[index] = response
				end

				return data
			elseif actionType == DubitStore.interface.Middleware.action.Set then
				for index, value in data do
					if type(value) == "table" then
						data[index] = serialiseMiddlewareImplementation:Call(value, actionType)

						continue
					elseif not DubitStore.interface.Serialisation:IsSupported(value) then
						continue
					end

					local success, response = DubitStore.interface.Serialisation:Serialise(value)

					if not success then
						DubitStore.interface.DataCorrupted:Fire(data)

						return DubitStore.reporter:Error(
							`Serialisation failed for datatype: {typeof(value)}: {response}`
						)
					end

					data[index] = response
					data[index]._isSerialised = true
				end

				return data
			else
				return
			end
		end))

	DubitStore.interface.GetRequestFailed:Connect(function(...)
		DubitStore.reporter:Critical(`Failed 'GetRequestFailed' call:`, ...)
	end)

	DubitStore.interface.OrderedGetRequestFailed:Connect(function(...)
		DubitStore.reporter:Critical(`Failed 'OrderedGetRequestFailed' call:`, ...)
	end)

	DubitStore.interface.OrderedSetRequestFailed:Connect(function(...)
		DubitStore.reporter:Critical(`Failed 'OrderedSetRequestFailed' call:`, ...)
	end)

	DubitStore.interface.SetRequestFailed:Connect(function(...)
		DubitStore.reporter:Critical(`Failed 'SetRequestFailed' call:`, ...)
	end)

	DubitStore.interface.DataCorrupted:Connect(function(...)
		DubitStore.reporter:Critical(`Data Corrupted:`, ...)
	end)
end

return DubitStore.interface
