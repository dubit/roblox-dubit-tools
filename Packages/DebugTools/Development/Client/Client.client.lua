local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local DebugTools = require(ReplicatedStorage.Packages.DebugTools)

DebugTools.Action.new("Destroy Universe", nil, function() end)

DebugTools.Action.new("Test Action", nil, function(player: Player)
	print(`Player '{player.DisplayName}' executed an action!`)
end, {
	{
		Type = "Player",
		Name = "Player",
	},
})
