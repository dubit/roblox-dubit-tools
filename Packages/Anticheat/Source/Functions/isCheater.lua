--[[
	Returns either true/false dependent on if a player has been flagged at some point in the past for cheating
]]

local DataStoreService = game:GetService("DataStoreService")

local Package = script.Parent.Parent

local isOfflineEnvironment = require(Package.Functions.isOfflineEnvironment)

local MAX_FAILED_ATTEMPTS = 10

local dataStore

return function(player: Player): boolean
	if player:GetAttribute("DubitAnticheat_KnownCheater") then
		return true
	end

	if isOfflineEnvironment() then
		return false
	end

	if not dataStore then
		dataStore = DataStoreService:GetDataStore("Dubit_AntiCheat")
	end

	local success, data = false, nil
	local failedAttempts = 0

	while not success do
		if failedAttempts >= MAX_FAILED_ATTEMPTS then
			return false
		end

		success, data = pcall(dataStore.GetAsync, dataStore, player.UserId)

		if not success then
			failedAttempts += 1
		end

		task.wait(5)
	end

	return data and data.flagged or false
end
