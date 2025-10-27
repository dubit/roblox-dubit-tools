--[[
	Will flag a player as a known cheater, will also save this to datastore, if datastore is available.
]]

local DataStoreService = game:GetService("DataStoreService")

local Package = script.Parent.Parent

local isCheater = require(Package.Functions.isCheater)
local isOfflineEnvironment = require(Package.Functions.isOfflineEnvironment)

local MAX_FAILED_ATTEMPTS = 10

local dataStore

return function(player: Player): ()
	local isAlreadyACheater = isCheater(player)

	player:SetAttribute(`DubitAnticheat_KnownCheater`, true)

	if isAlreadyACheater then
		return
	end

	if isOfflineEnvironment() then
		return
	end

	if not dataStore then
		dataStore = DataStoreService:GetDataStore("Dubit_AntiCheat")
	end

	local success = false
	local failedAttempts = 0

	while not success do
		if failedAttempts >= MAX_FAILED_ATTEMPTS then
			return false
		end

		success = pcall(dataStore.SetAsync, dataStore, player.UserId, {
			flagged = true,
		}, { player.UserId })

		if not success then
			failedAttempts += 1
		end

		task.wait(5)
	end
end
