local Players = game:GetService("Players")

local Action = require(script.Parent.Parent.Parent.Parent.Shared.Action)
local Authorization = require(script.Parent.Parent.Parent.Parent.Server.Authorization)

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

Action.new(
	"Default/Lock Server",
	"Lock the current server so that only debug user players can join",
	function(locked: boolean)
		serverLockEnabled = locked

		validatePlayers()
		return
	end,
	{
		{
			Type = "boolean",
			Name = "Locked",
			Default = false,
		},
	}
)

return {}
