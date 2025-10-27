local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:CreateDataSchema("PlayerData", {
	["Gold"] = DubitStore.Container.new(5),
})

local capturedPlayerData = {}

local function onPlayerAdded(player)
	local playerKey = tostring(player.UserId)

	player.Chatted:Connect(function()
		capturedPlayerData[player].Gold += 5

		print("Increment:", capturedPlayerData[player].Gold)
	end)

	warn("Yielding..")
	DubitStore:YieldUntilDataUnlocked("PlayerDataStore", playerKey)
	DubitStore:GetDataAsync("PlayerDataStore", playerKey)
		:andThen(function(data)
			local playerData = DubitStore:ReconcileData(data, "PlayerData")

			warn("Got:", playerData)

			capturedPlayerData[player] = playerData
		end)
		:andThen(function()
			DubitStore:SetDataSessionLocked("PlayerDataStore", playerKey, true)
			DubitStore:PushAsync("PlayerDataStore", playerKey, { player.UserId }):andThen(function()
				print("Locked Player Data!")
			end)
		end)
end

local function onPlayerRemoving(player)
	local playerKey = tostring(player.UserId)

	if not capturedPlayerData[player] then
		return
	end

	DubitStore:SetDataSessionLocked("PlayerDataStore", playerKey, false)
	DubitStore:SetDataAsync("PlayerDataStore", playerKey, capturedPlayerData[player]):await()

	DubitStore:PushAsync("PlayerDataStore", playerKey, { player.UserId }):andThen(function()
		warn("Set:", capturedPlayerData[player])

		capturedPlayerData[player] = nil
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetChildren() do
	onPlayerAdded(player)
end

game:BindToClose(function()
	for _, player in Players:GetChildren() do
		onPlayerRemoving(player)
	end
end)
