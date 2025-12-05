local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local EncodingService = game:GetService("EncodingService")

local Networking = require(script.Networking)
local Authorization = require(script.Authorization)

require(script.Builtin.Info)
require(script.Builtin.Console)
require(script.Builtin.Actions)

-- Output logging

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

Players.PlayerRemoving:Connect(function(player)
	pendingPlayerLogs[player] = nil
end)

-- Server FPS limiting
local targetFPS = math.huge

task.defer(function()
	while true do
		local tick0 = tick()

		RunService.Heartbeat:Wait()

		-- selene:allow(empty_loop)
		repeat
		until (tick0 + 1 / targetFPS) < tick()
	end
end)

Networking:SubscribeToTopic("fps_limiter", function(_, newFPSLimit)
	targetFPS = math.max(10, newFPSLimit)
end)

-- Server locking
local serverLockEnabled = false

local function validatePlayers()
	if not serverLockEnabled then
		return
	end

	for _, player in Players:GetPlayers() do
		task.spawn(function()
			if not Authorization:IsPlayerAuthorized(player) then
				player:Kick(`This server is currently locked; only users who have access to debug tools can access!`)
			end
		end)
	end
end

Players.PlayerAdded:Connect(function()
	task.defer(validatePlayers)
end)

Networking:SubscribeToTopic("server_lock", function(_, enabled)
	serverLockEnabled = enabled

	if enabled then
		validatePlayers()
	end
end)

return {
	Networking = Networking,
	Authorization = Authorization,
	Action = require(script.Parent.Shared.Action),
}
