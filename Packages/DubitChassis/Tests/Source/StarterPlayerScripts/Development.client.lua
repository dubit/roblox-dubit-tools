local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Components must be required before DubitChassis
for _, component in script.Parent:WaitForChild("Components"):GetChildren() do
	require(component)
end

local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

DubitChassis.OnChassisRegistered:Wait()
