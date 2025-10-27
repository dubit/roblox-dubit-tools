local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClothingDisplay = require(ReplicatedStorage.Packages.ClothingDisplay)
local Outfit = ClothingDisplay.Outfit

local outfit = Outfit.fromUserId(Players.LocalPlayer.UserId)

task.delay(3.00, function()
	local playerAvatarClone = Players:CreateHumanoidModelFromUserId(Players.LocalPlayer.UserId)
	playerAvatarClone.Parent = workspace

	playerAvatarClone:PivotTo(Players.LocalPlayer.Character:GetPivot())

	outfit:LinkHumanoid(playerAvatarClone:FindFirstChildOfClass("Humanoid"))
	-- outfit:AddAsset(7192553841)
	-- outfit:AddAsset(13895671430)

	-- graphic
	-- outfit:AddAsset(382538503)
	outfit:AddAsset(16015862250) -- shirt / texture
	outfit:AddAsset(15048322173) -- shirt / accessory
	-- outfit:AddAsset(5830814889)
	-- 13895671430

	-- oliver torso
	-- outfit:AddAsset(3963871432)
	-- outfit:RemoveAsset(3963871432)

	-- fry bundle 671
	-- outfit:AddBundle(311, { Enum.AssetType.LeftLeg, Enum.AssetType.RightLeg })
	outfit:AddBundle(671, { Enum.AssetType.LeftLeg, Enum.AssetType.RightLeg })
	task.wait(1.00)
	outfit:RemoveBundle(671, { Enum.AssetType.LeftArm, Enum.AssetType.RightLeg })

	-- local outfitChanger = Outfit.new()
	-- outfitChanger:LinkHumanoid(playerAvatarClone:FindFirstChildOfClass("Humanoid"), false)
	-- outfitChanger:AddAsset(9112474888)
end)

print(ClothingDisplay.ItemDetails.GetAssetDetails(15507312553))
print(ClothingDisplay.ItemDetails.GetAssetDetails(16783486874))
print(ClothingDisplay.ItemDetails.GetAssetDetails(2830454962))

print(ClothingDisplay.ItemDetails.IsAssetOwned(Players.LocalPlayer, 15507312553))
print(ClothingDisplay.ItemDetails.IsAssetOwned(Players.LocalPlayer, 16783486874))

print(ClothingDisplay.ItemDetails.IsBundleOwned(Players.LocalPlayer, 311))
print(ClothingDisplay.ItemDetails.IsBundleOwned(Players.LocalPlayer, 573))
print(ClothingDisplay.ItemDetails.IsBundleOwned(Players.LocalPlayer, 573))
