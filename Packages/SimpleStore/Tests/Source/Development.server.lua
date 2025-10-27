local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)
local SimpleStore = require(ReplicatedStorage.Packages.SimpleStore)

DubitStore:SetVerbosity(false)

local function onPlayerAdded(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui")
	local textLabel = Instance.new("TextLabel")

	screenGui.Parent = playerGui
	screenGui.Name = "Simple-Store-Test-Debug"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true

	textLabel.Text = `Loading data..`
	textLabel.Parent = screenGui
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.AnchorPoint = Vector2.one / 2
	textLabel.Size = UDim2.fromScale(1, 1)

	local playerStore = SimpleStore:GetPlayerStore(player)

	if playerStore.IsNewPlayer then
		playerStore:Set({
			Dict = {
				Dict = {
					Value = true,
				},

				TimesJoined = 0,
			},
		})
	end

	---

	playerStore:SetKey("Dict.TimesJoined", playerStore:GetKey("Dict.TimesJoined", 0) + 1)

	textLabel.Text = `Joined '{playerStore:GetKey("Dict.TimesJoined", 0)}' times!`
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player: Player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
