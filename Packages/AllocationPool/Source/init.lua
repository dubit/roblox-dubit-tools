local Players = game:GetService("Players")

local DubitStore = require(script.Parent.DubitStore)
local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)

local Types = require(script.Types)

local POOL_DATASTORE = "AllocationPool_v1"
local PLAYER_DATASTORE = "AllocationPlayers_v1"
local POOL_SCHEMA_NAME = "AllocationBudgetSchema_Pool"
local PLAYERS_SCHEMA_NAME = "AllocationBudgetSchema_Players"

local LOOP_SPEED = 5

local isInitialized = false
local poolsToSync = {}
local lockedPools = {}

DubitStore:CreateDataSchema(POOL_SCHEMA_NAME, {
	PoolConsumed = DubitStore.Container.new(0),
	PoolLimit = DubitStore.Container.new(0),
})

DubitStore:CreateDataSchema(PLAYERS_SCHEMA_NAME, {
	PoolsConsumed = DubitStore.Container.new({}),
})

--[=[
	@class AllocationPool

	We need a specific type of library that’ll allow developers to award items if the allocation of the item awarded
	still has budget.. and not to consume that budget if the player DOES have that item.
]=]
local AllocationPool = {}

AllocationPool.interface = {}

--[=[
	@prop BudgetConsumed Signal
	@within AllocationPool
]=]
AllocationPool.interface.BudgetConsumed = Signal.new()

--[=[
	@prop BudgetFailed Signal
	@within AllocationPool
]=]
AllocationPool.interface.BudgetFailed = Signal.new()

--[=[
	@within AllocationPool

	Creates a new allocation pool with the specified name and limit.

	This function creates a new allocation pool in the datastore with the given name and maximum allocation limit. If a pool
	with the same name already exists, it will update the limit if different from the provided value.

	```lua
	AllocationPool.CreatePoolAsync("MyPool", 10):expect()
	```
]=]
function AllocationPool.interface.CreatePoolAsync(poolName: string, poolLimit: number): ()
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)
	assert(type(poolLimit) == "number", `Expected parameter #2 'poolLimit' to be a number, got {type(poolLimit)}`)

	return Promise.new(function(resolve, reject)
		DubitStore:GetDataAsync(POOL_DATASTORE, poolName)
			:andThen(function(remoteBudgetModel)
				remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)

				if remoteBudgetModel.PoolLimit == poolLimit then
					resolve()

					return
				end

				AllocationPool.interface
					.UpdatePoolLimitAsync(poolName, poolLimit)
					:andThen(function()
						resolve()
					end)
					:catch(reject)
			end)
			:catch(reject)
	end)
end

--[=[
	@within AllocationPool

	Updates the pool's limit value in the datastore.

	This function updates the pool's maximum allocation limit in the datastore. The new limit will be applied immediately
	and affects future allocation attempts.

	```lua
	AllocationPool.UpdatePoolLimitAsync("MyPool", 10):expect()
	```
]=]
function AllocationPool.interface.UpdatePoolLimitAsync(poolName: string, poolLimit: number): ()
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)
	assert(type(poolLimit) == "number", `Expected parameter #2 'poolLimit' to be a number, got {type(poolLimit)}`)

	return DubitStore:UpdateDataAsync(POOL_DATASTORE, poolName, function(remoteBudgetModel)
		remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)
		remoteBudgetModel.PoolLimit = poolLimit

		return remoteBudgetModel
	end)
end

