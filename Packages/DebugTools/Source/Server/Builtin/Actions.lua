--!strict
local Players = game:GetService("Players")
local Networking = require(script.Parent.Parent.Networking)
local Authorization = require(script.Parent.Parent.Authorization)

local Action = require(script.Parent.Parent.Parent.Shared.Action)

local actionListeners = {}

local function sendActionsList(player: Player)
	local playerData = actionListeners[player]
	if not playerData then
		playerData = {
			Listening = true,
			SentActions = {},
		}
		actionListeners[player] = playerData
	end

	local actionsToSend = {}

	for _, actionDefiniton in Action:GetAll() do
		if playerData.SentActions[actionDefiniton.Name] then
			continue
		end

		playerData.SentActions[actionDefiniton.Name] = true

		table.insert(actionsToSend, actionDefiniton)
	end

	if #actionsToSend == 0 then
		return
	end

	Networking:SendMessageToPlayer(player, "actions_update", actionsToSend)
end

Action.ActionAdded:Connect(function(actionName: string)
	local actionDefinition = Action:GetDefinition(actionName)

	for player, playerData in actionListeners do
		if not playerData.Listening then
			continue
		end

		playerData.SentActions[actionName] = true

		Networking:SendMessageToPlayer(player, "actions_update", { actionDefinition })
	end
end)

Action.ActionRemoved:Connect(function(actionName: string)
	for player, playerData in actionListeners do
		if not playerData.Listening then
			continue
		end

		playerData.SentActions[actionName] = nil

		Networking:SendMessageToPlayer(player, "actions_remove", actionName)
	end
end)

Networking:SubscribeToTopic("actions_listening", function(player: Player, isListening: boolean)
	if isListening then
		sendActionsList(player)
	else
		actionListeners[player].Listening = false
	end
end)

Networking:SubscribeToTopic("actions_execute", function(_, actionName: string, arguments: { any }?)
	Action:Execute(actionName, arguments)
end)

Authorization.PlayerAuthorizationLost:Connect(function(player)
	actionListeners[player].Listening = false
end)

Players.PlayerRemoving:Connect(function(player)
	actionListeners[player] = nil
end)

return nil
