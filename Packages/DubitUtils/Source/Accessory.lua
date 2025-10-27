--[=[
	@class DubitUtils.Accessory

	Contains utility functions for working with Accessory object types.
]=]

local Accessory = {}

--[=[
	Checks if the given asset type is an accessory.
	
	@within DubitUtils.Accessory

	@param assetType Enum.AssetType -- The asset type to check if is an accessory.

	@return boolean -- Whether the given asset type is an accessory.

	#### Example Usage

	```lua
	DubitUtils.Accessory.isAssetTypeAccessory(Enum.AssetType.ShortsAccessory) -- Will print true
	DubitUtils.Accessory.isAssetTypeAccessory(Enum.AssetType.Animation) -- Will print false
	```
]=]
function Accessory.isAssetTypeAccessory(assetType: Enum.AssetType): boolean
	if typeof(assetType) ~= "EnumItem" then
		return false
	end

	return string.find(assetType.Name, "Accessory") and true or assetType == Enum.AssetType.Hat
end

--[=[
	Matches the given asset type to its corresponding accessory type.
	
	@within DubitUtils.Accessory

	@param assetType Enum.AssetType? -- The asset type to match to an accessory type.

	@return Enum.AccessoryType -- The accessory type matching the given asset type. Will be Enum.AccessoryType.Unknown if no match is found or no valid asset type is provided.

	#### Example Usage

	```lua
	DubitUtils.Accessory.matchAssetTypeToAccessoryType(Enum.AssetType.Hat) -- Will print Enum.AccessoryType.Hat
	```
]=]
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
