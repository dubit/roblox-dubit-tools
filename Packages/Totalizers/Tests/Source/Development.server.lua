--[[
	Development script - this script is not part of the package, and should only be used for testing the functionality
	of the package within the Roblox engine.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Totalizers = require(ReplicatedStorage.Packages.Totalizers)

Totalizers.Totalizersynced:Connect(function(...)
	print(...)
end)

Totalizers.Reset("Example")

while true do
	Totalizers.Increment("Example")

	task.wait(1)
end
