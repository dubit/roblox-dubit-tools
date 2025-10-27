--!strict

--[[
	Responsible for the Noclip functionality - allowing Developers/QA to clip through objects in the world. This
	can be useful for getting into awkward places, or getting out of awkward places.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Action = require(DebugToolRootPath.Parent.Shared.Action)

local connection
local enabled = false

local function onRender()
	local character = Players.LocalPlayer.Character

	if not character then
		return
	end

	for _, object in character:GetChildren() do
		if object:IsA("BasePart") then
			object.CanCollide = false
		end
	end
end

local function enable()
	connection = RunService.PreSimulation:Connect(function()
		if not enabled then
			return
		end

		onRender()
	end)
end

local function disable()
	local character = Players.LocalPlayer.Character

	if connection then
		connection:Disconnect()

		connection = nil
	end

	if not character then
		return
	end

	for _, object in character:GetChildren() do
		if object:IsA("BasePart") then
			object.CanCollide = true
		end
	end
end

Action.new("Default/Set Noclip", "Enables/Disables clipping for the current player", function(isEnabled: boolean)
	enabled = isEnabled

	if isEnabled then
		enable()
	else
		disable()
	end

	return
end, {
	{
		Type = "boolean",
		Name = "Enabled",
		Default = true,
	},
})

return nil
