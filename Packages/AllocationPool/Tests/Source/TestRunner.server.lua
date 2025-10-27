local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EmoticonReporter = require(ReplicatedStorage.DevPackages.EmoticonReporter)
local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

local Reporter = EmoticonReporter.new()

TestEz.TestBootstrap:run({
	ServerScriptService.Modules,
	ReplicatedStorage.Packages.AllocationPool,
}, Reporter)

Reporter:Print()
