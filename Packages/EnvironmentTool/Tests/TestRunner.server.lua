local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEz = require(ReplicatedStorage.DevPackages.TestEz)

print("[TestRunner]: TestEZ Running, please be patient if you're running tests on a LIVE environment.")

TestEz.TestBootstrap:run({
	ReplicatedStorage.Packages,
})
