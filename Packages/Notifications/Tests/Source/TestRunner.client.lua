local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EmoticonReporter = require(ReplicatedStorage.Tests.Source.Reporters.EmoticonReporter)
local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

TestEz.TestBootstrap:run({
	ReplicatedStorage.Tests.Source.Modules,
	-- ReplicatedStorage.Packages.Notifications,
}, EmoticonReporter)
