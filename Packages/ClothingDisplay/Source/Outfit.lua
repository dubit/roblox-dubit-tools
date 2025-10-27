--!strict

--[=[
	@class ClothingDisplay.Outfit
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Signal = require(script.Parent.Parent.Signal)
local DubitUtils = require(script.Parent.Parent.DubitUtils)

local Utils = require(script.Parent.Utils)
local ItemDetails = require(script.Parent.ItemDetails)

local AVATAR_RULES_MAX_QUERIES = 5

export type OutfitInstance = {
	AddBundle: (self: OutfitInstance, bundleID: number, whitelist: { Enum.AssetType }?) -> boolean,
	RemoveBundle: (self: OutfitInstance, bundleID: number, whitelist: { Enum.AssetType }?) -> boolean,

	AddAsset: (self: OutfitInstance, assetID: number, assetType: Enum.AssetType?) -> boolean,
	RemoveAsset: (self: OutfitInstance, assetID: number, assetType: Enum.AssetType?) -> boolean,

	GetBodyParts: (self: OutfitInstance) -> BodyPartName,
	SetBodyPartsColor: (self: OutfitInstance, color: Color3) -> (),

	SetHumanoidScale: (self: OutfitInstance, scale: HumanoidScale, value: number) -> (),

	LinkHumanoid: (self: OutfitInstance, humanoid: Humanoid, keepOutfitDescription: boolean?) -> (),
	GetHumanoidDescription: (self: OutfitInstance) -> HumanoidDescription,
	GetRawHumanoidDescription: (self: OutfitInstance) -> RawHumanoidDescription,

	GetSnapshot: (self: OutfitInstance) -> Snapshot,

	ApplyHumanoidDescription: (self: OutfitInstance, humanoidDescription: HumanoidDescription) -> (),
	SetFallbackHumanoidDescription: (self: OutfitInstance, humanoidDescription: HumanoidDescription) -> (),

	Destroy: (self: OutfitInstance) -> (),

	OnHumanoidDescriptionChanged: typeof(Signal.new()),
}

export type Snapshot = {
	RigType: Enum.HumanoidRigType,

	RawHumanoidDescription: RawHumanoidDescription,

	UsedBundles: { number },
}

export type RawHumanoidDescription = {
	-- Body Colors
	HeadColor: Color3,
	LeftArmColor: Color3,
	LeftLegColor: Color3,
	RightArmColor: Color3,
	RightLegColor: Color3,
	TorsoColor: Color3,

	-- Body Parts
	Face: number,
	Head: number,
	LeftArm: number,
	LeftLeg: number,
	RightArm: number,
	RightLeg: number,
	Torso: number,

	-- Clothes
	GraphicTShirt: number,
	Pants: number,
	Shirt: number,

	-- Scale
	BodyTypeScale: number,
	DepthScale: number,
	HeadScale: number,
	HeightScale: number,
	ProportionScale: number,
	WidthScale: number,

	Accessories: { AccessoryData },
}

type AccessoryData = {
	AccessoryType: Enum.AccessoryType,
	AssetId: number,
	IsLayered: boolean,
	Order: number?,
	Puffiness: number?,
}

type PrivateOutfitData = {
	LinkedHumanoid: Humanoid?,
	HumanoidChildAddedConnection: RBXScriptConnection?,

	RigType: Enum.HumanoidRigType,

	RawHumanoidDescription: RawHumanoidDescription,
	FallbackHumanoidDescription: RawHumanoidDescription?,

	UsedBundles: { number },
}

type BodyPartName = "Face" | "Head" | "Torso" | "LeftArm" | "LeftLeg" | "RightArm" | "RightLeg"

type HumanoidScale = "BodyType" | "Head" | "Height" | "Proportion" | "Width"

local Outfit = {}
Outfit.rules = {
	Accessory = {} :: { [Enum.AccessoryType]: number },
}
Outfit.data = {} :: { [OutfitInstance]: PrivateOutfitData }
Outfit.utils = {}
Outfit.private = {
	AvatarRules = nil,
	UpdateQueue = {} :: { OutfitInstance },
	UpdateQueueLookup = {} :: { [OutfitInstance]: boolean },
}
Outfit.interface = {}
Outfit.prototype = {}

local function populateRules()
	local avatarRules
	local queryIndex = 0
	while not avatarRules do
		local success, data = pcall(AvatarEditorService.GetAvatarRules, AvatarEditorService)
		if success then
			avatarRules = data
		else
			queryIndex += 1
			if queryIndex >= AVATAR_RULES_MAX_QUERIES then
				break
			end
		end
		task.wait()
	end

	if not avatarRules then
		return
	end

	Outfit.private.AvatarRules = avatarRules

	for _, wearableAssetData in avatarRules.WearableAssetTypes do
		local accessory = Utils.AssetTypeIDToAccessoryType(wearableAssetData.Id)
		if accessory and accessory ~= Enum.AccessoryType.Unknown then
			Outfit.rules.Accessory[accessory] = wearableAssetData.MaxNumber
			continue
		end
	end
end

function Outfit.utils.createEmptyRawHumanoidDescription(): RawHumanoidDescription
	return {
		-- Body Colors
		HeadColor = Color3.fromRGB(0, 0, 0),
		LeftArmColor = Color3.fromRGB(0, 0, 0),
		LeftLegColor = Color3.fromRGB(0, 0, 0),
		RightArmColor = Color3.fromRGB(0, 0, 0),
		RightLegColor = Color3.fromRGB(0, 0, 0),
		TorsoColor = Color3.fromRGB(0, 0, 0),

		-- Body Parts
		Face = 0,
		Head = 0,
		LeftArm = 0,
		LeftLeg = 0,
		RightArm = 0,
		RightLeg = 0,
		Torso = 0,

		-- Clothes
		GraphicTShirt = 0,
		Pants = 0,
		Shirt = 0,

		-- Scale
		BodyTypeScale = 0.3,
		DepthScale = 1,
		HeadScale = 1,
		HeightScale = 1,
		ProportionScale = 1,
		WidthScale = 1,

		Accessories = {},
	}
end

function Outfit.utils.humanoidDescriptionToRaw(humanoidDescription: HumanoidDescription): RawHumanoidDescription
	return {
		-- Body Colors
		HeadColor = humanoidDescription.HeadColor,
		LeftArmColor = humanoidDescription.LeftArmColor,
		LeftLegColor = humanoidDescription.LeftLegColor,
		RightArmColor = humanoidDescription.RightArmColor,
		RightLegColor = humanoidDescription.RightLegColor,
		TorsoColor = humanoidDescription.TorsoColor,

		-- Body Parts
		Face = humanoidDescription.Face,
		Head = humanoidDescription.Head,
		LeftArm = humanoidDescription.LeftArm,
		LeftLeg = humanoidDescription.LeftLeg,
		RightArm = humanoidDescription.RightArm,
		RightLeg = humanoidDescription.RightLeg,
		Torso = humanoidDescription.Torso,

		-- Clothes
		GraphicTShirt = humanoidDescription.GraphicTShirt,
		Pants = humanoidDescription.Pants,
		Shirt = humanoidDescription.Shirt,

		-- Scale
		BodyTypeScale = humanoidDescription.BodyTypeScale,
		DepthScale = humanoidDescription.DepthScale,
		HeadScale = humanoidDescription.HeadScale,
		HeightScale = humanoidDescription.HeightScale,
		ProportionScale = humanoidDescription.ProportionScale,
		WidthScale = humanoidDescription.WidthScale,

		Accessories = humanoidDescription:GetAccessories(true),
	}
end

function Outfit.utils.fillHumanoidDescriptionWithRawData(
	humanoidDescription: HumanoidDescription,
	rawHumanoidDescription: RawHumanoidDescription
)
	humanoidDescription.HeadColor = rawHumanoidDescription.HeadColor
	humanoidDescription.LeftArmColor = rawHumanoidDescription.LeftArmColor
	humanoidDescription.LeftLegColor = rawHumanoidDescription.LeftLegColor
	humanoidDescription.RightArmColor = rawHumanoidDescription.RightArmColor
	humanoidDescription.RightLegColor = rawHumanoidDescription.RightLegColor
	humanoidDescription.TorsoColor = rawHumanoidDescription.TorsoColor

	humanoidDescription.Face = rawHumanoidDescription.Face
	humanoidDescription.Head = rawHumanoidDescription.Head
	humanoidDescription.LeftArm = rawHumanoidDescription.LeftArm
	humanoidDescription.LeftLeg = rawHumanoidDescription.LeftLeg
	humanoidDescription.RightArm = rawHumanoidDescription.RightArm
	humanoidDescription.RightLeg = rawHumanoidDescription.RightLeg
	humanoidDescription.Torso = rawHumanoidDescription.Torso

	humanoidDescription.GraphicTShirt = rawHumanoidDescription.GraphicTShirt
	humanoidDescription.Pants = rawHumanoidDescription.Pants
	humanoidDescription.Shirt = rawHumanoidDescription.Shirt

	humanoidDescription.BodyTypeScale = rawHumanoidDescription.BodyTypeScale
	humanoidDescription.DepthScale = rawHumanoidDescription.DepthScale
	humanoidDescription.HeadScale = rawHumanoidDescription.HeadScale
	humanoidDescription.HeightScale = rawHumanoidDescription.HeightScale
	humanoidDescription.ProportionScale = rawHumanoidDescription.ProportionScale
	humanoidDescription.WidthScale = rawHumanoidDescription.WidthScale

	humanoidDescription:SetAccessories(rawHumanoidDescription.Accessories, true)
end

function Outfit.utils.rawHumanoidDescriptionContainsAccessory(
	humanoidDescription: RawHumanoidDescription,
	accessoryID: number
): boolean
	for _, accessory in humanoidDescription.Accessories do
		if accessory.AssetId == accessoryID then
			return true
		end
	end

	return false
end

function Outfit.private.QueueDescriptionUpdate(self: OutfitPrivate, outfitInstance: OutfitInstance)
	if self.UpdateQueueLookup[outfitInstance] ~= nil then
		return
	end

	self.UpdateQueueLookup[outfitInstance] = true
	table.insert(self.UpdateQueue, outfitInstance)
end

function Outfit.private.DispatchDescriptionUpdates(self: OutfitPrivate)
	local outfitInstance = self.UpdateQueue[1]
	if not outfitInstance then
		return
	end

	self.UpdateQueueLookup[outfitInstance] = nil
	table.remove(self.UpdateQueue, 1)

	local outfitData = Outfit.data[outfitInstance]
	if not outfitData.LinkedHumanoid then
		return
	end

	local humanoidModel: Model? = outfitData.LinkedHumanoid.Parent :: Model?
	local humanoid: Humanoid = outfitData.LinkedHumanoid

	if humanoidModel then
		-- Roblox is weird when it comes to applying description and the character
		-- 	mesh downscales to match scale of 1 so we reset the scale and bring it back
		--	after the description is updated
		local previousScale: number = humanoidModel:GetScale()
		humanoidModel:ScaleTo(1.00)
		humanoid:ApplyDescription(outfitInstance:GetHumanoidDescription())
		humanoidModel:ScaleTo(previousScale)
	end
end

function Outfit.prototype.GetBodyParts(self: OutfitInstance): { [BodyPartName]: number }
	local data = Outfit.data[self]
	local rawDescription = data.RawHumanoidDescription

	return {
		Face = rawDescription.Face,
		Head = rawDescription.Head,
		LeftArm = rawDescription.LeftArm,
		LeftLeg = rawDescription.LeftLeg,
		RightArm = rawDescription.RightArm,
		RightLeg = rawDescription.RightLeg,
		Torso = rawDescription.Torso,
	}
end

function Outfit.prototype.SetHumanoidScale(self: OutfitInstance, scale: HumanoidScale, value: number)
	local data = Outfit.data[self]
	local avatarRules = Outfit.private.AvatarRules

	if scale == "BodyType" then
		data.RawHumanoidDescription.BodyTypeScale =
			math.clamp(value, avatarRules.Scales.BodyType.Min, avatarRules.Scales.BodyType.Max)
	elseif scale == "Head" then
		data.RawHumanoidDescription.HeadScale =
			math.clamp(value, avatarRules.Scales.Head.Min, avatarRules.Scales.Head.Max)
	elseif scale == "Height" then
		data.RawHumanoidDescription.HeightScale =
			math.clamp(value, avatarRules.Scales.Height.Min, avatarRules.Scales.Height.Max)
	elseif scale == "Proportion" then
		data.RawHumanoidDescription.ProportionScale =
			math.clamp(value, avatarRules.Scales.Proportion.Min, avatarRules.Scales.Proportion.Max)
	elseif scale == "Width" then
		data.RawHumanoidDescription.WidthScale =
			math.clamp(value, avatarRules.Scales.Width.Min, avatarRules.Scales.Width.Max)
	end

	if data.LinkedHumanoid then
		Outfit.private:QueueDescriptionUpdate(self)
	end

	self.OnHumanoidDescriptionChanged:Fire()
end

function Outfit.prototype.SetBodyPartsColor(self: OutfitInstance, color: Color3)
	local data = Outfit.data[self]

	data.RawHumanoidDescription.HeadColor = color
	data.RawHumanoidDescription.TorsoColor = color
	data.RawHumanoidDescription.LeftArmColor = color
	data.RawHumanoidDescription.LeftLegColor = color
	data.RawHumanoidDescription.RightArmColor = color
	data.RawHumanoidDescription.RightLegColor = color

	if data.LinkedHumanoid then
		Outfit.private:QueueDescriptionUpdate(self)
	end

	self.OnHumanoidDescriptionChanged:Fire()
end

function Outfit.prototype.AddBundle(self: OutfitInstance, bundleID: number, whitelist: { Enum.AssetType }?): boolean
	local data = Outfit.data[self]

	local bundleDetails = ItemDetails.GetBundleDetails(bundleID)
	if not bundleDetails then
		return false
	end

	table.insert(data.UsedBundles, bundleID)

	for _, bundledItem in bundleDetails.Items do
		if bundledItem.Type ~= "Asset" then
			continue
		end

		task.spawn(function()
			local assetDetails = ItemDetails.GetAssetDetails(bundledItem.Id)
			if not assetDetails then
				return
			end

			local assetType = assetDetails.AssetType

			if not assetType or (whitelist and assetType and not table.find(whitelist, assetType)) then
				return
			end

			self:AddAsset(bundledItem.Id)
		end)
	end

	self.OnHumanoidDescriptionChanged:Fire()

	return true
end

function Outfit.prototype.RemoveBundle(self: OutfitInstance, bundleID: number, whitelist: { Enum.AssetType }?)
	local data = Outfit.data[self]

	local bundleDetails = ItemDetails.GetBundleDetails(bundleID)
	if not bundleDetails then
		return false
	end

	local bundledItemIds = {}
	for _, bundledItem in bundleDetails.Items do
		if bundledItem.Type ~= "Asset" then
			continue
		end

		table.insert(bundledItemIds, bundledItem.Id)

		task.spawn(function()
			local assetDetails = ItemDetails.GetAssetDetails(bundledItem.Id)
			if not assetDetails then
				return
			end

			local assetType = assetDetails.AssetType

			if not assetType or (whitelist and not table.find(whitelist, assetType)) then
				return
			end

			self:RemoveAsset(bundledItem.Id)
		end)
	end

	local tableIndex = table.find(data.UsedBundles, bundleID)
	if not tableIndex then
		-- item still got removed so it succeed
		return true
	end

	-- it's possible that whitelist doesn't contain all items that were applied, so we need to check if bundle can be removed from UsedBundles
	local stillContainsBundleAssets = false
	for _, accessory in data.RawHumanoidDescription.Accessories do
		if table.find(bundledItemIds, accessory.AssetId) then
			stillContainsBundleAssets = true
			break
		end
	end

	if not stillContainsBundleAssets then
		for _, bodyPart in Enum.BodyPart:GetEnumItems() do
			local assetId = data.RawHumanoidDescription[bodyPart.Name]

			if table.find(bundledItemIds, assetId) then
				stillContainsBundleAssets = true
				break
			end
		end
	end

	if not stillContainsBundleAssets then
		table.remove(data.UsedBundles, tableIndex)
	end

	self.OnHumanoidDescriptionChanged:Fire()

	return true
end

function Outfit.prototype.AddAsset(self: OutfitInstance, assetID: number, assetType: Enum.AssetType?): boolean
	if not assetType then
		local productInfo = ItemDetails.GetAssetDetails(assetID)
		if not productInfo then
			warn(`Couldn't get productInfo for {assetID}`)
			return false
		end

		assetType = productInfo.AssetType
	end

	if not assetType then
		return false
	end

	local data = Outfit.data[self]

	local accessoryType = Utils.AssetTypeToAccessoryType(assetType)
	local bodyPartType = Utils.GetBodyPartFromAssetType(assetType)

	if assetType == Enum.AssetType.Shirt then
		data.RawHumanoidDescription.Shirt = assetID

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif assetType == Enum.AssetType.Pants then
		data.RawHumanoidDescription.Pants = assetID

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif assetType == Enum.AssetType.TShirt then
		data.RawHumanoidDescription.GraphicTShirt = assetID

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif assetType == Enum.AssetType.Face then
		data.RawHumanoidDescription.Face = assetID

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif bodyPartType then
		if not data.RawHumanoidDescription[bodyPartType.Name] then
			return false
		end

		data.RawHumanoidDescription[bodyPartType.Name] = assetID

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif accessoryType and accessoryType ~= Enum.AccessoryType.Unknown then
		if Outfit.utils.rawHumanoidDescriptionContainsAccessory(data.RawHumanoidDescription, assetID) then
			return false
		end

		local currentAccessories = data.RawHumanoidDescription.Accessories

		table.insert(currentAccessories, {
			AccessoryType = accessoryType,
			AssetId = assetID,
			IsLayered = true,
			Order = Utils.GetAccessoryOrder(accessoryType),
		})

		-- remove conflicting accessories
		local accessoriesToRemove = {}
		local accessoriesRemovedLookup = {}
		for i, accessory in currentAccessories do
			local accessoriesRemoved = accessoriesRemovedLookup[accessory.AccessoryType] or 0

			local accessoryTypeCount = Utils.GetAccessoryTypeCount(currentAccessories, accessory.AccessoryType)
				- accessoriesRemoved
			local accessoryLimit = Outfit.rules.Accessory[accessory.AccessoryType]
			local accessoryLimitReached = accessoryTypeCount > accessoryLimit
			local accessoryConflict = Utils.DoAccessoriesConflict(accessory.AccessoryType, accessoryType)

			if accessoryConflict or accessoryLimitReached then
				accessoriesRemovedLookup[accessory.AccessoryType] = (
					accessoriesRemovedLookup[accessory.AccessoryType] or 0
				) + 1

				table.insert(accessoriesToRemove, i)
			end
		end

		-- accessoriesToRemove array will always contain lower indexes first so we just do (index - accessoriesRemoved), because as we remove items the array shifts
		local indexOffset = 0
		for _, accessoryIndex in accessoriesToRemove do
			table.remove(currentAccessories, accessoryIndex - indexOffset)
			indexOffset += 1
		end

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()
		return true
	end

	return false
end

function Outfit.prototype.RemoveAsset(self: OutfitInstance, assetID: number, assetType: Enum.AssetType?): boolean
	if not assetType then
		local productInfo = ItemDetails.GetAssetDetails(assetID)
		if not productInfo then
			warn(`Couldn't get productInfo for {assetID}`)
			return false
		end

		assetType = productInfo.AssetType
	end

	if not assetType then
		return false
	end

	local data = Outfit.data[self]

	local accessoryType = Utils.AssetTypeToAccessoryType(assetType)
	local bodyPartType = Utils.GetBodyPartFromAssetType(assetType)

	if assetType == Enum.AssetType.Shirt then
		if data.FallbackHumanoidDescription then
			data.RawHumanoidDescription.Shirt = data.FallbackHumanoidDescription.Shirt
		else
			data.RawHumanoidDescription.Shirt = 0
		end

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif assetType == Enum.AssetType.Pants then
		if data.FallbackHumanoidDescription then
			data.RawHumanoidDescription.Pants = data.FallbackHumanoidDescription.Pants
		else
			data.RawHumanoidDescription.Pants = 0
		end

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif assetType == Enum.AssetType.TShirt then
		if data.FallbackHumanoidDescription then
			data.RawHumanoidDescription.GraphicTShirt = data.FallbackHumanoidDescription.GraphicTShirt
		else
			data.RawHumanoidDescription.GraphicTShirt = 0
		end

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif assetType == Enum.AssetType.Face then
		if data.FallbackHumanoidDescription then
			data.RawHumanoidDescription.Face = data.FallbackHumanoidDescription.Face
		else
			data.RawHumanoidDescription.Face = 0
		end

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return true
	elseif not accessoryType and bodyPartType then
		if not data.RawHumanoidDescription[bodyPartType.Name] then
			return false
		end

		if data.FallbackHumanoidDescription then
			data.RawHumanoidDescription[bodyPartType.Name] = data.FallbackHumanoidDescription[bodyPartType.Name]
		else
			data.RawHumanoidDescription[bodyPartType.Name] = 0
		end

		if data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()
	elseif accessoryType and accessoryType ~= Enum.AccessoryType.Unknown then
		local removed = false
		for accessoryIndex, accessory in data.RawHumanoidDescription.Accessories do
			if accessory.AssetId == assetID then
				table.remove(data.RawHumanoidDescription.Accessories, accessoryIndex)
				removed = true
				break
			end
		end

		-- TODO: if all conflicting accessories are removed and fallback contains any then re apply the fallback ones

		if removed and data.LinkedHumanoid then
			Outfit.private:QueueDescriptionUpdate(self)
		end

		self.OnHumanoidDescriptionChanged:Fire()

		return removed
	end

	return false
end

function Outfit.prototype.LinkHumanoid(self: OutfitInstance, humanoid: Humanoid, keepOutfitDescription: boolean?)
	local data = Outfit.data[self]

	if keepOutfitDescription == nil then
		keepOutfitDescription = true
	end

	if keepOutfitDescription then
		-- TODO: Do something about conflicting rig types?
		data.RigType = humanoid.RigType
		data.RawHumanoidDescription = Outfit.utils.humanoidDescriptionToRaw(humanoid:GetAppliedDescription())
		data.UsedBundles = {}
	else
		-- TODO: Handle changing rig type somehow? Couple of ideas below
		--  - Implement an R15 and R6 rig
		--  - Replace the current rig model with a new updated rig
		--  - Not support R6
		humanoid.RigType = data.RigType
		humanoid:ApplyDescription(self:GetHumanoidDescription())
	end

	data.LinkedHumanoid = humanoid

	if data.HumanoidChildAddedConnection then
		data.HumanoidChildAddedConnection:Disconnect()
	end

	data.HumanoidChildAddedConnection = humanoid.ChildAdded:Connect(function(instance: Instance)
		if not instance:IsA("HumanoidDescription") then
			return
		end

		local isDifferent = Utils.AreHumanoidDescriptionsDifferent(instance, self:GetHumanoidDescription())

		if isDifferent then
			data.RawHumanoidDescription = Outfit.utils.humanoidDescriptionToRaw(humanoid:GetAppliedDescription())

			-- TODO: Check if the accessories on the new description are from the bundles
			-- data.UsedBundles = {}
		end
	end)
end

function Outfit.prototype.GetHumanoidDescription(self: OutfitInstance): HumanoidDescription
	local data = Outfit.data[self]

	local humanoidDescription = Instance.new("HumanoidDescription")
	Outfit.utils.fillHumanoidDescriptionWithRawData(humanoidDescription, data.RawHumanoidDescription)

	return humanoidDescription
end

function Outfit.prototype.GetRawHumanoidDescription(self: OutfitInstance): RawHumanoidDescription
	local data = Outfit.data[self]

	return DubitUtils.Table.deepClone(data.RawHumanoidDescription)
end

function Outfit.prototype.GetSnapshot(self: OutfitInstance): Snapshot
	local data = Outfit.data[self]

	return {
		RigType = data.RigType,
		RawHumanoidDescription = DubitUtils.Table.deepClone(data.RawHumanoidDescription),
		UsedBundles = DubitUtils.Table.deepClone(data.UsedBundles),
	}
end

function Outfit.prototype.ApplyHumanoidDescription(self: OutfitInstance, humanoidDescription: HumanoidDescription)
	local data = Outfit.data[self]

	data.RawHumanoidDescription = Outfit.utils.humanoidDescriptionToRaw(humanoidDescription)

	if data.LinkedHumanoid then
		Outfit.private:QueueDescriptionUpdate(self)
	end

	self.OnHumanoidDescriptionChanged:Fire()
end

function Outfit.prototype.SetFallbackHumanoidDescription(self: OutfitInstance, humanoidDescription: HumanoidDescription)
	local data = Outfit.data[self]

	data.FallbackHumanoidDescription = Outfit.utils.humanoidDescriptionToRaw(humanoidDescription)
end

function Outfit.prototype.Destroy(self: OutfitInstance)
	local data = Outfit.data[self]

	if data.HumanoidChildAddedConnection then
		data.HumanoidChildAddedConnection:Disconnect()
	end

	Outfit.data[self] = nil
end

function Outfit.interface.new(): OutfitInstance
	local self: OutfitInstance = setmetatable(
		{
			OnHumanoidDescriptionChanged = Signal.new(),
		} :: any,
		{
			__index = Outfit.prototype,
		}
	) :: OutfitInstance

	Outfit.data[self] = {
		RigType = Enum.HumanoidRigType.R15,

		RawHumanoidDescription = Outfit.utils.createEmptyRawHumanoidDescription(),

		UsedBundles = {},
	}

	return self
end

function Outfit.interface.fromSnapshot(snapshot: Snapshot): OutfitInstance
	local outfitInstance = Outfit.interface.new()
	local outfitData = Outfit.data[outfitInstance]
	outfitData.RawHumanoidDescription = DubitUtils.Table.deepClone(snapshot.RawHumanoidDescription)
	outfitData.RigType = snapshot.RigType
	outfitData.UsedBundles = DubitUtils.Table.deepClone(snapshot.UsedBundles)

	return outfitInstance
end

function Outfit.interface.fromUserId(userId: number): OutfitInstance
	local outfitInstance = Outfit.interface.new()
	local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(userId)
	outfitInstance:ApplyHumanoidDescription(humanoidDescription)
	-- outfitInstance:ApplyHumanoidDescription doesn't do anything with HumanoidDescription, it just reads its fields
	humanoidDescription:Destroy()

	return outfitInstance
end

function Outfit.interface:GetAvatarRules(): any
	return Outfit.private.AvatarRules
end

populateRules()

RunService.Heartbeat:Connect(function()
	Outfit.private:DispatchDescriptionUpdates()
end)

type OutfitPrivate = typeof(Outfit.private)

return Outfit.interface
