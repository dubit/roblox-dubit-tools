--[=[
	@class DubitUtils.RobloxGroup

	Contains utility functions for working with Roblox Groups.
]=]

local RunService = game:GetService("RunService")

local RobloxGroup = {}

--[=[
	@yields

	Check if the specified player is at or above the provided group rank, or otherwise succeeds the permissions of that rank.
	Returns `true` if any of the following conditions have been met:
	- The group rank of the player in the specified group matches or exceeds the minimum group rank
	- The player is the owner of the game
	- The player is whitelisted
	- The game is running in Studio
	
	@within DubitUtils.RobloxGroup

	@param player Player -- The player to check.
	@param minimumGroupRank number -- The minimum group rank to check the player's rank against.
	@param whitelist { [number]: any  }? -- An optional dictionary of player ID keys to pass this check, regardless of group rank.
	@param retries number? -- The number of times to retry getting the player's group rank. Defaults to 4.
	@param creatorIdOverride number? -- An optional override of the creator ID to check the player's rank in, if not desired to be that of the current experience.

	@return boolean -- Whether the player's rank matches or exceeds the minimum given, or otherwise succeeds its permissions.

	#### Example Usage

	```lua
	DubitUtils.RobloxGroup.isPlayerAboveGroupRank(playerWhoJustJoined, 250, { [aSpecificExternalPlayer.UserId] = true }, 3, 0000000)
	```
]=]
function RobloxGroup.isPlayerAboveGroupRank(
	player: Player,
	minimumGroupRank: number,
	whitelist: { [number]: any }?,
	retries: number?,
	creatorIdOverride: number?
): boolean
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		`Player must be a Player instance, received '{typeof(player)}'.`
	)
	assert(
		typeof(minimumGroupRank) == "number",
		`minimumGroupRank must be a number, received '{typeof(minimumGroupRank)}'.`
	)

	local creatorId = if typeof(creatorIdOverride) == "number" then creatorIdOverride else game.CreatorId
	minimumGroupRank = if typeof(minimumGroupRank) == "number" then minimumGroupRank else 254

	if RunService:IsStudio() or (typeof(whitelist) == "table" and whitelist[player.UserId]) then
		return true
	end

	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == creatorId
	end

	local rank = RobloxGroup.getMemberRank(player, creatorId, retries) or 0

	if game.CreatorType == Enum.CreatorType.Group then
		return rank >= minimumGroupRank
	end

	return false
end

--[=[
	@yields

	Get the rank of the given player in the group with the ID provided
	
	@within DubitUtils.RobloxGroup

	@param player Player -- The player to get the group rank of.
	@param groupId number? -- The ID of the group to check. Defaults to that of the current experience.
	@param retries number? -- The number of times to retry getting the player's group rank. Defaults to 4.

	@return number? -- The rank of the player in the given group, or nil if the function failed to get the player's rank.

	#### Example Usage

	```lua
	DubitUtils.RobloxGroup.getMemberRank(somePlayer, nil, 5)
	```

	:::warning
	if 'groupId' is not provided and the creator ID of the current experience is not that of a group,
	this function will fail and return nil.
	:::
]=]
function RobloxGroup.getMemberRank(player: Player, groupId: number?, retries: number?): number?
	local attemptIndex = 0
	local success, rank

	local finalGroupId: number
	if typeof(groupId) == "number" then
		finalGroupId = groupId
	else
		if game.CreatorType ~= Enum.CreatorType.Group then
			warn("Cannot get group rank if experience's creator ID is not that of a group.")
			return nil
		end

		finalGroupId = game.CreatorId
	end
	retries = if typeof(retries) == "number" then retries else 4

	repeat
		success, rank = xpcall(function()
			return player:GetRankInGroup(finalGroupId)
		end, function(err)
			return err
		end)

		attemptIndex += 1
		if not success then
			task.wait(1)
		end
	until success or attemptIndex == retries

	if not success then
		warn(`Failed to get group rank for player '{player.Name}': {rank}`)
		return nil
	end

	return rank
end

return RobloxGroup
