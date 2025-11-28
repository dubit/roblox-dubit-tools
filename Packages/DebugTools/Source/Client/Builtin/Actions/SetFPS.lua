--!strict

local RunService = game:GetService("RunService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Action = require(DebugToolRootPath.Parent.Shared.Action)

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

Action.new("Default/Set Client FPS", "Set the player FPS (see settings for your default FPS)", function(fps: number)
	targetFPS = math.max(1, fps)

	return
end, {
	{
		Type = "number",
		Name = "FPS",
		Default = 60,
	},
})

return nil
