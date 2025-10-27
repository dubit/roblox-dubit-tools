local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local DubitUtils = require(ReplicatedStorage.Packages.DubitUtils)

--Instance
print("\n CLIENT INSTANCE UTILITY TESTS \n")
if workspace:FindFirstChild("GeneralTestModel") then
	print("Setting transparency of test model to 0.5")
	DubitUtils.Instance.setDescendantTransparency(workspace.GeneralTestModel, 0.5)
end

--Character
Players.LocalPlayer.CharacterAdded:Connect(function(character)
	print("\n CLIENT CHARACTER UTILITY TESTS \n")
	local clonedCharacter = DubitUtils.Character.cloneCharacter(character, true)
	clonedCharacter.Parent = workspace
	print("cloneCharacter Test: ", clonedCharacter)
end)
