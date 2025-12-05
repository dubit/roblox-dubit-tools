--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DebugToolRootPath = script.Parent.Parent
local SharedPath = DebugToolRootPath.Shared

local Constants = require(SharedPath.Constants)

local Authorization = require(script.Parent.Authorization)

local Networking = {}
Networking.internal = {
	TopicCallbacks = {},
	NetworkTrafficRemote = nil :: RemoteEvent?,
	MessageQueue = {} :: {
		[number]: { unknown },
	},
}
Networking.interface = {}

function Networking.internal.invokeTopic(topic: string, ...)
	local topicCallbacks = Networking.internal.TopicCallbacks[topic]

	if not topicCallbacks then
		return
	end

	for _, callback in topicCallbacks do
		callback(...)
	end
end

function Networking.interface:SendMessage(topic: string, ...)
	table.insert(Networking.internal.MessageQueue, {
		topic,
		{ ... },
	})
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

local networkTrafficRemote = ReplicatedStorage:WaitForChild(Constants.NETWORK_TRAFFIC_REMOTE_NAME) :: RemoteEvent

networkTrafficRemote.OnClientEvent:Connect(function(messageContent: { any })
	for _, message in messageContent do
		local topic: string = message[1]
		local params: { any } = message[2]

		if not topic or not params then
			continue
		end

		Networking.internal.invokeTopic(topic, table.unpack(params))
	end
end)

Networking.internal.NetworkTrafficRemote = networkTrafficRemote

RunService.Heartbeat:Connect(function()
	if #Networking.internal.MessageQueue <= 0 then
		return
	end

	local messagesToSend = Networking.internal.MessageQueue
	Networking.internal.MessageQueue = {}

	Networking.internal.NetworkTrafficRemote:FireServer(messagesToSend)
end)

Authorization.StatusChanged:Connect(function(authorized)
	if authorized then
		networkTrafficRemote:FireServer("_ready_")
	end
end)

if Authorization:IsLocalPlayerAuthorized() then
	networkTrafficRemote:FireServer("_ready_")
end

return Networking.interface
