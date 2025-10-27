--[[
	Development script - this script is not part of the package, and should only be used for testing the functionality
	of the package within the Roblox engine.
]]

-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- local Engagements = require(ReplicatedStorage.Packages.Engagements)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Size = UDim2.fromScale(0.5, 0.5)

local textButton = Instance.new("TextButton")
textButton.Name = "TextButton"
textButton.BackgroundColor3 = Color3.fromRGB(138, 138, 138)
textButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
textButton.BorderSizePixel = 0
textButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
textButton.Size = UDim2.fromScale(0.5, 0.5)
textButton.TextColor3 = Color3.fromRGB(0, 0, 0)
textButton.TextSize = 14
textButton.Parent = frame

frame.Parent = screenGui

local player = Players:FindFirstAncestorOfClass("Player") or Players.PlayerAdded:Wait()

screenGui:SetAttribute("DubitEngagement_Identifier", "Test Gui")
screenGui:AddTag("DubitEngagement_Gui")
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Engagements.ViewedGui:Connect(function(...)
-- 	print("ViewedGui", ...)
-- end)

-- Engagements.InteractedWithGui:Connect(function(...)
-- 	print("InteractedWithGui", ...)
-- end)
