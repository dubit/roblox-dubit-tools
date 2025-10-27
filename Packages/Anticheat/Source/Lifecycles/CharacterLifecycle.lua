--[[
	This specific module implements the following lifecycles:
		- OnCharacterAdded
			When a players character has been added
		- OnCharacterRemoving
			When a players character has been removed
]]

local Players = game:GetService("Players")

local Package = script.Parent.Parent

local Runtime = require(Package.Parent.Runtime)

local ON_CHARACTER_ADDED_LIFECYCLE_NAME = "OnCharacterAdded"
local ON_CHARACTER_REMOVING_LIFECYCLE_NAME = "OnCharacterRemoving"

return function(moduleArray: { ModuleScript })
	local function playerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			Runtime:CallMethodOn(moduleArray, ON_CHARACTER_ADDED_LIFECYCLE_NAME, character, player)
		end)

		player.CharacterRemoving:Connect(function(character)
			Runtime:CallMethodOn(moduleArray, ON_CHARACTER_REMOVING_LIFECYCLE_NAME, character, player)
		end)

		if player.Character then
			Runtime:CallSpawnedMethodOn(moduleArray, ON_CHARACTER_ADDED_LIFECYCLE_NAME, player.Character, player)
		end
	end

	Players.PlayerAdded:Connect(playerAdded)

	for _, player: Player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end
end
