local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EmoticonReporter = require(ReplicatedStorage.DevPackages.EmoticonReporter)
local TestEz = require(ReplicatedStorage.DevPackages.TestEz)
local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

-- Initialize component to track component object class and lifecycle methods
DubitChassis.Component.new({
	Tag = "Chassis",
})

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

local Reporter = EmoticonReporter.new()

DubitChassis.Reporter:SetLogLevel(5)

TestEz.TestBootstrap:run({
	script.Parent:WaitForChild("Modules"),
	ReplicatedStorage.Packages.DubitChassis,
}, Reporter)

Reporter:Print()
