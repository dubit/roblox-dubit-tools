--!strict

--[[
	Module responsible for determining whether a player is authorized to use debug tools. Players are authorized if
	they are playing in studio, or they are sufficient rank in the defined roblox group.

	If the player joins via a deeplink with the launchdata of "NODEBUG", then the player will not be able to access
	debug tools regardless of usual authorization. This is designed to allow them to emulate what the experience
	is like for players who do not have access to debug tools.

	In order to allow QA to test a game without debug tools active, provide a link in the following format:
	https://www.roblox.com/games/start?placeId=00000000&launchData=NODEBUG
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugToolRootPath = script.Parent.Parent
local SharedPath = DebugToolRootPath.Shared

local Signal = require(SharedPath.Signal)
local Constants = require(SharedPath.Constants)

type PlayerData = {
	Authorized: boolean,
	Authorizing: boolean,
}

local Authorization = {}
Authorization.internal = {
	Players = {} :: { [Player]: PlayerData },
}
Authorization.interface = {
	PlayerAuthorized = Signal.new(),
}

function Authorization.internal.playerAdded(player: Player)
	Authorization.internal.Players[player] = {
		Authorized = false,
		Authorizing = true,
	}

	local isAuthorized: boolean = RunService:IsStudio()
		or player:GetRankInGroup(Constants.AUTHORIZED_GROUP_ID) >= Constants.AUTHORIZED_GROUP_RANK

	-- if player leaves while he was being authorized
	if not Authorization.internal.Players[player] then
		return
	end

	-- If player has the "NODEBUG" launch data, prevent access to debug tools.
	local joinData = player:GetJoinData()
	local launchData = joinData and joinData.LaunchData
	if launchData == Constants.NO_DEBUG_LAUNCH_DATA then
		isAuthorized = false
	end

	player:SetAttribute(Constants.IS_AUTHORIZED_ATTRIBUTE, isAuthorized)
	Authorization.internal.Players[player].Authorized = isAuthorized
	Authorization.internal.Players[player].Authorizing = false

	if not isAuthorized then
		return
	end

	Authorization.interface.PlayerAuthorized:Fire(player)
end

function Authorization.internal.playerRemoved(player: Player)
	if not Authorization.internal.Players[player] then
		return
	end

	Authorization.internal.Players[player] = nil
end

function Authorization.internal.listenToPlayers()
	Players.PlayerAdded:Connect(function(player: Player)
		Authorization.internal.playerAdded(player)
	end)

	for _, player: Player in Players:GetPlayers() do
		Authorization.internal.playerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		Authorization.internal.playerRemoved(player)
	end)
end

function Authorization.interface.isPlayerAuthorized(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end

	local playerData = Authorization.internal.Players[player]
	if not playerData then
		return false
	end

	while Authorization.internal.Players[player] and playerData.Authorizing do
		task.wait()
	end

	return Authorization.internal.Players[player] and playerData.Authorized
end

Authorization.internal.listenToPlayers()

return Authorization.interface
