local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Components must be required before DubitChassis
for _, component in ServerScriptService.Components:GetChildren() do
	require(component)
end

local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

DubitChassis.OnChassisRegistered:Wait()
