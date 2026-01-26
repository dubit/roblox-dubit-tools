local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugToolRootPath = script.Parent.Parent
local SharedPath = DebugToolRootPath.Shared

local Constants = require(SharedPath.Constants)

local Authorization = require(DebugToolRootPath.Server.Authorization)

local networkTrafficRemote = Instance.new("RemoteEvent")
networkTrafficRemote.Name = Constants.NETWORK_TRAFFIC_REMOTE_NAME
networkTrafficRemote.Parent = ReplicatedStorage

local outgoingMessageQueue = {}
local readyTargets = {}
local topicCallbacks = {}

local function playerLostAuthorization(player: Player)
	if not outgoingMessageQueue[player] then
		return
	end

	readyTargets[player] = nil
	outgoingMessageQueue[player] = nil
end

local function playerAuthorized(player: Player)
	if outgoingMessageQueue[player] then
		return
	end

	outgoingMessageQueue[player] = {}
end

local function invokeTopic(topic: string, player: Player, ...)
	local topicCallbacks = topicCallbacks[topic]

	if not topicCallbacks then
		return
	end

	for _, callback in topicCallbacks do
		callback(player, ...)
	end
end

Players.PlayerRemoving:Connect(playerLostAuthorization)
Authorization.PlayerAuthorized:Connect(playerAuthorized)
Authorization.PlayerAuthorizationLost:Connect(playerLostAuthorization)
for _, player in Authorization:GetAuthorizedPlayers() do
	task.spawn(playerAuthorized, player)
end

networkTrafficRemote.OnServerEvent:Connect(function(player, messageContent: { any } | string)
	if not Authorization:IsPlayerAuthorizedAsync(player) then
		player:Kick("Attempted to perform unauthorized action.")
		return
	end

	if messageContent == "_ready_" then
		readyTargets[player] = true
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

		invokeTopic(topic, player, table.unpack(params))
	end
end)

RunService.Heartbeat:Connect(function()
	for player, playerData in outgoingMessageQueue do
		if not readyTargets[player] or #playerData <= 0 then
			continue
		end

		local messageQueue = playerData
		outgoingMessageQueue[player] = {}

		networkTrafficRemote:FireClient(player, messageQueue)
	end
end)

local Networking = {}

function Networking.SendMessageToPlayer(self, player: Player, topic: string, ...)
	assert(self == Networking, "Expected ':' not '.' calling member function SendMessageToPlayer")

	if not outgoingMessageQueue[player] then
		return
	end

	table.insert(outgoingMessageQueue[player], {
		topic,
		{ ... },
	})
end

function Networking.SendMessage(self, topic: string, ...)
	assert(self == Networking, "Expected ':' not '.' calling member function SendMessage")

	for player in outgoingMessageQueue do
		Networking:SendMessageToPlayer(player, topic, ...)
	end
end

function Networking.SubscribeToTopic(self, topic: string, callback: (...any) -> ()): ()
	assert(self == Networking, "Expected ':' not '.' calling member function SubscribeToTopic")

	if not topicCallbacks[topic] then
		topicCallbacks[topic] = {}
	end

	local topicCallbacks = topicCallbacks[topic]

	table.insert(topicCallbacks, callback)
	return function()
		local callbackIndex = table.find(topicCallbacks, callback)

		if callbackIndex then
			table.remove(topicCallbacks, callbackIndex)
		end
	end
end

return Networking
