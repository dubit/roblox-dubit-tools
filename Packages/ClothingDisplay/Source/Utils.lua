--!strict

-- https://create.roblox.com/docs/reference/engine/enums/AssetType
local ASSET_ID_TO_ASSET_TYPE = {
	[2] = Enum.AssetType.TShirt,

	[8] = Enum.AssetType.Hat,

	[11] = Enum.AssetType.Shirt,
	[12] = Enum.AssetType.Pants,

	[17] = Enum.AssetType.Head,
	[18] = Enum.AssetType.Face,
	[19] = Enum.AssetType.Gear,

	[27] = Enum.AssetType.Torso,
	[28] = Enum.AssetType.RightArm,
	[29] = Enum.AssetType.LeftArm,
	[30] = Enum.AssetType.LeftLeg,
	[31] = Enum.AssetType.RightLeg,

	[41] = Enum.AssetType.HairAccessory,
	[42] = Enum.AssetType.FaceAccessory,
	[43] = Enum.AssetType.NeckAccessory,
	[44] = Enum.AssetType.ShoulderAccessory,
	[45] = Enum.AssetType.FrontAccessory,
	[46] = Enum.AssetType.BackAccessory,
	[47] = Enum.AssetType.WaistAccessory,

	[64] = Enum.AssetType.TShirtAccessory,
	[65] = Enum.AssetType.ShirtAccessory,
	[66] = Enum.AssetType.PantsAccessory,
	[67] = Enum.AssetType.JacketAccessory,
	[68] = Enum.AssetType.SweaterAccessory,
	[69] = Enum.AssetType.ShortsAccessory,
	[70] = Enum.AssetType.LeftShoeAccessory,
	[71] = Enum.AssetType.RightShoeAccessory,
	[72] = Enum.AssetType.DressSkirtAccessory,

	[76] = Enum.AssetType.EyebrowAccessory,
	[77] = Enum.AssetType.EyelashAccessory,

	[79] = Enum.AssetType.DynamicHead,
}

-- https://create.roblox.com/docs/reference/engine/enums/AssetType
local ASSETID_TO_ACCESSORY_TYPE = {
	[8] = Enum.AccessoryType.Hat,

	[41] = Enum.AccessoryType.Hair,
	[42] = Enum.AccessoryType.Face,
	[43] = Enum.AccessoryType.Neck,
	[44] = Enum.AccessoryType.Shoulder,
	[45] = Enum.AccessoryType.Front,
	[46] = Enum.AccessoryType.Back,
	[47] = Enum.AccessoryType.Waist,

	[64] = Enum.AccessoryType.TShirt,
	[65] = Enum.AccessoryType.Shirt,
	[66] = Enum.AccessoryType.Pants,
	[67] = Enum.AccessoryType.Jacket,
	[68] = Enum.AccessoryType.Sweater,
	[69] = Enum.AccessoryType.Shorts,
	[70] = Enum.AccessoryType.LeftShoe,
	[71] = Enum.AccessoryType.RightShoe,
	[72] = Enum.AccessoryType.DressSkirt,

	[76] = Enum.AccessoryType.Eyebrow,
	[77] = Enum.AccessoryType.Eyelash,
}

local ASSET_TYPE_TO_ACCESSORY_TYPE = {
	[Enum.AssetType.Hat] = Enum.AccessoryType.Hat,
	[Enum.AssetType.HairAccessory] = Enum.AccessoryType.Hair,
	[Enum.AssetType.FaceAccessory] = Enum.AccessoryType.Face,
	[Enum.AssetType.NeckAccessory] = Enum.AccessoryType.Neck,
	[Enum.AssetType.ShoulderAccessory] = Enum.AccessoryType.Shoulder,
	[Enum.AssetType.FrontAccessory] = Enum.AccessoryType.Front,
	[Enum.AssetType.BackAccessory] = Enum.AccessoryType.Back,
	[Enum.AssetType.WaistAccessory] = Enum.AccessoryType.Waist,
	[Enum.AssetType.TShirtAccessory] = Enum.AccessoryType.TShirt,
	[Enum.AssetType.ShirtAccessory] = Enum.AccessoryType.Shirt,
	[Enum.AssetType.PantsAccessory] = Enum.AccessoryType.Pants,
	[Enum.AssetType.JacketAccessory] = Enum.AccessoryType.Jacket,
	[Enum.AssetType.SweaterAccessory] = Enum.AccessoryType.Sweater,
	[Enum.AssetType.ShortsAccessory] = Enum.AccessoryType.Shorts,
	[Enum.AssetType.LeftShoeAccessory] = Enum.AccessoryType.LeftShoe,
	[Enum.AssetType.RightShoeAccessory] = Enum.AccessoryType.RightShoe,
	[Enum.AssetType.DressSkirtAccessory] = Enum.AccessoryType.DressSkirt,
	[Enum.AssetType.EyebrowAccessory] = Enum.AccessoryType.Eyebrow,
	[Enum.AssetType.EyelashAccessory] = Enum.AccessoryType.Eyelash,
}

