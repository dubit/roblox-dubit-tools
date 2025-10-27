--!strict

--[[
	Responsible for the Default WalkSpeed action in the debug tools package. This action will allow developers/QA to
	change their characters walkspeed on the fly, in any of the games we develop.
]]

local Players = game:GetService("Players")

local DebugToolRootPath = script.Parent.Parent.Parent

local Action = require(DebugToolRootPath.Parent.Shared.Action)

local humanoid
local targetWalkspeed

local function onCharacterAdded(character: Model)
	humanoid = character:WaitForChild("Humanoid") :: Humanoid

	if targetWalkspeed then
		humanoid.WalkSpeed = targetWalkspeed
	end
end

Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

Action.new("Default/Set Walkspeed", "Sets the walkspeed of the current player", function(walkspeed: number)
	if humanoid then
		humanoid.WalkSpeed = walkspeed
	end

	targetWalkspeed = walkspeed

	return
end, {
	{
		Type = "number",
		Name = "Walkspeed",
		Default = 40,
	},
})

return nil
