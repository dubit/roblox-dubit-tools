--[[
	Module responsible for determining whether a player is authorized to use debug tools.

	By default only owners are authorized to use the tool.

	If the player joins via a deeplink with the launchdata of "NODEBUG", then the player will not be able to access
	debug tools regardless of usual authorization. This is designed to allow them to emulate what the experience
	is like for players who do not have access to debug tools.

	https://www.roblox.com/games/start?placeId=0&launchData=NODEBUG
]]
local Players = game:GetService("Players")

local DebugToolRootPath = script.Parent.Parent
local SharedPath = DebugToolRootPath.Shared

local Signal = require(SharedPath.Signal)
local Constants = require(SharedPath.Constants)

local playerAuthorizedSignal = Signal.new()
local playerAuthorizationLostSignal = Signal.new()

local playersData = {}
local currentAuthorizationMethod: (Player) -> boolean

local function defaultAuthorizationMethod(player: Player)
	local isAuthorized = false

	if game.CreatorType == Enum.CreatorType.User then
		if game.CreatorId == 0 then
			isAuthorized = true -- Local studio session within unpublished experience
		else
			isAuthorized = player.UserId == game.CreatorId
		end
	elseif game.CreatorType == Enum.CreatorType.Group then
		isAuthorized = player:GetRankInGroup(game.CreatorId) == 255
	end

	return isAuthorized
end

currentAuthorizationMethod = defaultAuthorizationMethod

local function playerAdded(player: Player)
	local wasPlayerAuthorized = false
	if playersData[player] and playersData[player].Authorized then
		wasPlayerAuthorized = true
	end

	local authState = {
		Authorized = false,
		Authorizing = true,
	}

	playersData[player] = authState

	local success, result = pcall(currentAuthorizationMethod, player)

	-- The authorization method switched in the meantime or player left
	if playersData[player] ~= authState then
		return
	end

	if not success then
		authState.Authorized = false
		warn(`An issue occured while authorizing {player.DisplayName}\n{result}`)
	else
		authState.Authorized = result == true
	end

	-- If player has the "NODEBUG" launch data, prevent access to debug tools.
	local joinData = player:GetJoinData()
	local launchData = joinData and joinData.LaunchData
	if launchData == "NODEBUG" then
		authState.Authorized = false
	end

	authState.Authorizing = false

	player:SetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE, authState.Authorized)

	if not authState.Authorized then
		if wasPlayerAuthorized then
			playerAuthorizationLostSignal:Fire(player)
		end
		return
	end

	playerAuthorizedSignal:Fire(player)
end

local function playerRemoved(player: Player)
	if not playersData[player] then
		return
	end

	playersData[player] = nil
end

Players.PlayerRemoving:Connect(playerRemoved)
Players.PlayerAdded:Connect(playerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

local Authorization = {
	PlayerAuthorized = playerAuthorizedSignal,
	PlayerAuthorizationLost = playerAuthorizationLostSignal,
}

function Authorization.IsPlayerAuthorizedAsync(self, player: Player)
	assert(self == Authorization, "Expected ':' not '.' calling member function IsPlayerAuthorizedAsync")

	local playerData = playersData[player]
	if not playerData then
		return false
	end

	while playersData[player] and playerData.Authorizing do
		task.wait()
	end

	return playersData[player] and playerData.Authorized
end

function Authorization.SetAuthorizationCallback(self, callback: ((player: Player) -> boolean)?)
	assert(self == Authorization, "Expected ':' not '.' calling member function setAuthorizationCallback")

	if callback and typeof(callback) == "function" then
		currentAuthorizationMethod = callback
	else
		currentAuthorizationMethod = defaultAuthorizationMethod
	end

	for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end
end

function Authorization.GetAuthorizedPlayers(self)
	assert(self == Authorization, "Expected ':' not '.' calling member function GetAuthorizedPlayers")

	local authorizedPlayers = {}

	for player, data in playersData do
		if data.Authorized == true then
			table.insert(authorizedPlayers, player)
		end
	end

	return authorizedPlayers
end

return Authorization