local ACCESSORY_ORDERS: { [Enum.AccessoryType]: number } = {
	[Enum.AccessoryType.LeftShoe] = 0,
	[Enum.AccessoryType.RightShoe] = 0,

	[Enum.AccessoryType.Pants] = 1,
	[Enum.AccessoryType.Shorts] = 1,
	[Enum.AccessoryType.DressSkirt] = 1,

	[Enum.AccessoryType.Shirt] = 2,
	[Enum.AccessoryType.TShirt] = 2,

	[Enum.AccessoryType.Jacket] = 3,
	[Enum.AccessoryType.Sweater] = 3,
}

-- https://create.roblox.com/docs/reference/engine/enums/AssetType
local ASSETID_TO_BODY_PART = {
	[17] = Enum.BodyPart.Head,

	[27] = Enum.BodyPart.Torso,
	[28] = Enum.BodyPart.RightArm,
	[29] = Enum.BodyPart.LeftArm,
	[30] = Enum.BodyPart.LeftLeg,
	[31] = Enum.BodyPart.RightLeg,

	[79] = Enum.BodyPart.Head,
}

local ASSETTYPE_TO_BODY_PART_NAME: { [Enum.AssetType]: string } = {
	[Enum.AssetType.Torso] = "Torso",
	[Enum.AssetType.LeftArm] = "LeftArm",
	[Enum.AssetType.LeftLeg] = "LeftLeg",
	[Enum.AssetType.RightArm] = "RightArm",
	[Enum.AssetType.RightLeg] = "RightLeg",
	[Enum.AssetType.Head] = "Head",
	[Enum.AssetType.DynamicHead] = "Head",
}

local ASSET_TYPE_TO_BODY_PART: { [Enum.AssetType]: Enum.BodyPart } = {
	[Enum.AssetType.Torso] = Enum.BodyPart.Torso,
	[Enum.AssetType.LeftArm] = Enum.BodyPart.LeftArm,
	[Enum.AssetType.LeftLeg] = Enum.BodyPart.LeftLeg,
	[Enum.AssetType.RightArm] = Enum.BodyPart.RightArm,
	[Enum.AssetType.RightLeg] = Enum.BodyPart.RightLeg,
	[Enum.AssetType.Head] = Enum.BodyPart.Head,
	[Enum.AssetType.DynamicHead] = Enum.BodyPart.Head,
}

local BODY_PARTS: { Enum.AssetType } = table.freeze({
	Enum.AssetType.Torso,
	Enum.AssetType.LeftArm,
	Enum.AssetType.LeftLeg,
	Enum.AssetType.RightArm,
	Enum.AssetType.RightLeg,
	Enum.AssetType.Head,
})

local BODY_COLOR_PARTS: { string } = table.freeze({
	"HeadColor",
	"TorsoColor",
	"LeftArmColor",
	"RightArmColor",
	"LeftLegColor",
	"RightLegColor",
})

local CONFLICTING_ACCESSORIES = table.freeze({
	[Enum.AccessoryType.DressSkirt] = Enum.AccessoryType.Shorts,
	[Enum.AccessoryType.DressSkirt] = Enum.AccessoryType.Pants,

	[Enum.AccessoryType.Shorts] = Enum.AccessoryType.Pants,

	[Enum.AccessoryType.Sweater] = Enum.AccessoryType.Shirt,
	[Enum.AccessoryType.Sweater] = Enum.AccessoryType.TShirt,

	[Enum.AccessoryType.Shirt] = Enum.AccessoryType.TShirt,
})

local HUMANOID_SCALED_PROPERTIES = table.freeze({
	"HeadScale",
	"DepthScale",
	"WidthScale",
	"HeightScale",
	"BodyTypeScale",
	"ProportionScale",
})

local HUMANOID_DESCRIPTION_COMPARABLE = table.freeze({
	"HeadColor",
	"TorsoColor",
	"LeftArmColor",
	"RightArmColor",
	"LeftLegColor",
	"RightLegColor",

	"Torso",
	"LeftArm",
	"LeftLeg",
	"RightArm",
	"RightLeg",
	"Head",

	"Shirt",
	"Pants",
	"GraphicTShirt",

	"HeadScale",
	"DepthScale",
	"WidthScale",
	"HeightScale",
	"BodyTypeScale",
	"ProportionScale",
})

