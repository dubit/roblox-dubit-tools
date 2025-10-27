--!strict
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")

local Module = require(script.Parent.Parent.Module)
local Networking = require(script.Parent.Parent.Networking)

local MESSAGE_HISTORY_LENGTH: number = 100

local ConsoleModule = Module.new("Console")
local Internal = {
	MessagesHistory = {},
}

function Internal.sendMessagesHistory(player: Player)
	for _, messageData in Internal.MessagesHistory do
		Networking:SendMessageToPlayer(
			player,
			"console_messages",
			messageData.MessageType,
			messageData.Message,
			messageData.Timestamp
		)
	end
end

function ConsoleModule:Init()
	-- In studio all server and client side errors get printed within LogService.MessageOut
	-- on client side either way, nice...
	if RunService:IsStudio() then
		return
	end

	LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
		local timestamp: number = math.floor(os.clock() * 1000) / 1000

		Networking:SendMessage("console_messages", messageType, message, timestamp)

		table.insert(Internal.MessagesHistory, {
			Message = message,
			MessageType = messageType,
			Timestamp = timestamp,
		})

		if #Internal.MessagesHistory > MESSAGE_HISTORY_LENGTH then
			table.remove(Internal.MessagesHistory, 1)
		end
	end)

	for _, player: Player in Networking:GetNetworkTargets() do
		Internal.sendMessagesHistory(player)
	end

	Networking.NetworkTargetAdded:Connect(function(player: Player)
		Internal.sendMessagesHistory(player)
	end)
end

return ConsoleModule