--[=[
	@within AllocationPool

	Returns the pool's limit value from the datastore.
	
	This function retrieves the pool's data and returns a promise that resolves with the maximum number of allocations
	allowed for the specified pool.

	```lua
	local poolLimit = AllocationPool.GetPoolLimitAsync("MyPool"):expect()
	```
]=]
function AllocationPool.interface.GetPoolLimitAsync(poolName: string): Types.Promise
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	return Promise.new(function(resolve, reject)
		while lockedPools[poolName] do
			task.wait()
		end

		lockedPools[poolName] = true

		DubitStore:ClearCache(POOL_DATASTORE, poolName)
		DubitStore:GetDataAsync(POOL_DATASTORE, poolName)
			:andThen(function(remoteBudgetModel)
				remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)

				resolve(remoteBudgetModel.PoolLimit)
			end)
			:catch(reject)
			:finally(function()
				lockedPools[poolName] = false
			end)
	end)
end

--[=[
	@within AllocationPool

	Returns the remaining allocations available in a pool.

	This function retrieves the pool's data from the datastore and calculates the difference between the pool's limit
	and current consumption count. The result represents how many more allocations can be made from the pool.

	```lua
	local lastPoolValue = AllocationPool.GetPoolReserveAsync("PreviousPool"):expect()
	local newPoolValue = AllocationPool.CreatePool("NewPool", DEFAULT_POOL_LIMIT + lastPoolValue):expect()
	```
]=]
function AllocationPool.interface.GetPoolReserveAsync(poolName: string): Types.Promise
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	return Promise.new(function(resolve, reject)
		while lockedPools[poolName] do
			task.wait()
		end

		lockedPools[poolName] = true

		DubitStore:ClearCache(POOL_DATASTORE, poolName)
		DubitStore:GetDataAsync(POOL_DATASTORE, poolName)
			:andThen(function(remoteBudgetModel)
				remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)

				resolve(remoteBudgetModel.PoolLimit - remoteBudgetModel.PoolConsumed)
			end)
			:catch(reject)
			:finally(function()
				lockedPools[poolName] = false
			end)
	end)
end

--[=[
	@within AllocationPool

	Returns the current consumption count for a specific pool.
	
	This function retrieves the pool's data from the datastore and returns a promise that resolves with the number
	of allocations consumed from the pool.

	```lua
	local poolCount = AllocationPool.GetPoolCountAsync("MyPool"):expect()
	```
]=]
function AllocationPool.interface.GetPoolCountAsync(poolName: string): Types.Promise
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	return Promise.new(function(resolve, reject)
		while lockedPools[poolName] do
			task.wait()
		end

		lockedPools[poolName] = true

		DubitStore:ClearCache(POOL_DATASTORE, poolName)
		DubitStore:GetDataAsync(POOL_DATASTORE, poolName)
			:andThen(function(remoteBudgetModel)
				remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)

				resolve(remoteBudgetModel.PoolConsumed)
			end)
			:catch(reject)
			:finally(function()
				lockedPools[poolName] = false
			end)
	end)
end

--[=[
	@within AllocationPool

	Resets a pool's consumption count back to zero.
	
	This function updates the pool's consumption count in the datastore and returns a promise that resolves when
	complete.
	
	This is useful for resetting pool allocations after a specific event or time period.

	```lua
	AllocationPool.ResetPoolAsync(player, poolName)
	```
]=]
function AllocationPool.interface.ResetPoolAsync(poolName: string): Types.Promise
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	return DubitStore:UpdateDataAsync(POOL_DATASTORE, poolName, function(remoteBudgetModel)
		remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)
		remoteBudgetModel.PoolConsumed = 0

		return remoteBudgetModel
	end)
end

