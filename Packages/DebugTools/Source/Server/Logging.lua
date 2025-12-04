local EncodingService = game:GetService("EncodingService")
local HttpService = game:GetService("HttpService")

local Networking = require(script.Parent.Networking)

local pendingPlayerLogs = {}

Networking:SubscribeToTopic("send_log", function(player, message)
	if typeof(message) ~= "buffer" then
		return
	end

	if pendingPlayerLogs[player] then
		Networking:SendMessageToPlayer(
			player,
			"send_log_result",
			nil,
			pendingPlayerLogs[player] - DateTime.now().UnixTimestamp
		)
		return
	end

	pendingPlayerLogs[player] = DateTime.now().UnixTimestamp + 30

	local decompressedMessage =
		buffer.tostring(EncodingService:DecompressBuffer(message, Enum.CompressionAlgorithm.Zstd))

	local success, result = pcall(
		HttpService.PostAsync,
		HttpService,
		"https://dpaste.com/api/v2/",
		`content={HttpService:UrlEncode(decompressedMessage)}&expiry_days=1&title={HttpService:UrlEncode(
			`Debug Tools Output {DateTime.now().UnixTimestamp}`
		)}`,
		Enum.HttpContentType.ApplicationUrlEncoded,
		false
	)

	Networking:SendMessageToPlayer(player, "send_log_result", success, result)

	task.delay(30, function()
		pendingPlayerLogs[player] = nil
	end)
end)

return nil
