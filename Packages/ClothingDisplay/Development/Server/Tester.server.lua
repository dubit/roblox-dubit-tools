local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClothingDisplay = require(ReplicatedStorage.Packages.ClothingDisplay)
ClothingDisplay.ItemDetails.PreloadAssetDetails(11103863030)
ClothingDisplay.ItemDetails.PreloadAssetDetails(13895671430)
-- ClothingDisplay.ItemDetails.PreloadAssetDetails(6825096846)
ClothingDisplay.ItemDetails.PreloadBundleDetails(311)
task.delay(5, function()
	local player = Players:GetPlayers()[1]
	warn(
		`{player.DisplayName} {ClothingDisplay.ItemDetails.IsBundleOwned(player, 573) and "owns" or "doesn't own"} bundle 573`
	)
end)

local mannequinHead = ClothingDisplay.MannequinHead.new(13821486499)
mannequinHead:PivotTo(CFrame.new(Vector3.new(15.00, 5.00, 0.00)))
-- mannequinHead:SetBodyColor(Color3.fromRGB(234, 184, 146))
mannequinHead:AddAccessory(11103863030)
-- mannequinHead:AddAccessory(12362054670)
-- mannequinHead:AddAccessory(15496251679)
-- mannequinHead:AddAccessory(10787157603)
-- mannequinHead:AddAccessory(12278632203)
-- mannequinHead:AddAccessory(3963874672)
mannequinHead.Instance.Parent = workspace

task.delay(5, function()
	mannequinHead:RemoveAccessory(11103863030)
end)

local rigMannequin = ClothingDisplay.Mannequin.new(Enum.HumanoidRigType.R15)
rigMannequin.Instance.Parent = workspace
-- rigMannequin:ApplyOutfit(24121378572)
rigMannequin:SetBodyColor(Color3.fromRGB(100, 100, 100))
rigMannequin:AddAccessory(15496251679) -- hat
-- rigMannequin:AddAccessory(3963871432) -- body part
rigMannequin:AddAccessory(9112474888) -- shirt white
rigMannequin:AddAccessory(7192553841) -- jacket
rigMannequin:AddAccessory(15022837535, true) -- space shirt

rigMannequin:AddAccessory(13899135964) -- bunny hat
rigMannequin:AddAccessory(12583828426) -- pink cat ears
rigMannequin:AddAccessory(10193400881) -- fragmented hat
rigMannequin:AddAccessory(11307813259) -- elton hat

rigMannequin:RemoveAccessory(7192553841) -- jacket
rigMannequin:RemoveAccessory(15022837535) -- space shirt

local outfitMannequin = ClothingDisplay.Mannequin.fromOutfitID(24121378572)
outfitMannequin.Instance.Parent = workspace
outfitMannequin:AddAccessory(15496251679)

local accessories = {
	13899135964,
	12583828426,
	10193400881,
	11307813259,
	15022837535,
}

local accessory = ClothingDisplay.Hanger.new(7192553841)
accessory.Instance.Parent = workspace
accessory:PivotTo(CFrame.new(Vector3.new(0.00, 10.00, 0.00)))

for i, accessoryID in accessories do
	accessory:ChangeTo(accessoryID)
	accessory:ScaleTo(i)
	task.wait(5)
end
