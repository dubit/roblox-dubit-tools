local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Networking = require(script.Parent.Parent.Networking)

local isQueryingServerInfo = false
local serverInfo

local function queryServerInfo()
	while isQueryingServerInfo do
		task.wait()
	end

	if serverInfo then
		return serverInfo
	end

	if RunService:IsStudio() then
		return {
			Ip = "::ffff:127.0.0.1",
			Location = "Unknown",
		}
	else
		isQueryingServerInfo = true

		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = "https://ipconfig.io/json",
				Method = "GET",
			})
		end)

		local httpData = success and HttpService:JSONDecode(response)

		if not success then
			return {
				Ip = "Unknown",
				Location = "Unknown",
			}
		end

		serverInfo = {
			Ip = httpData.ip,
			Location = `{httpData.region_code or "Unknown"}, {httpData.country_iso or "Unknown"}`,
		}

		isQueryingServerInfo = false

		return serverInfo
	end
end

local function sendServerInfo(player: Player)
	local info = queryServerInfo()

	Networking:SendMessageToPlayer(player, "server_info", info.Ip, info.Location)
end

Networking.NetworkTargetAdded:Connect(sendServerInfo)
for _, player in Networking:GetNetworkTargets() do
	task.spawn(sendServerInfo, player)
end

return nil
