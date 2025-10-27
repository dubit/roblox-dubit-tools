local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EmoticonReporter = require(ReplicatedStorage.DevPackages.EmoticonReporter)
local TestEz = require(ReplicatedStorage.DevPackages.TestEz)
local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

local OnGeneratePrototype = ReplicatedStorage.Assets.Remotes.OnGeneratePrototype
local OnRemovePrototype = ReplicatedStorage.Assets.Remotes.OnRemovePrototype

-- Initialize component to track component object class and lifecycle methods
DubitChassis.Component.new({
	Tag = "Chassis",
})

OnGeneratePrototype.OnServerInvoke = function(_): Model
	local chassis = ReplicatedStorage.Assets.Kart:Clone()
	chassis.Parent = workspace

	DubitChassis.OnChassisRegistered:Wait()

	return chassis
end

OnRemovePrototype.OnServerEvent:Connect(function(_: Player, chassis: Model)
	DubitChassis:FromInstance(chassis):Stop()
end)

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

local Reporter = EmoticonReporter.new()

DubitChassis.Reporter:SetLogLevel(4)

TestEz.TestBootstrap:run({
	ServerScriptService.Modules,
	ReplicatedStorage.Packages.DubitChassis,
}, Reporter)

Reporter:Print()
