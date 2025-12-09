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

local AllocationPool = {}
AllocationPool.interface = { -- TODO: Remove the interface table and simplify it to one table
	BudgetConsumed = Signal.new(),
	BudgetFailed = Signal.new(),
}

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

function AllocationPool.interface.UpdatePoolLimitAsync(poolName: string, poolLimit: number): ()
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)
	assert(type(poolLimit) == "number", `Expected parameter #2 'poolLimit' to be a number, got {type(poolLimit)}`)

	return DubitStore:UpdateDataAsync(POOL_DATASTORE, poolName, function(remoteBudgetModel)
		remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)
		remoteBudgetModel.PoolLimit = poolLimit

		return remoteBudgetModel
	end)
end

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

function AllocationPool.interface.ResetPoolAsync(poolName: string): Types.Promise
	assert(type(poolName) == "string", `Expected parameter #1 'poolName' to be a string, got {type(poolName)}`)

	return DubitStore:UpdateDataAsync(POOL_DATASTORE, poolName, function(remoteBudgetModel)
		remoteBudgetModel = DubitStore:ReconcileData(remoteBudgetModel, POOL_SCHEMA_NAME)
		remoteBudgetModel.PoolConsumed = 0

		return remoteBudgetModel
	end)
end

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

-- TODO: Probably remove this function and make it initialize when required?
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
