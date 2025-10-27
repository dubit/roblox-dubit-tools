--!strict
local RunService = game:GetService("RunService")

local Types = require(script.Types)

local isServer = RunService:IsServer()

local itemDetails: Types.ItemDetails
if isServer then
	local itemDetailsServer = require(script.Server)
	itemDetails = {
		IsAssetOwned = itemDetailsServer.IsAssetOwned,
		IsAssetCached = itemDetailsServer.IsAssetCached,
		GetAssetDetails = itemDetailsServer.GetAssetDetails,
		GetAssetDetailsAsync = itemDetailsServer.GetAssetDetailsAsync,
		PreloadAssetDetails = itemDetailsServer.PreloadAssetDetails,

		IsBundleOwned = itemDetailsServer.IsBundleOwned,
		IsBundleCached = itemDetailsServer.IsBundleCached,
		GetBundleDetails = itemDetailsServer.GetBundleDetails,
		GetBundleDetailsAsync = itemDetailsServer.GetBundleDetailsAsync,
		PreloadBundleDetails = itemDetailsServer.PreloadBundleDetails,

		OnAssetDataRetrieved = itemDetailsServer.OnAssetDataRetrieved,
		OnAssetDataUpdated = itemDetailsServer.OnAssetDataUpdated,
		OnBundleDataRetrieved = itemDetailsServer.OnBundleDataRetrieved,

		OnAssetOwnershipRetrieved = itemDetailsServer.OnAssetOwnershipRetrieved,
		OnBundleOwnershipRetrieved = itemDetailsServer.OnBundleOwnershipRetrieved,
	}
else
	local itemDetailsClient = require(script.Client)
	itemDetails = {
		IsAssetOwned = itemDetailsClient.IsAssetOwned,
		IsAssetCached = itemDetailsClient.IsAssetCached,
		GetAssetDetails = itemDetailsClient.GetAssetDetails,
		GetAssetDetailsAsync = itemDetailsClient.GetAssetDetailsAsync,
		PreloadAssetDetails = itemDetailsClient.PreloadAssetDetails,

		IsBundleOwned = itemDetailsClient.IsBundleOwned,
		IsBundleCached = itemDetailsClient.IsBundleCached,
		GetBundleDetails = itemDetailsClient.GetBundleDetails,
		GetBundleDetailsAsync = itemDetailsClient.GetBundleDetailsAsync,
		PreloadBundleDetails = itemDetailsClient.PreloadBundleDetails,

		OnAssetDataRetrieved = itemDetailsClient.OnAssetDataRetrieved,
		OnAssetDataUpdated = itemDetailsClient.OnAssetDataUpdated,
		OnBundleDataRetrieved = itemDetailsClient.OnBundleDataRetrieved,

		OnAssetOwnershipRetrieved = itemDetailsClient.OnAssetOwnershipRetrieved,
		OnBundleOwnershipRetrieved = itemDetailsClient.OnBundleOwnershipRetrieved,
	}
end

return itemDetails
