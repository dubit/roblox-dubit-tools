local RunService = game:GetService("RunService")
local Package = script

local Signal = require(script.Parent.Signal)

local getDataStoreForServer = require(Package.Functions.getDataStoreFor)
local getKeysFor = require(Package.Functions.getKeysFor)
local retryIfFailed = require(Package.Functions.retryIfFailed)

local TOTALIZER_UPDATE_LOOP_TIME = 60
local TIME_BEFORE_UPDATING = TOTALIZER_UPDATE_LOOP_TIME / 2

local isInitialised = false
local lastSyncedTimestamps = {}

--[=[
	@class Totalizers
	@__index = internal

	The community goals/totaliser tool is a tool that allows us to create some sort of value that can be written to,
	and read from - from all Servers within a Roblox experience.

	This is useful in cases where you want to track something, for example - if you’re in an shooter game and want
	to track how many kills all players have made throughout the lifetime of the experience, you’re able to do that.
	Alongside this, we could use this value to award community members with free in-game items.

	For example, tracking how many players have liked and joined the group, and once 1000~ players have, award
	players 1000 in game cash!
]=]
local Totalizers = {}

Totalizers.internal = {}
Totalizers.interface = {}

Totalizers.interface.TotalizerSynced = Signal.new()

--[=[
	@within Totalizers

	Will return whether the totalizer has at least the specified amount.
]=]
function Totalizers.interface.HasAtLeast(totalizer: string, target: number): boolean
	local value = Totalizers.interface.Get(totalizer)

	return value >= target
end

--[=[
	@within Totalizers

	Will return the current value of the totalizer.
]=]
function Totalizers.interface.Get(totalizer: string): number
	local dataStore: DataStore? = getDataStoreForServer()

	if not dataStore then
		return 0
	end

	local success, value: any? = retryIfFailed(function()
		dataStore:GetAsync(`{totalizer}`)
	end)

	if not success or not value then
		return 0
	end

	return value
end

--[=[
	@within Totalizers

	Will increment the totalizer by the specified amount. If no increment amount is specified, will increment by 1.
]=]
function Totalizers.interface.Increment(totalizer: string, incrementBy: number?): boolean
	local valueToIncrementBy = incrementBy or 1
	local currentValue

	local dataStore: DataStore? = getDataStoreForServer()

	if not dataStore then
		return false
	end

	return retryIfFailed(function()
		dataStore:UpdateAsync(`{totalizer}`, function(value)
			local newValue

			if value then
				newValue = value + valueToIncrementBy
			else
				newValue = valueToIncrementBy
			end

			currentValue = newValue
			lastSyncedTimestamps[totalizer] = os.time()

			return newValue
		end)

		lastSyncedTimestamps[totalizer] = os.time()

		Totalizers.interface.TotalizerSynced:Fire(totalizer, currentValue)
	end)
end

--[=[
	@within Totalizers

	Will reset the totalizer to 0.
]=]
function Totalizers.interface.Reset(totalizer: string): boolean
	local dataStore: DataStore? = getDataStoreForServer()

	if not dataStore then
		return false
	end

	return retryIfFailed(function()
		dataStore:SetAsync(`{totalizer}`, 0)
	end)
end

--[=[
	@within Totalizers

	Initializes the Totalizers package by setting up necessary event listeners and tracking systems.

	:::caution
	The Totalizers package initializes itself automatically. Developers requiring this module do not need to call this
	function.
	:::
]=]
function Totalizers.interface.Initialize()
	if isInitialised then
		assert(isInitialised == false, `Totalizers package is already initialised!`)
	else
		isInitialised = true
	end

	local datastore

	local function updateKeys()
		local keys = getKeysFor(datastore, 5)

		for _, totalizer in keys do
			if not lastSyncedTimestamps[totalizer] then
				if os.time() - lastSyncedTimestamps[totalizer] < TIME_BEFORE_UPDATING then
					continue
				end
			end

			lastSyncedTimestamps[totalizer] = os.time()

			local value = Totalizers.interface.Get(totalizer)

			Totalizers.interface.TotalizerSynced:Fire(totalizer, value)
		end
	end

	if RunService:IsServer() then
		datastore = getDataStoreForServer()

		if not datastore then
			return
		end

		while true do
			updateKeys()

			task.wait(TOTALIZER_UPDATE_LOOP_TIME)
		end
	end
end

return Totalizers.interface
