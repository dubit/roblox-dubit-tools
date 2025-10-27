--[[
	Roblox DubitStore:
		A feature-rich Roblox DataStore wrapper.

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have been made to provide insight.
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

--[=[
	@class DubitStore

	DubitStore is a feature-rich Roblox DataStore wrapper, enabling developers to take advantage over a multitude of advanced features.

	---

	DubitStore offers quite a lot of features, however, it does not force developers to use these features.. it is up to the developer to choose what features are necessary vs what features to avoid.

	An brief overview on what DubitStore offers;
	- **Middleware implementation**
		- Middleware enable both developers & DubitStore to write code that mutates the data before or after the data is downloaded or uplodaded.
		- *⚠️ Use middleware with caution as it can introduce the ability to corrupt data if miss-used.*
	- **Reconciling data**
		- To reconcile data is to help flatten two data's into a single entity, in DubitStore's case it'll be merging remote data with our schema format.
		- To be able to reconcile data, developers must create a "Schema", this schema represents what the latets version of that data will look like.
			- *ℹ️ Schemas will only fill in data which does not exist with an existing data object.*
	- **Session Locking**
		- Session locking isn't enforced in DubitStore, this is because we don't know the application, maybe we do want servers to read & write to data when other servers can.. for instance, a totalizer.
	- **Data Corruption**
		- In the case middleware fail to mutate the state of data, the Data Corrupted signal will be invoked to indicate that data was unable to be processed.
	- **Autosaving data**
		- As DubitStore still doesn't know the use case, we've implemented an abstract way to save player data.. allowing you to bind a function to an autosave key, when this key is fired, your function will be called. It's up to the developer to then save that data.
		- Autosaving intervals can be set, as well as manually called. We do not advise you call an autosave function once that data is dropped.
			- For instance, an example of this could be invoking the autosave function to save data when the player leaves.. this is because AutoSaving may serve a different purpose to saving data at the end of a session.
	- **Removing existing data**
		- Since DubitStore isn't player orientated, it does not have the ability to remove player cached data when that player leaves.. this will need to be done through a developer to ensure that when that player joins back, they will not recieve an older version of said data.
		- This is one of the cons for DubitStore, however enables us to use this module in things like Leaderboards and so on.

	Some of the dubit store background handywork;
	- **Type Support**
		- DubitStore has the ability to save objects such as Vector3's, CFrame's and so on.
		- DubitStore achieves this by breaking each object down into a table, implementing components and things of that sort.
	- **BindToClose**
		- DubitStore has full support for when a studio/server is shutting down, it's goal being to save all player data before shutdown.
	- **Cache**
		- DubitStore will only build a cache once a get request is made and there is already no existing cache. The principle behind this is to enable developers to quickly SET & GET data without making multiple datastore requests..
		- This however means, in order to send that data over to the server, you need to "Push" that data, Pushing data is the act where we move what we currently have in cache over to the server.
			- *⚠️ If a developer doesn't push any data, no data will be saved as it'll only exist under that specific servers cache.*
	- **Internal Queue & Budgeting**
		- DubitStore relies on both a Queue system and DataStore budgets to regulate how fast requests are made to each endpoint.. this also includes awareness for "key cooldown" mentioned in the below document
			- https://devforum.roblox.com/t/details-on-datastoreservice-for-advanced-developers/175804
	- **Multi-Threading**
		- DubitStore takes advantage of roblox's parallel thread implementation, allowing DubitStore to work alongside the Roblox VM.

	---
]=]
local DubitStore = {}

DubitStore.reporter = Console:CreateReporter("DubitStore")

DubitStore.interface = {}
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

DubitStore.interface.Provider = require(script.Provider)
DubitStore.interface.Validator = require(script.Validator)
DubitStore.interface.Serialisation = require(script.Serialisation)

--[=[
	@prop Container Container
	@within DubitStore
]=]
--
DubitStore.interface.Container = require(script.Container)

--[=[
	@prop Middleware Middleware
	@within DubitStore
]=]
--
DubitStore.interface.Middleware = require(script.Middleware)

--[=[
	@prop GetRequestFailed Signal
	@within DubitStore
]=]
--
DubitStore.interface.GetRequestFailed = Signal.new()

--[=[
	@prop SetRequestFailed Signal
	@within DubitStore
]=]
--
DubitStore.interface.SetRequestFailed = Signal.new()

--[=[
	@prop OrderedGetRequestFailed Signal
	@within DubitStore
]=]
--
DubitStore.interface.OrderedGetRequestFailed = Signal.new()

--[=[
	@prop OrderedSetRequestFailed Signal
	@within DubitStore
]=]
--
DubitStore.interface.OrderedSetRequestFailed = Signal.new()

--[=[
	@prop DataCorrupted Signal
	@within DubitStore
]=]
--
DubitStore.interface.DataCorrupted = Signal.new()

--[=[
	@prop PushCompleted Signal
	@within DubitStore
]=]
--
DubitStore.interface.PushCompleted = Signal.new()

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

--[=[
	When set to true, all of the debugging logs DubitStore creates will appear, by default this is set to false so only warning+ will appear.

	```lua
	DubitStore:SetVerbosity(true)
	```

	@method SetVerbosity
	@within DubitStore

	@param isVerboise boolean

	@return ()
]=]
--
function DubitStore.interface:SetVerbosity(isVerbose: boolean): ()
	Console:SetLogLevel(isVerbose and ConsoleLib.LogLevel.Debug or ConsoleLib.LogLevel.Warn)
end

--[=[
	This function will return the size of a key in Bytes, this can be used to find how large you can scale your systems.

	```lua
	local DataStoreModule = require(path.to.module)
	local DataEnum = require(path.to.enum)

	local MAX_DATA_SIZE = 4194303

	DubitStore:GetDataAsync(DataEnum.PlayerStatData, "player1"):await()

	local dataSizeInBytes = DubitStore:GetSizeInBytes(DataEnum.PlayerStatData, "player1")
	local consumedDataBudget = (dataSizeInBytes / MAX_DATA_SIZE) * 100
	```

	@method GetSizeInBytes
	@within DubitStore

	@param datastoreIdentifier string

	@return number
]=]
--
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

--[=[
	This function will return a boolean depening on if the library is "online", online meaning able to push to a live roblox datastore.

	Ideally this is useful in scenarios where developers are inside of studio or want to run tests.

	```lua
	DubitStore:IsOffline()
	```

	@method IsOffline
	@within DubitStore

	@return boolean
]=]
--
function DubitStore.interface:IsOffline(): boolean
	return DubitStore.interface.Provider.isOffline and not DubitStore.interface.Provider.onlineState
end

--[=[
	This function will override and set the "online" state of the library, online meaning able to push to a live roblox datastore.

	```lua
	DubitStore:SetOnlineState(true)
	```

	@method SetOnlineState
	@within DubitStore

	@param state boolean

	@return ()
]=]
--
function DubitStore.interface:SetOnlineState(state: boolean): ()
	DubitStore.reporter:Debug(`Set 'offline' state to: {state}`)

	DubitStore.interface.Provider.onlineState = state
end

--[=[
	This function will set the development channel for DubitStore, if the development channel is anything other than "PRODUCTION" then specific cooldowns won't apply.

	- We suggest leaving this unchecked unless you're either developing or debugging an issue.

	```lua
	DubitStore:SetDevelopmentChannel("DEVELOPMENT")
	```

	@method SetDevelopmentChannel
	@within DubitStore

	@param channel boolean

	@return ()
]=]
--
function DubitStore.interface:SetDevelopmentChannel(channel: string): ()
	DubitStore.reporter:Debug(`Set 'development' channel to: {channel}`)

	DubitStore.interface.Provider.channel = channel
end

--[=[
	This function will retrieve the current channel of the library, in the majority of cases, this channel will be "Production

	```lua
	local channelName = DubitStore:GetDevelopmentChannel()
	local isProduction = channelName == "Production"
	```

	@method GetDevelopmentChannel
	@within DubitStore

	@return string
]=]
--
function DubitStore.interface:GetDevelopmentChannel(): string
	return DubitStore.interface.Provider.channel
end

--[=[
	This method will help developers implement middleware to recieve & modify data before we set and get that data.

	```lua
	local middleware = DubitStore.Middleware.new(function(data, middlewareActionType)
		if middlewareActionType == DubitStore.Middleware.action.Get then
			-- we can do stuff with 'data' before our library "gets" that data.

			...
		end

		return data
	end)

	DubitStore:ImplementMiddleware(middleware)
	```

	@method ImplementMiddleware
	@within DubitStore

	@param middleware Middleware

	@return Middleware
]=]
--
function DubitStore.interface:ImplementMiddleware(middleware: Types.MiddlewareObject): Types.MiddlewareObject
	assert(self.Middleware.is(middleware), "Expected parameter #1 'middleware' to represent a middleware type")

	table.insert(DubitStore.middleware, middleware)

	return middleware
end

--[=[
	This method will remove any existing Middleware from DubitStore

	```lua
	local middleware = DubitStore.Middleware.new(function()
		...
	end)

	DubitStore:ImplementMiddleware(middleware)

	doSomething()

	DubitStore:RemoveMiddleware(middleware)
	```

	@method RemoveMiddleware
	@within DubitStore

	@param middleware Middleware

	@return Middleware
]=]
--
function DubitStore.interface:RemoveMiddleware(middleware: Types.MiddlewareObject): Types.MiddlewareObject
	assert(self.Middleware.is(middleware), "Expected parameter #1 'middleware' to represent a middleware type")

	local setIndex = table.find(DubitStore.middleware.setters, middleware)

	if setIndex then
		table.remove(DubitStore.middleware, setIndex)
	end

	return middleware
end

--[=[
	This function will serialise a schema into a standard Lua table

	```lua
	local data = DubitStore:GenerateRawTable({
		ExampleSchemaString = DubitStore.Container.new("Super Awesome String!")
		ExampleSchemaEntry = DubitStore.Cotainer.new({
			ExampleSchemaSubEntry = DubitStore.Container.new("Super Awesome String 2!")
		})
	})

	print(data.ExampleSchemaString) -- > "Super Awesome String!"
	```

	@method GenerateRawTable
	@within DubitStore

	@param schemaTable { [string]: Container }

	@return { [string]: any }
]=]
--
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

--[=[
	This function will validate schemas generated by developers.

	```lua
	local success, errorMessage = DubitStore:ValidateDataSchema({
		ExampleSchemaString = DubitStore.Container.new("Super Awesome String!")
		ExampleSchemaEntry = DubitStore.Cotainer.new({
			ExampleSchemaSubEntry = DubitStore.Container.new("Super Awesome String 2!")
		})
	})
	```

	@method ValidateDataSchema
	@within DubitStore

	@param schemaTable { [string]: Container }

	@return boolean, string
]=]
--
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

--[=[
	This function will create a data schema, data schemas should be used to validate data as well as update outdated data.

	```lua
	DubitStore:CreateDataSchema("schemaIdentifier", {
		ExampleSchemaString = DubitStore.Container.new("Super Awesome String!")
		ExampleSchemaEntry = DubitStore.Cotainer.new({
			ExampleSchemaSubEntry = DubitStore.Container.new("Super Awesome String 2!")
		})
	})

	-- "schemaIdentifier" is now a direct link to the above schema, we can now use this schema to update/maintain our data!
	```

	@method CreateDataSchema
	@within DubitStore

	@param schemaIdentifier string
	@param schemaTable { [string]: Container }

	@return ()
]=]
--
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

--[=[
	This function will return the initial schema implemented through `DubitStore:CreateDataSchema`

	```lua
	local dataSchema = DubitStore:GetDataSchema("schemaIdentifier")
	```

	@method GetDataSchema
	@within DubitStore

	@param schemaIdentifier string

	@return { [string]: Container }
]=]
--
function DubitStore.interface:GetDataSchema(schemaIdentifier: string): Types.Schema
	assert(
		DubitStore.schemas[schemaIdentifier] ~= nil,
		`Schema {schemaIdentifier} does not exist in DubitStore, please allocate a schema.`
	)

	return DubitStore.schemas[schemaIdentifier]
end

--[=[
	This function will return a boolean depending on if the schema identifier is linked to a schema object

	```lua
	local doesSchemaExist = DubitStore:SchemaExists("schemaIdentifier")
	```

	@method SchemaExists
	@within DubitStore

	@param schemaIdentifier string

	@return boolean
]=]
--
function DubitStore.interface:SchemaExists(schemaIdentifier: string): boolean
	return DubitStore.schemas[schemaIdentifier] ~= nil
end

--[=[
	This function will fill in the data with the contents of a schema if the data doesn't exist.

	```lua
	DubitStore:CreateDataSchema("schemaIdentifier", {
		Exp = DubitStore.Container.new(42),
		Level = DubitStore.Container.new(2)
	})

	local schema = DubitStore:ReconcileData({ Level = 1 }, "schemaIdentifier")

	print(schema.Level) --> 1
	print(schema.Exp) --> 42
	```

	@method ReconcileData
	@within DubitStore

	@param schemaIdentifier string

	@return boolean
]=]
--
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

--[=[
	This function returns a signal which'll be invoked each autosave occurance.

	```lua
	local DataStoreModule = require(path.to.module)
	local DataEnum = require(path.to.enum)

	DataStoreModule:OnAutosave(DataEnum.PlayerStatData):Connect(function()
		...
	end)
	```

	@method OnAutosave
	@within DubitStore

	@param datastoreIdentifier string

	@return Signal
]=]
--
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

--[=[
	This function will invoke the autosave signal

	```lua
	local DataStoreModule = require(path.to.module)
	local DataEnum = require(path.to.enum)

	DataStoreModule:InvokeAutosave(DataEnum.PlayerStatData)
	```

	@method InvokeAutosave
	@within DubitStore

	@param datastoreIdentifier string

	@return ()
]=]
--
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

--[=[
	This function will cancel any background workers spawned through DubitStore:SetAutosaveInterval

	```lua
	local DataStoreModule = require(path.to.module)
	local DataEnum = require(path.to.enum)

	DataStoreModule:CancelAutosave(DataEnum.PlayerStatData)
	```

	@method CancelAutosave
	@within DubitStore

	@param datastoreIdentifier string

	@return ()
]=]
--
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

--[=[
	This function will spawn a new background worker that'll invoke an autosave signal each interval

	```lua
	local DataStoreModule = require(path.to.module)
	local DataEnum = require(path.to.enum)

	local AUTO_SAVE_INTERVAL_SECONDS = 60 * 5 -- 5 mins.

	DataStoreModule:SetAutosaveInterval(DataEnum.PlayerStatData, AUTO_SAVE_INTERVAL_SECONDS)
	```

	@method SetAutosaveInterval
	@within DubitStore

	@param datastoreIdentifier string
	@param interval number

	@return ()
]=]
--
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

--[=[
	This function will remove cached data for a data store key, however if a key is not defined, the datastore cache will be removed instead.

	```lua
	DubitStore:ClearCache("PlayerData", "Player")
	```

	@method ClearCache
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey? string?

	@return ()
]=]
--
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

--[=[
	This function will halt the execution of the current thread until either the datastore key can be written to, or the maximum yield time is surpassed

	If no yield time is passed, then the function will indefinitely wait.

	```lua
	local unlocked = DubitStore:YieldUntilDataUnlocked("datastoreIdentifier", "datastoreKey", 10)

	local schema = DubitStore:ReconcileData({ Level = 1 }, "schemaIdentifier")

	print(schema.Level) --> 
	print(schema.Exp)
	```

	@method YieldUntilDataUnlocked
	@within DubitStore
	@yields

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param maximumYieldTime? number?

	@return boolean
]=]
--
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

--[=[
	This function will set the 'locked' state of the datastoreKey to a given value, if the data is locked then no other server can write to this key, however when the data is unlocked - servers are able to write to this key.

	```lua
	DubitStore:SetDataSessionLocked("datastoreIdentifier", "datastoreKey", true)
	```

	:::caution
		These changes will not take effect until you call :PushAsync to push data, including metadata to the server.
	:::

	@method SetDataSessionLocked
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param locked? boolean?

	@return ()
]=]
--
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

--[=[
	This function will overwrite the 'locked' state for a given datastoreKey, by overwriting a data session we're risking an older record of that players data never being saved.

	```lua
	DubitStore:OverwriteDataSessionLocked("datastoreIdentifier", "datastoreKey", true)
	```

	:::caution
		Once you've overwritten a data session, if the session state is set to true - the previous server will be unable to write to the datastore.
	:::

	@method OverwriteDataSessionLocked
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param locked? boolean?

	@return ()
]=]
--
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

--[=[
	This function will merge the cached data with what the server already has, typically useful in cases where we're not locking player data.

	In the case we pass no reconciler function, the library will use Sift to merge keys, the cached data taking priority.

	```lua
	DubitStore:SyncDataAsync("datastoreIdentifier", "datastoreKey")

	-- OR

	DubitStore:SyncDataAsync("datastoreIdentifier", "datastoreKey", function(serverData)
		...

		return serverData
	end)
	```

	@method SyncDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param reconciler? (data: any, response: any) -> any?

	@return Promise<()>
]=]
--
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

--[=[
	This function retrieves the MetaData of a key.

	```lua
	DubitStore:GetMetaDataAsync("datastoreIdentifier", "datastoreKey"):andThen(function(metaData)
		...
	end)
	```

	@method GetMetaDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player

	@return Promise<{[string]: any}>
]=]
--
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

--[=[
	This function sets the MetaData of a key

	```lua
	DubitStore:SetMetaDataAsync("datastoreIdentifier", "datastoreKey", { value = 5 }):andThen(function(metaData)
		...
	end)
	```

	@method SetMetaDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param value { [string]: any }

	@return Promise<()>
]=]
--
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

--[=[
	This function retrieves the Data of a key. You can use the third parameter to fetch an older version of said key.

	```lua
	DubitStore:CreateDataSchema("schema", {
		Exp = DubitStore.Container.new(42),
		Level = DubitStore.Container.new(2)
	})

	DubitStore:GetDataAsync("datastoreIdentifier", "datastoreKey"):andThen(function(data)
		data = DubitStore:ReconcileData({ Level = 1 }, "schema")

		print(data)
	end)
	```

	@method GetDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param version? string?

	@return Promise<{[string]: any}>
]=]
--
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

--[=[
	This function retrieves a list of versions this key currently has.

	```lua
	DubitStore:GetDataVersionsAsync("datastoreIdentifier", "datastoreKey"):andThen(function(versionList)
		
	end)
	```

	@method GetDataVersionsAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param sortDirection? Enum.SortOrder?
	@param minDate? number?
	@param maxDate? number?
	@param pageSize? number?

	@return Promise<DataStoreVersionPages>
]=]
--
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

--[=[
	This function sets the Data of a key. This method returns a promise in order to do the following;

	- Remain consistant with it's counterpart, GetAsync..
	- Provide a friendly approach to how a developer can handle syntax..
	- Scaleable error handling..

	```lua
	DubitStore:SetDataAsync("datastoreIdentifier", "datastoreKey", {
		abc = 123
	})

	DubitStore:PushAsync()
	```

	:::caution
		These changes will not take effect until you call :PushAsync to push data, including metadata to the server.
	:::

	@method SetDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param value any

	@return Promise<()>
]=]
--
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

--[=[
	This function will enable developers to both GET and SET data within the same function, avoiding server-server sync issues.

	:::caution
		This function will NOT write to cache, you do NOT need to call :PushAsync after making this call.
	:::

	```lua
	DubitStore:UpdateDataAsync("datastoreIdentifier", "datastoreKey", function(data)
		return {
			Coins = data.Coins + 1
		}
	end)
	```

	@method UpdateDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param callback function

	@return Promise<string, DataStoreKeyInfo>
]=]
--
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

--[=[
	This function retrieves the value for an ordered data store key, this function is useful in the case you want to get a specific players value in an ordered datastore

	:::caution
		This function will NOT read cache, it will instead make a query to the datastore backend on each call.
	:::

	```lua
	DubitStore:GetOrderedKeyAsync("datastoreIdentifier", "datastoreKey"):andThen(function(data)
		...
	end)
	```

	@method GetOrderedKeyAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player

	@return Promise<number>
]=]
--
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

--[=[
	This function retrieves ordered datastore pages, enabling the developers to create functionality such as leaderboards.

	:::caution
		This function will NOT read cache, it will instead make a query to the datastore backend on each call.
	:::

	```lua
	DubitStore:GetOrderedDataAsync("datastoreIdentifier"):andThen(function(datastorePages)
		...
	end)
	```

	@method GetOrderedDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param ascending boolean
	@param pageSize number
	@param minValue? number?
	@param maxValue? number?

	@return Promise<DataStorePages>
]=]
--
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

--[=[
	This function sets the value of 'datastoreKey' to a given input inside of the ordered data store.

	:::caution
		This function will NOT write to cache, you do NOT need to call :PushAsync after making this call.
	:::

	```lua
	DubitStore:SetOrderedDataAsync("datastoreIdentifier", "datastoreKey", 5)
	```

	@method SetOrderedDataAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param value number

	@return Promise<string, DataStoreKeyInfo>
]=]
--
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

--[=[
	This function will remove ordered data that is tied to the 'datastoreKey' under the given 'datastoreIdentifier'

	```lua
	DubitStore:RemoveOrderedAsync("datastoreIdentifier", "datastoreKey")
	```

	@method RemoveOrderedAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player

	@return Promise
]=]
--
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

--[=[
	This function will remove data that is tied to the 'datastoreKey' under the given 'datastoreIdentifier'

	```lua
	DubitStore:RemoveAsync("datastoreIdentifier", "datastoreKey")
	```

	@method RemoveAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player

	@return Promise
]=]
--
function DubitStore.interface:RemoveAsync(datastoreIdentifier: string, datastoreKey: string | Player): Types.Promise
	assert(
		typeof(datastoreIdentifier) == "string",
		"Expected parameter #1 'datastoreIdentifier' to represent a string type"
	)

	datastoreKey = DubitStore.internal:AssertDataStoreKey(datastoreKey)

	DubitStore.reporter:Debug(`Requesting REMOVE for '{datastoreIdentifier}/{datastoreKey}'..`)

	return self.Provider:RemoveAsync(datastoreIdentifier, datastoreKey, self.Provider.datastoreTypes.Normal)
end

--[=[
	This function will push any changes made in the cache to the server, if for some reason the push fails, the promise will reject.

	```lua
	DubitStore:PushAsync("datastoreIdentifier", "datastoreKey", { player.userId })
	```

	@method PushAsync
	@within DubitStore

	@param datastoreIdentifier string
	@param datastoreKey string | Player
	@param userIds? { number | Player }?

	@return Promise<string, DataStoreKeyInfo>
]=]
--
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
