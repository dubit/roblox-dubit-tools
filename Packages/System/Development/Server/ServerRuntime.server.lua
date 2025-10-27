local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local System = require(ReplicatedStorage.Packages.System)

System:AddSystemsFolder(ServerScriptService.SystemExamples)
System:Start()
