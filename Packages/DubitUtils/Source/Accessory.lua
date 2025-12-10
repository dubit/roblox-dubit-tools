local Accessory = {}

function Accessory.isAssetTypeAccessory(assetType: Enum.AssetType): boolean
	if typeof(assetType) ~= "EnumItem" then
		return false
	end

	return string.find(assetType.Name, "Accessory") and true or assetType == Enum.AssetType.Hat
end

function Accessory.matchAssetTypeToAccessoryType(assetType: Enum.AssetType?): Enum.AccessoryType
	if typeof(assetType) ~= "EnumItem" or not assetType.Name then
		return Enum.AccessoryType.Unknown
	end

	for _, accessoryType in Enum.AccessoryType:GetEnumItems() do
		if string.gsub(assetType.Name, "Accessory", "") == accessoryType.Name then
			return accessoryType
		end
	end

	return Enum.AccessoryType.Unknown
end

return Accessory
