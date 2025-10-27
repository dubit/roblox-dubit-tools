local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local localPlayerScripts = localPlayer.PlayerScripts

local System = require(ReplicatedStorage.Packages.System)

System:AddSystemsFolder(localPlayerScripts.SystemExamples)
System:Start()