--[=[
	@within AllocationPool

	Consumes a pool allocation for a player. This function updates both the player's consumed pools list and the pool's 
	consumption count. The operation is performed asynchronously and returns a promise that resolves when complete.

	If a player is provided, it will mark the pool as consumed for that player before attempting to consume from the pool.
	The size parameter determines how many allocations to consume from the pool, defaulting to 1 if not specified.

	:::caution
		This promise can reject if the pool is already consumed by the player or if the pool has reached its limit.
		implement error handling to handle these scenarios.
	:::

	:::caution
		This function will not error if the pool is already consumed by the player. You need to handle this scenario
		in your code.
	:::

	```lua
	AllocationPool.ConsumePoolAsync(player, poolName):andThen(function()
		awardUgc(player)
	end):catch(function(err)
		warn(err)
	end)

	-- or in the event you'd like to consume a budget anonymously

	AllocationPool.ConsumePoolAsync(nil, poolName):andThen(function()
		awardUgc(player)
	end):catch(function(err)
		warn(err)
	end)
	```
]=]
function AllocationPool.interface.ConsumePoolAsync(player: Player?, poolName: string, size: number?): Types.Promise
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	return Promise.new(function(resolve, reject)
		if player then
			local success, response = AllocationPool.interface.MarkConsumedAsync(player, poolName):await()

			if not success then
				reject(response)

				return
			end
		end

		local connection0
		local connection1

		connection0 = AllocationPool.interface.BudgetConsumed:Connect(function(...)
			local poolConsumed = select(1, ...)

			if poolConsumed ~= poolName then
				return
			end

			connection0:Disconnect()
			connection1:Disconnect()

			resolve(select(2, ...))
		end)

		connection1 = AllocationPool.interface.BudgetFailed:Connect(function(...)
			local poolConsumed = select(1, ...)

			if poolConsumed ~= poolName then
				return
			end

			connection0:Disconnect()
			connection1:Disconnect()

			reject(select(2, ...))
		end)

		if not poolsToSync[poolName] then
			poolsToSync[poolName] = 0
		end

		poolsToSync[poolName] += size or 1
	end)
end

--[=[
	@within AllocationPool

	Checks if a player has consumed a specific pool in the datastore.
	
	This function queries the player's consumed pools list to determine if the specified pool name exists.
	
	The operation is performed asynchronously and returns a promise that resolves with a boolean indicating
	consumption status.

	```lua
	local hasConsumed = AllocationPool.HasConsumedAsync(player, poolName):expect()
	```
]=]
function AllocationPool.interface.HasConsumedAsync(player: Player, poolName: string): Types.Promise
	assert(player.ClassName == "Player", `Expected parameter #1 'player' to be a Player, got {player.ClassName}`)
	assert(type(poolName) == "string", `Expected parameter #2 'poolName' to be a string, got {type(poolName)}`)

	return Promise.new(function(resolve, reject)
		while lockedPools[poolName] do
			task.wait()
		end

		lockedPools[poolName] = true

		DubitStore:ClearCache(PLAYER_DATASTORE, `{player.UserId}`)
		DubitStore:GetDataAsync(PLAYER_DATASTORE, `{player.UserId}`)
			:andThen(function(remoteBudgetModel)
				remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, PLAYERS_SCHEMA_NAME)

				resolve(table.find(remoteBudgetModel.PoolsConsumed, poolName) ~= nil)
			end)
			:catch(reject)
			:finally(function()
				lockedPools[poolName] = false
			end)
	end)
end

--[=[
	@within AllocationPool

	Will remove the users data from allocation pools datastore

	If the second parameter 'PoolName' is given, this function will remove all references to the pool name given.
	If the second parameter 'PoolName' is not given, this function will remove all pools from the users pools consumption.

	```lua
	AllocationPool.ResetConsumedAsync(player, poolName):expect()
	```
]=]
function AllocationPool.interface.ResetConsumedAsync(player: Player, poolName: string?): Types.Promise
	assert(player.ClassName == "Player", `Expected parameter #1 'player' to be a Player, got {player.ClassName}`)

	return Promise.new(function(resolve, reject)
		DubitStore:ClearCache(PLAYER_DATASTORE, `{player.UserId}`)

		if poolName then
			while lockedPools[poolName] do
				task.wait()
			end

			lockedPools[poolName] = true

			DubitStore:GetDataAsync(PLAYER_DATASTORE, `{player.UserId}`):await()
			DubitStore:UpdateDataAsync(PLAYER_DATASTORE, `{player.UserId}`, function(remoteBudgetModel)
				remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, PLAYERS_SCHEMA_NAME)

				local index = table.find(remoteBudgetModel.PoolsConsumed, poolName)

				while index do
					table.remove(remoteBudgetModel.PoolsConsumed, index)

					index = table.find(remoteBudgetModel.PoolsConsumed, poolName)
				end

				return remoteBudgetModel, { player.UserId }
			end)
				:andThen(function()
					resolve()
				end)
				:catch(reject)
				:finally(function()
					lockedPools[poolName] = false
				end)
		else
			DubitStore:RemoveAsync(PLAYER_DATASTORE, `{player.UserId}`)
				:andThen(function()
					resolve()
				end)
				:catch(reject)
		end
	end)
