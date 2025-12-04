local HttpService = game:GetService("HttpService")
local EncodingService = game:GetService("EncodingService")

local ServerDebugTools = {}

require(script.Builtin.Info)
require(script.Builtin.Console)
require(script.Builtin.Actions)

require(script.Builtin.ActionModules.SetFPS)
require(script.Builtin.ActionModules.LockServer)

ServerDebugTools.Action = require(script.Parent.Shared.Action)

ServerDebugTools.Networking = require(script.Networking)
ServerDebugTools.Authorization = require(script.Authorization)

-- Output logging

local pendingPlayerLogs = {}
ServerDebugTools.Networking:SubscribeToTopic("send_log", function(player, message)
	if typeof(message) ~= "buffer" then
		return
	end

	if pendingPlayerLogs[player] then
		ServerDebugTools.Networking:SendMessageToPlayer(
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

	ServerDebugTools.Networking:SendMessageToPlayer(player, "send_log_result", success, result)

	task.delay(30, function()
		pendingPlayerLogs[player] = nil
	end)
end)

return ServerDebugTools
