local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

local EmoticonReporter = require(ReplicatedStorage.DevPackages.EmoticonReporter)
local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

local Reporter = EmoticonReporter.new()

if script.Parent.Development.Enabled then
	return
end

DubitStore:SetOnlineState(false)
DubitStore:SetDevelopmentChannel("Test")

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

TestEz.TestBootstrap:run({
	ServerScriptService.Modules,
	ReplicatedStorage.Packages.DubitStore,
}, Reporter)

Reporter:Print()