end

--[=[
	@within AllocationPool

	Marks a pool as consumed for a player in the datastore.
	
	This function updates the player's consumed pools list by adding the specified pool name. The operation is
	performed asynchronously and returns a promise that resolves when complete.

	```lua
	AllocationPool.MarkConsumedAsync(player, poolName):expect()
	```
]=]
function AllocationPool.interface.MarkConsumedAsync(player: Player, poolName: string): Types.Promise
	assert(player.ClassName == "Player", `Expected parameter #1 'player' to be a Player, got {player.ClassName}`)
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	DubitStore:GetDataAsync(PLAYER_DATASTORE, `{player.UserId}`):await()
	return DubitStore:UpdateDataAsync(PLAYER_DATASTORE, `{player.UserId}`, function(remoteBudgetModel)
		remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, PLAYERS_SCHEMA_NAME)

		table.insert(remoteBudgetModel.PoolsConsumed, poolName)

		return remoteBudgetModel, { player.UserId }
	end)
end

--[=[
	@within AllocationPool
	@private

	Initializes the AllocationPool service and starts the pool synchronization loop.
	
	This function sets up player cleanup and continuously updates pool consumption while managing budget limits.
]=]
function AllocationPool.interface.Initialize()
	assert(isInitialized == false, "AllocationPool has already been initialized")

	isInitialized = true

	Players.PlayerRemoving:Connect(function(player)
		DubitStore:ClearCache(PLAYER_DATASTORE, `{player.UserId}`)
	end)

	Players.PlayerAdded:Connect(function(player)
		DubitStore:GetDataAsync(PLAYER_DATASTORE, `{player.UserId}`)
	end)

	for _, player in Players:GetPlayers() do
		DubitStore:GetDataAsync(PLAYER_DATASTORE, `{player.UserId}`)
	end

	while true do
		task.wait(LOOP_SPEED)

		local updatedPools = {}
		local failedPools = {}
		local promisesToWaitFor = {}
		local skippedPools = {}

		for pool, increment in poolsToSync do
			local latestValue

			poolsToSync[pool] = nil

			if lockedPools[pool] then
				skippedPools[pool] = increment

				continue
			end

			table.insert(
				promisesToWaitFor,
				DubitStore:UpdateDataAsync(POOL_DATASTORE, pool, function(remoteBudgetModel)
					remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)
					remoteBudgetModel.PoolConsumed += increment

					latestValue = remoteBudgetModel.PoolConsumed

					assert(latestValue <= remoteBudgetModel.PoolLimit, "Pool limit exceeded")

					return remoteBudgetModel
				end)
					:andThen(function()
						updatedPools[pool] = latestValue
					end)
					:catch(function(reason)
						failedPools[pool] = reason

						warn(`Failed to update pool {pool} - {reason}`)
					end)
			)
		end

		Promise.all(promisesToWaitFor):await()

		poolsToSync = skippedPools

		for pool, latestValue in updatedPools do
			AllocationPool.interface.BudgetConsumed:FireDeferred(pool, latestValue)
		end

		for pool, reason in failedPools do
			AllocationPool.interface.BudgetFailed:FireDeferred(pool, reason)
		end
	end
end

return AllocationPool.interface
