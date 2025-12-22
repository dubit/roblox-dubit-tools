local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugToolRootPath = script.Parent.Parent
local SharedPath = DebugToolRootPath.Shared

local Constants = require(SharedPath.Constants)

local Authorization = require(script.Parent.Authorization)

local outgoingMessageQueue = {}
local topicCallbacks = {}

local networkTrafficRemote = ReplicatedStorage:WaitForChild(Constants.NETWORK_TRAFFIC_REMOTE_NAME) :: RemoteEvent

local function invokeTopic(topic: string, ...)
	local callbacks = topicCallbacks[topic]

	if not callbacks then
		return
	end

	for _, callback in callbacks do
		callback(...)
	end
end

networkTrafficRemote.OnClientEvent:Connect(function(messageContent)
	for _, message in messageContent do
		local topic: string = message[1]
		local params: { any } = message[2]

		if not topic or not params then
			continue
		end

		invokeTopic(topic, table.unpack(params))
	end
end)

RunService.Heartbeat:Connect(function()
	if #outgoingMessageQueue <= 0 then
		return
	end

	local messagesToSend = outgoingMessageQueue
	outgoingMessageQueue = {}

	networkTrafficRemote:FireServer(messagesToSend)
end)

Authorization.StatusChanged:Connect(function(authorized)
	if authorized then
		networkTrafficRemote:FireServer("_ready_")
	end
end)

if Authorization:IsLocalPlayerAuthorized() then
	networkTrafficRemote:FireServer("_ready_")
end

local Networking = {}

function Networking.SendMessage(self, topic: string, ...)
	assert(self == Networking, "Expected ':' not '.' calling member function SendMessage")

	table.insert(outgoingMessageQueue, {
		topic,
		{ ... },
	})
end

function Networking.SubscribeToTopic(self, topic: string, callback: (...any) -> ()): ()
	assert(self == Networking, "Expected ':' not '.' calling member function SubscribeToTopic")

	if not topicCallbacks[topic] then
		topicCallbacks[topic] = {}
	end

	local callbacks = topicCallbacks[topic]

	table.insert(callbacks, callback)
	return function()
		local callbackIndex = table.find(callbacks, callback)

		if callbackIndex then
			table.remove(callbacks, callbackIndex)
		end
	end
end

return Networking
