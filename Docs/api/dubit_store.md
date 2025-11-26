# API

## DubitStore

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
		- [Devforum Post](https://devforum.roblox.com/t/details-on-datastoreservice-for-advanced-developers/175804)
- **Multi-Threading**
	- DubitStore takes advantage of roblox's parallel thread implementation, allowing DubitStore to work alongside the Roblox VM.

### Properties

#### .Container
```luau { .fn_type }
DubitStore.Container: Container
```

---

#### .Middleware
```luau { .fn_type }
DubitStore.Middleware: Middleware
```

---

#### .GetRequestFailed
```luau { .fn_type }
DubitStore.GetRequestFailed: Signal
```

---

#### .SetRequestFailed
```luau { .fn_type }
DubitStore.SetRequestFailed: Signal
```

---

#### .OrderedGetRequestFailed
```luau { .fn_type }
DubitStore.OrderedGetRequestFailed: Signal
```

---

#### .OrderedSetRequestFailed
```luau { .fn_type }
DubitStore.OrderedSetRequestFailed: Signal
```

---

#### .DataCorrupted
```luau { .fn_type }
DubitStore.DataCorrupted: Signal
```

---

#### .PushCompleted
```luau { .fn_type }
DubitStore.PushCompleted: Signal
```

### Functions

#### :SetVerbosity
```luau { .fn_type }
DubitStore:SetVerbosity(isVerboise: boolean): ()
```

When set to true, all of the debugging logs DubitStore creates will appear, by default this is set to false so only warning+ will appear.

---

#### :GetSizeInBytes
```luau { .fn_type }
DubitStore:GetSizeInBytes(datastoreIdentifier: string, datastoreKey: string | Player): number
```

This function will return the size of a key in Bytes, this can be used to find how large you can scale your systems.

??? example "Example Usage"
	```lua
	DubitStore:GetDataAsync("Inventory", "player1"):await()

	local dataSizeInBytes = DubitStore:GetSizeInBytes("Inventory", "player1")
	```

---

#### :IsOffline
```luau { .fn_type }
DubitStore:IsOffline(): boolean
```

This function will return a boolean depening on if the library is "online", online meaning able to push to a live roblox datastore.

Ideally this is useful in scenarios where developers are inside of studio or want to run tests.

---

#### :SetOnlineState
```luau { .fn_type }
DubitStore:SetOnlineState(state: boolean): ()
```

This function will override and set the "online" state of the library, online meaning able to push to a live roblox datastore.

---

#### :SetDevelopmentChannel
```luau { .fn_type }
DubitStore:SetDevelopmentChannel(channel: string): ()
```

This function will set the development channel for DubitStore, if the development channel is anything other than "PRODUCTION" then specific cooldowns won't apply.
	- We suggest leaving this unchecked unless you're either developing or debugging an issue.

---

#### :GetDevelopmentChannel
```luau { .fn_type }
DubitStore:GetDevelopmentChannel(): string
```

This function will retrieve the current channel of the library, in the majority of cases, this channel will be "Production

---

#### :ImplementMiddleware
```luau { .fn_type }
DubitStore:ImplementMiddleware(middleware: Middleware): Middleware
```

This method will help developers implement middleware to recieve & modify data before we set and get that data.

??? example "Example Usage"
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

---

#### :RemoveMiddleware
```luau { .fn_type }
DubitStore:RemoveMiddleware(middleware: Middleware): Middleware
```

This method will remove any existing Middleware from DubitStoren

---

#### :GenerateRawTable
```luau { .fn_type }
DubitStore:GenerateRawTable(schemaTable: {[string]: Container}): {[string]: any}
```

This function will serialise a schema into a standard Lua table

??? example "Example Usage"
	```lua
	local data = DubitStore:GenerateRawTable({
		ExampleSchemaString = DubitStore.Container.new("Super Awesome String!")
		ExampleSchemaEntry = DubitStore.Cotainer.new({
			ExampleSchemaSubEntry = DubitStore.Container.new("Super Awesome String 2!")
		})
	})

	print(data.ExampleSchemaString) --> Super Awesome String!
	```

---

#### :ValidateDataSchema
```luau { .fn_type }
DubitStore:ValidateDataSchema(schemaTable: {[string]: Container}): (boolean, string)
```

This function will validate schemas generated by developers.

??? example "Example Usage"
	```lua
	local success, errorMessage = DubitStore:ValidateDataSchema({
		ExampleSchemaString = DubitStore.Container.new("Super Awesome String!")
		ExampleSchemaEntry = DubitStore.Cotainer.new({
			ExampleSchemaSubEntry = DubitStore.Container.new("Super Awesome String 2!")
		})
	})
	```

---

#### :CreateDataSchema
```luau { .fn_type }
DubitStore:CreateDataSchema(schemaIdentifier: string, schemaTable: {[string]: Container}): ()
```

This function will create a data schema, data schemas should be used to validate data as well as update outdated data.

??? example "Example Usage"
	```lua
	DubitStore:CreateDataSchema("schemaIdentifier", {
		ExampleSchemaString = DubitStore.Container.new("Super Awesome String!")
		ExampleSchemaEntry = DubitStore.Cotainer.new({
			ExampleSchemaSubEntry = DubitStore.Container.new("Super Awesome String 2!")
		})
	})

	-- "schemaIdentifier" is now a direct link to the above schema, we can now use this schema to update/maintain our data!
	```

---

#### :GetDataSchema
```luau { .fn_type }
DubitStore:GetDataSchema(schemaIdentifier: string): {[string]: Container}
```

This function will return the initial schema implemented through **[CreateDataSchema](#createdataschema)**

---

#### :SchemaExists
```luau { .fn_type }
DubitStore:SchemaExists(schemaIdentifier: string): boolean
```

This function will return a boolean depending on if the schema identifier is linked to a schema object

---

#### :ReconcileData
```luau { .fn_type }
DubitStore:ReconcileData(schemaIdentifier: string): boolean
```

This function will fill in the data with the contents of a schema if the data doesn't exist.

??? example "Example Usage"
	```lua
	DubitStore:CreateDataSchema("schemaIdentifier", {
		Exp = DubitStore.Container.new(42),
		Level = DubitStore.Container.new(2)
	})

	local schema = DubitStore:ReconcileData({ Level = 1 }, "schemaIdentifier")

	print(schema.Level) --> 1
	print(schema.Exp) --> 42
	```

---

#### :OnAutosave
```luau { .fn_type }
DubitStore:OnAutosave(datastoreIdentifier: string): Signal
```

This function returns a signal which'll be invoked each autosave occurance.

??? example "Example Usage"
	```lua
	DataStoreModule:OnAutosave("Inventory"):Connect(function()
		
	end)
	```

---

#### :InvokeAutosave
```luau { .fn_type }
DubitStore:InvokeAutosave(datastoreIdentifier: string): ()
```

This function will invoke the autosave signal

---

#### :CancelAutosave
```luau { .fn_type }
DubitStore:CancelAutosave(datastoreIdentifier: string): ()
```

This function will cancel any background workers spawned through **[SetAutosaveInterval](#setautosaveinterval)**

---

#### :SetAutosaveInterval
```luau { .fn_type }
DubitStore:SetAutosaveInterval(datastoreIdentifier: string, interval: number): ()
```

This function will spawn a new background worker that'll invoke an autosave signal each interval

---

#### :ClearCache
```luau { .fn_type }
DubitStore:ClearCache(datastoreIdentifier: string, datastoreKey: string?): ()
```

This function will remove cached data for a data store key, however if a key is not defined, the datastore cache will be removed instead.

---

#### :YieldUntilDataUnlocked
```luau { .fn_type }
DubitStore:YieldUntilDataUnlocked(datastoreIdentifier: string, datastoreKey: string | Player, maximumYieldTime?: number?): boolean
```

This function will halt the execution of the current thread until either the datastore key can be written to, or the maximum yield time is surpassed

If no yield time is passed, then the function will indefinitely wait.

??? example "Example Usage"
	```lua
	local unlocked = DubitStore:YieldUntilDataUnlocked("datastoreIdentifier", "datastoreKey", 10)

	if not unlocked then
		return
	end

	local schema = DubitStore:ReconcileData({ Level = 1 }, "schemaIdentifier")
	```

---

#### :SetDataSessionLocked
```luau { .fn_type }
DubitStore:SetDataSessionLocked(datastoreIdentifier: string, datastoreKey: string | Player, locked: boolean?): ()
```

This function will set the 'locked' state of the datastoreKey to a given value, if the data is locked then no other server can write to this key, however when the data is unlocked - servers are able to write to this key.

!!! warning
	These changes will not take effect until you call :PushAsync to push data, including metadata to the server.

---

#### :OverwriteDataSessionLocked
```luau { .fn_type }
DubitStore:OverwriteDataSessionLocked(datastoreIdentifier: string, datastoreKey: string | Player, locked: boolean?): ()
```

This function will overwrite the 'locked' state for a given datastoreKey, by overwriting a data session we're risking an older record of that players data never being saved.

!!! warning
	Once you've overwritten a data session, if the session state is set to true - the previous server will be unable to write to the datastore.

---

#### :SyncDataAsync
```luau { .fn_type }
DubitStore:SyncDataAsync(datastoreIdentifier: string, datastoreKey: string | Player, reconciler: ((data: any, response: any): (...any))?): Promise
```

This function will merge the cached data with what the server already has, typically useful in cases where we're not locking player data.

In the case we pass no reconciler function, the library will use Sift to merge keys, the cached data taking priority.

---

#### :GetMetaDataAsync
```luau { .fn_type }
DubitStore:GetMetaDataAsync(datastoreIdentifier: string, datastoreKey: string | Player): Promise<{[string]: any}>
```

This function retrieves the MetaData of a key.

---

#### :SetMetaDataAsync
```luau { .fn_type }
DubitStore:SetMetaDataAsync(datastoreIdentifier: string, datastoreKey: string | Player, value: {[string]: any}): Promise
```

This function sets the MetaData of a key.

---

#### :GetDataAsync
```luau { .fn_type }
DubitStore:GetDataAsync(datastoreIdentifier: string, datastoreKey: string | Player, version?: string?): Promise<{[string]: any}>
```

This function retrieves the Data of a key. You can use the third parameter to fetch an older version of said key.

??? example "Example Usage"
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

---

#### :GetDataVersionsAsync
```luau { .fn_type }
DubitStore:GetDataVersionsAsync(datastoreIdentifier: string, datastoreKey: string | Player, sortDirection?: Enum.SortOrder?, minDate?: number?, maxDate?: number?, pageSize?: number?) → : Promise<DataStoreVersionPages>
```

This function retrieves a list of versions this key currently has.

---

#### :SetDataAsync
```luau { .fn_type }
DubitStore:SetDataAsync(datastoreIdentifier: string, datastoreKey: string | Player, value: any): Promise
```

This function sets the Data of a key. This method returns a promise in order to do the following;
- Remain consistant with it's counterpart, GetAsync..
- Provide a friendly approach to how a developer can handle syntax..
- Scaleable error handling..

??? example "Example Usage"
	```lua
	DubitStore:SetDataAsync("datastoreIdentifier", "datastoreKey", { abc = 123 })
	DubitStore:PushAsync("datastoreIdentifier", "datastoreKey")
	```

!!! warning
	These changes will not take effect until you call **[PushAsync](#pushasync)** to push data, including metadata to the server.

---

#### :UpdateDataAsync
```luau { .fn_type }
DubitStore:UpdateDataAsync(datastoreIdentifier: string, datastoreKey: string | Player, callback: (data: any) -> (any)): Promise<string, DataStoreKeyInfo>
```

This function will enable developers to both GET and SET data within the same function, avoiding server-server sync issues.

??? example "Example Usage"
	```lua
	DubitStore:UpdateDataAsync("datastoreIdentifier", "datastoreKey", function(data)
		return { Coins = data.Coins + 1 }
	end)
	```

!!! warning
	This function will NOT write to cache, you do NOT need to call :PushAsync after making this call.

---

#### :GetOrderedKeyAsync
```luau { .fn_type }
DubitStore:GetOrderedKeyAsync(datastoreIdentifier: string, datastoreKey: string | Player): Promise<number>
```

This function retrieves the value for an ordered data store key, this function is useful in the case you want to get a specific players value in an ordered datastore.

!!! warning
	This function will NOT read cache, it will instead make a query to the datastore backend on each call.

---

#### :GetOrderedDataAsync
```luau { .fn_type }
DubitStore:GetOrderedDataAsync(datastoreIdentifier: string, ascending: boolean, pageSize: number, minValue?: number?, maxValue?: number?): Promise<DataStorePages>
```

This function retrieves ordered datastore pages, enabling the developers to create functionality such as leaderboards.

!!! warning
	This function will NOT read cache, it will instead make a query to the datastore backend on each call.

---

#### :SetOrderedDataAsync
```luau { .fn_type }
DubitStore:SetOrderedDataAsync(datastoreIdentifier: string, datastoreKey: string | Player, value: number): Promise<string, DataStoreKeyInfo>
```

This function sets the value of 'datastoreKey' to a given input inside of the ordered data store.

!!! warning
	This function will NOT write to cache, you do NOT need to call **[PushAsync](#pushasync)** after making this call.

---

#### :RemoveOrderedAsync
```luau { .fn_type }
DubitStore:RemoveOrderedAsync(datastoreIdentifier: string, datastoreKey: string | Player): Promise
```

This function will remove ordered data that is tied to the 'datastoreKey' under the given 'datastoreIdentifier'

---

#### :RemoveAsync
```luau { .fn_type }
DubitStore:RemoveAsync(datastoreIdentifier: string, datastoreKey: string | Player): Promise
```

This function will remove data that is tied to the 'datastoreKey' under the given 'datastoreIdentifier'

---

#### :PushAsync
```luau { .fn_type }
DubitStore:PushAsync(datastoreIdentifier: string, datastoreKey: string | Player, userIds?: {number | Player}?): Promise<string, DataStoreKeyInfo>
```

This function will push any changes made in the cache to the server, if for some reason the push fails, the promise will reject.

## Container

Containers are objects that contain a value, the object will then provide quality of life functions for manipulating this value.

### Functions

#### .is
```luau { .fn_type }
Container.is(object?: Container?): boolean
```

This function compares the first parameter to the class 'Container'

---

#### .new
```luau { .fn_type }
Container.new(data: any): Container
```

This function constructs a new 'Container' class

---

#### :ToString()
```luau { .fn_type }
Container:ToString(): string
```

This function generates a string that shows the following; Container Type, Allocated Data Type, Allocated Data Value.

---

#### :ToValue()
```luau { .fn_type }
Container:ToValue(): any
```

This function returns the allocated Data Value.

---

#### :ToDataType()
```luau { .fn_type }
Container:ToDataType(): string
```

This function returns the type of the allocated Data Value


## Middleware

Middleware represents an object that we can create to help transform an input into something else we can use.

### Types

#### MiddlewareActionType
```luau { .fn_type }
type MiddlewareActionType = "Get" | "Set"
```

### Properties

#### action
```luau { .fn_type }
Middleware.action: MiddlewareActionType
```

### Functions

#### .is
```luau { .fn_type }
Middleware.is(object?: Middleware?): boolean
```

This function compares the first parameter to the 'Middleware' class

---

#### .new
```luau { .fn_type }
Middleware.new(callback: (...any) -> (...any)): Middleware
```

This function constructs a new 'Middleware' class

---

#### :ToString
```luau { .fn_type }
Middleware:ToString(): string
```

This function generates a string that shows the following; Middleware Type, Allocated Data Type, Allocated Data Value.

---

#### :Call
```luau { .fn_type }
Middleware:Call(...): ...any
```