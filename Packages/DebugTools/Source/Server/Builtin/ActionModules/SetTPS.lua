--!strict
local RunService = game:GetService("RunService")

local Action = require(script.Parent.Parent.Parent.Parent.Shared.Action)

local targetTPS = math.huge

task.defer(function()
	while true do
		local tick0 = tick()

		RunService.Heartbeat:Wait()

		-- selene:allow(empty_loop)
		repeat
		until (tick0 + 1 / targetTPS) < tick()
	end
end)

Action.new("Default/Set Server TPS", "Set the server TPS (60 is the default TPS)", function(tps: number)
	targetTPS = tps

	return
end, {
	{
		Type = "number",
		Name = "TPS",
		Default = 60,
	},
})

return {}