local Utils = {}

-- UNSAFE: unsafe code, if assetType string isn't a correct enum it will throw an error
-- this function shouldn't be used on it's own, it's being used within Utils.GetAssetTypeFromString
local function getAssetTypeFromStringUnsafe(assetType: string)
	return Enum.AssetType[assetType]
end

function Utils.AssetTypeIDToAccessoryType(assetTypeID: number): Enum.AccessoryType
	return ASSETID_TO_ACCESSORY_TYPE[assetTypeID] or Enum.AccessoryType.Unknown
end

function Utils.AssetTypeIDToBodyPart(assetTypeID: number): Enum.BodyPart?
	return ASSETID_TO_BODY_PART[assetTypeID]
end

function Utils.AssetTypeToAccessoryType(assetType: Enum.AssetType): Enum.AccessoryType?
	return ASSET_TYPE_TO_ACCESSORY_TYPE[assetType]
end

function Utils.GetAccessoryOrder(accessoryType: Enum.AccessoryType): number
	return ACCESSORY_ORDERS[accessoryType] or 0
end

function Utils.GetBodyParts(): { Enum.AssetType }
	return BODY_PARTS
end

function Utils.GetHumanoidScaledPropertyNames(): { string }
	return HUMANOID_SCALED_PROPERTIES
end

function Utils.GetColorBodyPartsList(): { string }
	return BODY_COLOR_PARTS
end

function Utils.AssetTypeToBodyPartFromAssetType(assetType: Enum.AssetType): string?
	return ASSETTYPE_TO_BODY_PART_NAME[assetType]
end

function Utils.DoAccessoriesConflict(accessoryA: Enum.AccessoryType, accessoryB: Enum.AccessoryType): boolean
	for accessoryX, accessoryY in CONFLICTING_ACCESSORIES do
		if
			(accessoryX == accessoryA and accessoryY == accessoryB)
			or (accessoryX == accessoryB and accessoryY == accessoryA)
		then
			return true
		end
	end

	return false
end

function Utils.GetHumanoidDescriptionAccessoryTypeCount(
	humanoidDescription: HumanoidDescription,
	accessoryType: Enum.AccessoryType
): number
	local count: number = 0

	for _, accessory in humanoidDescription:GetAccessories(true) do
		if accessory.AccessoryType == accessoryType then
			count += 1
		end
	end

	return count
end

function Utils.GetAccessoryTypeCount(accessories: { any }, accessoryType: Enum.AccessoryType): number
	local count: number = 0

	for _, accessory in accessories do
		if accessory.AccessoryType == accessoryType then
			count += 1
		end
	end

	return count
end

function Utils.HumanoidDescriptionContainsAccessory(
	humanoidDescription: HumanoidDescription,
	accessoryID: number
): boolean
	for _, accessory in humanoidDescription:GetAccessories(true) do
		if accessory.AssetId == accessoryID then
			return true
		end
	end

	return false
end

function Utils.AreHumanoidDescriptionsDifferent(
	aHumanoidDescription: HumanoidDescription,
	bHumanoidDescription: HumanoidDescription
)
	for _, bodyPart in HUMANOID_DESCRIPTION_COMPARABLE do
		if aHumanoidDescription[bodyPart] ~= bHumanoidDescription[bodyPart] then
			return true
		end
	end

	local aAccessories = aHumanoidDescription:GetAccessories(true)
	local bAccessories = bHumanoidDescription:GetAccessories(true)

	if #aAccessories ~= #bAccessories then
		return true
	end

	for i = 1, #aAccessories do
		if aAccessories[i].AssetId ~= bAccessories[i].AssetId then
			return true
		end
	end

	return false
end

function Utils.GetAssetTypeFromString(assetType: string): Enum.AssetType?
	local success, returnedType = pcall(getAssetTypeFromStringUnsafe, assetType)

	return success and returnedType
end

function Utils.GetAssetTypeFromAssetTypeId(assetId: number): Enum.AssetType?
	return ASSET_ID_TO_ASSET_TYPE[assetId]
end

function Utils.GetBodyPartFromAssetType(bodyPart: Enum.AssetType): Enum.BodyPart?
	return ASSET_TYPE_TO_BODY_PART[bodyPart]
end

function Utils.AreTablesDifferent(source: any, other: any)
	for key, value in source do
		if typeof(value) == "table" and typeof(other[key]) == "table" then
			if Utils.AreTablesDifferent(value, other[key]) then
				return true
			end
			continue
		end

		if value ~= other[key] then
			return true
		end
	end

	return false
end

return Utils
