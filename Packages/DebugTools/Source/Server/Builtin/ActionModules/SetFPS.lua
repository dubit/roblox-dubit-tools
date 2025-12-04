--!strict
local RunService = game:GetService("RunService")

local Action = require(script.Parent.Parent.Parent.Parent.Shared.Action)

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

Action.new("Default/Set Server FPS", "Set the server FPS (60 is the default FPS)", function(fps: number)
	targetFPS = math.max(1, fps)
	return
end, {
	{
		Type = "number",
		Name = "FPS",
		Default = 60,
	},
})

return {}
