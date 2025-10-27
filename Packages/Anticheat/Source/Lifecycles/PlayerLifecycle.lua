--[[
	This specific module implements the following lifecycles:
		- OnPlayerAdded
			When a player joins the server.
		- OnPlayerRemoving
			When a player leaves the server.
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent

local Runtime = require(Package.Parent.Runtime)

local ON_PLAYER_ADDED_LIFECYCLE_NAME = "OnPlayerAdded"
local ON_PLAYER_REMOVING_LIFECYCLE_NAME = "OnPlayerRemoving"

return function(moduleArray: { ModuleScript })
	Players.PlayerAdded:Connect(function(player: Player)
		Runtime:CallMethodOn(moduleArray, ON_PLAYER_ADDED_LIFECYCLE_NAME, player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		Runtime:CallMethodOn(moduleArray, ON_PLAYER_REMOVING_LIFECYCLE_NAME, player)
	end)

	for _, player: Player in Players:GetPlayers() do
		Runtime:CallMethodOn(moduleArray, ON_PLAYER_ADDED_LIFECYCLE_NAME, player)
	end
end
