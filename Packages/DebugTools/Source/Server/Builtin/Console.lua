local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")

local Networking = require(script.Parent.Parent.Networking)
local Authorization = require(script.Parent.Parent.Authorization)

local MESSAGE_HISTORY_LENGTH = 100

local outputLog: {
	{
		Message: string,
		MessageType: Enum.MessageType,
		Timestamp: number,
	}
} = {}

local function sendMessagesHistory(player: Player)
	for _, messageData in outputLog do
		Networking:SendMessageToPlayer(
			player,
			"console_messages",
			messageData.MessageType,
			messageData.Message,
			messageData.Timestamp
		)
	end
end

-- In studio all server and client side errors get printed within LogService.MessageOut on client side either way
if not RunService:IsStudio() then
	LogService.MessageOut:Connect(function(message, messageType)
		local timestamp = math.floor(os.clock() * 1000) / 1000

		Networking:SendMessage("console_messages", messageType, message, timestamp)

		table.insert(outputLog, {
			Message = message,
			MessageType = messageType,
			Timestamp = timestamp,
		})

		if #outputLog > MESSAGE_HISTORY_LENGTH then
			table.remove(outputLog, 1)
		end
	end)

	Authorization.PlayerAuthorized:Connect(sendMessagesHistory)
	for _, player in Authorization:GetAuthorizedPlayers() do
		task.spawn(sendMessagesHistory, player)
	end
end

return nil
