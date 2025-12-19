local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugToolRootPath = script.Parent.Parent
local SharedPath = DebugToolRootPath.Shared

local Signal = require(SharedPath.Signal)
local Constants = require(SharedPath.Constants)

local Authorization = require(DebugToolRootPath.Server.Authorization)

local Networking = {}
Networking.internal = {
	TopicCallbacks = {},
	NetworkTrafficRemote = nil :: RemoteEvent?,
	NetworkTargets = {},
}
Networking.interface = {
	NetworkTargetAdded = Signal.new(), -- TODO: Remove, there is Authorization.PlayerAuthorized
	NetworkTargetRemoved = Signal.new(), -- TODO: Remove, there is Authorization.PlayerAuthorizationLost
}

function Networking.internal.playerRemoving(player: Player)
	if not Networking.internal.NetworkTargets[player] then
		return
	end

	Networking.internal.NetworkTargets[player] = nil

	Networking.interface.NetworkTargetRemoved:Fire(player)
end

function Networking.internal.registerNetworkTarget(player: Player)
	if Networking.internal.NetworkTargets[player] then
		return
	end

	if not Authorization:IsPlayerAuthorizedAsync(player) then
		return
	end

	Networking.internal.NetworkTargets[player] = {
		MessageQueue = {},
	}

	Networking.interface.NetworkTargetAdded:Fire(player)
end

function Networking.internal.createTrafficRemote()
	local networkTrafficRemote: RemoteEvent = Instance.new("RemoteEvent")
	networkTrafficRemote.Name = Constants.NETWORK_TRAFFIC_REMOTE_NAME
	networkTrafficRemote.Parent = ReplicatedStorage

	Networking.internal.NetworkTrafficRemote = networkTrafficRemote
end

function Networking.internal.listenToNetworkTraffic()
	Networking.internal.NetworkTrafficRemote.OnServerEvent:Connect(
		function(player: Player, messageContent: { any } | string)
			if not Authorization:IsPlayerAuthorizedAsync(player) then
				player:Kick("Attempted to perform unauthorized action.")
				return
			end

			if messageContent == "_ready_" then
				Networking.internal.registerNetworkTarget(player)
				return
			end

			if typeof(messageContent) ~= "table" then
				return
			end

			for _, message in messageContent do
				local topic: string = message[1]
				local params: { any } = message[2]

				if not topic or not params then
					continue
				end

				Networking.internal.invokeTopic(topic, player, table.unpack(params))
			end
		end
	)
end

function Networking.internal.initiateTrafficHeartbeat()
	RunService.Heartbeat:Connect(function()
		for player: Player, playerData in Networking.internal.NetworkTargets do
			if #playerData.MessageQueue <= 0 then
				continue
			end

			Networking.internal.NetworkTrafficRemote:FireClient(player, playerData.MessageQueue)

			playerData.MessageQueue = {}
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		Networking.internal.playerRemoving(player)
	end)
end

function Networking.internal.invokeTopic(topic: string, player: Player, ...)
	local topicCallbacks = Networking.internal.TopicCallbacks[topic]

	if not topicCallbacks then
		return
	end

	for _, callback in topicCallbacks do
		callback(player, ...)
	end
end

function Networking.interface:SendMessageToPlayer(player: Player, topic: string, ...)
	if not Networking.internal.NetworkTargets[player] then
		return
	end

	table.insert(Networking.internal.NetworkTargets[player].MessageQueue, {
		topic,
		{ ... },
	})
end

function Networking.interface:SendMessage(topic: string, ...)
	for player: Player in Networking.internal.NetworkTargets do
		Networking.interface:SendMessageToPlayer(player, topic, ...)
	end
end

function Networking.interface:SubscribeToTopic(topic: string, callback: (...any) -> ...any): ()
	if not Networking.internal.TopicCallbacks[topic] then
		Networking.internal.TopicCallbacks[topic] = {}
	end

	local topicCallbacks = Networking.internal.TopicCallbacks[topic]

	table.insert(topicCallbacks, callback)
	return function()
		local callbackIndex: number? = table.find(topicCallbacks, callback)
		table.remove(topicCallbacks, callbackIndex)
	end
end

-- TODO: Add :GetAuthorizedPlayers to Authorization, remove this one
function Networking.interface:GetNetworkTargets(): { Player }
	local networkTargets: { Player } = {}
	for player: Player in Networking.internal.NetworkTargets do
		table.insert(networkTargets, player)
	end

	return networkTargets
end

Networking.internal.createTrafficRemote()
Networking.internal.listenToNetworkTraffic()
Networking.internal.initiateTrafficHeartbeat()

return Networking.interface
