local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EmoticonReporter = require(ServerScriptService.Reporters.EmoticonReporter)
local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

TestEz.TestBootstrap:run({
	ServerScriptService.Modules,
	-- ReplicatedStorage.Packages.ToolName
}, EmoticonReporter)
