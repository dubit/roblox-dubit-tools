--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Types = require(script.Parent.Types)

local Signal = require(script.Parent.Parent.Parent.Signal)
local DubitUtils = require(script.Parent.Parent.Parent.DubitUtils)
local Stack = DubitUtils.Stack

local Utils = require(script.Parent.Parent.Utils)

type Stack<T> = typeof(Stack.new())

type ItemQueue = {
	QueriesStack: Stack<number>,
	QueuedItems: { [number]: boolean },
}

local ItemDetails = {}
ItemDetails.cache = {
	AssetCache = {} :: { [number]: Types.AssetDetails },
	AssetCacheSize = 0,
	BundleCache = {} :: { [number]: Types.BundleDetails },
	BundleCacheSize = 0,
}
ItemDetails.data = {
	AssetQuerying = {} :: { [number]: boolean },
	AssetOwnership = {} :: { [Player]: { [number]: boolean } },
	AssetOwnershipPending = {} :: { [Player]: { [number]: boolean } },

	BundleQuerying = {} :: { [number]: boolean },
	BundleOwnership = {} :: { [Player]: { [number]: boolean } },
	BundleOwnershipPending = {} :: { [Player]: { [number]: boolean } },
}
ItemDetails.private = {}
ItemDetails.public = {
	OnAssetDataRetrieved = Signal.new(),
	OnAssetDataUpdated = Signal.new(),
	OnBundleDataRetrieved = Signal.new(),

	OnAssetOwnershipRetrieved = Signal.new(),
	OnBundleOwnershipRetrieved = Signal.new(),
}

function ItemDetails.cache.CacheAssetDetails(assetDetails: Types.AssetDetails)
	assert(table.isfrozen(assetDetails), "Asset details need to be frozen before they can be cached")

	local cachedAsset = ItemDetails.cache.AssetCache[assetDetails.Id]
	if cachedAsset then
		ItemDetails.cache.AssetCache[assetDetails.Id] = assetDetails
		return
	end

	ItemDetails.cache.AssetCache[assetDetails.Id] = assetDetails
	ItemDetails.cache.AssetCacheSize += 1
end

function ItemDetails.cache.CacheBundleDetails(bundleDetails: Types.BundleDetails)
	assert(table.isfrozen(bundleDetails), "Bundle details need to be frozen before they can be cached")

	local cachedBundle = ItemDetails.cache.BundleCache[bundleDetails.Id]
	if cachedBundle then
		ItemDetails.cache.BundleCache[bundleDetails.Id] = bundleDetails
		return
	end

	ItemDetails.cache.BundleCache[bundleDetails.Id] = bundleDetails
	ItemDetails.cache.BundleCacheSize += 1
end

function ItemDetails.cache.GetAssetData(assetId: number): Types.AssetDetails?
	return ItemDetails.cache.AssetCache[assetId]
end

function ItemDetails.cache.GetBundleData(bundleId: number): Types.BundleDetails?
	return ItemDetails.cache.BundleCache[bundleId]
end

function ItemDetails.private.OnPlayerAdded(player: Player)
	ItemDetails.data.AssetOwnership[player] = {}
	ItemDetails.data.AssetOwnershipPending[player] = {}
	ItemDetails.data.BundleOwnership[player] = {}
	ItemDetails.data.BundleOwnershipPending[player] = {}
end

function ItemDetails.private.OnPlayerRemoving(player: Player)
	ItemDetails.data.AssetOwnership[player] = nil
	ItemDetails.data.AssetOwnershipPending[player] = nil
	ItemDetails.data.BundleOwnership[player] = nil
	ItemDetails.data.BundleOwnershipPending[player] = nil
end

function ItemDetails.private.Init()
	Players.PlayerAdded:Connect(ItemDetails.private.OnPlayerAdded)
	Players.PlayerRemoving:Connect(ItemDetails.private.OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		ItemDetails.private.OnPlayerAdded(player)
	end

	MarketplaceService.PromptBundlePurchaseFinished:Connect(function(player: Player, bundleId: number, success: boolean)
		if not success then
			return
		end

		if not ItemDetails.data.BundleOwnership[player] then
			return
		end

		ItemDetails.data.BundleOwnership[player][bundleId] = true
		ItemDetails.public.OnBundleOwnershipRetrieved:Fire(player, bundleId, true)
	end)

	MarketplaceService.PromptPurchaseFinished:Connect(function(player: Player, assetId: number, success: boolean)
		if not success then
			return
		end

		if not ItemDetails.data.AssetOwnership[player] then
			return
		end

		ItemDetails.data.AssetOwnership[player][assetId] = true
		ItemDetails.public.OnAssetOwnershipRetrieved:Fire(player, assetId, true)
	end)

	MarketplaceService.PromptBulkPurchaseFinished:Connect(function(player, status, results)
		if player ~= Players.LocalPlayer then
			return
		end

		if status ~= Enum.MarketplaceBulkPurchasePromptStatus.Completed then
			return
		end

		for _, result in results.Items do
			if result.status ~= Enum.MarketplaceItemPurchaseStatus.Success then
				continue
			end

			local id = tonumber(result.id)
			if not id then
				continue
			end

			if result.type == Enum.MarketplaceProductType.AvatarAsset then
				ItemDetails.data.AssetOwnership[Players.LocalPlayer][id] = true
				ItemDetails.public.OnAssetOwnershipRetrieved:Fire(Players.LocalPlayer, id, true)
			elseif result.type == Enum.MarketplaceProductType.AvatarBundle then
				ItemDetails.data.BundleOwnership[Players.LocalPlayer][id] = true
				ItemDetails.public.OnBundleOwnershipRetrieved:Fire(Players.LocalPlayer, id, true)
			end
		end
	end)
end

function ItemDetails.private.QueryMarketplaceService(method: string, ...): any
	local success, data = pcall(MarketplaceService[method], MarketplaceService, ...)
	if not success then
		return
	end

	return data
end

function ItemDetails.private.QueryAssetDetails(assetId: number): Types.AssetDetails?
	local cachedDetails = ItemDetails.cache.GetAssetData(assetId)
	if cachedDetails then
		return
	end

	local assetStateLookup = ItemDetails.data.AssetQuerying
	if assetStateLookup[assetId] then
		return
	end

	local productInfo = ItemDetails.private.QueryMarketplaceService("GetProductInfo", assetId, Enum.InfoType.Asset)
	if not productInfo then
		return
	end

	assetStateLookup[assetId] = true

	local assetDetails: Types.AssetDetails = {
		Id = productInfo.AssetId,
		Price = productInfo.PriceInRobux or 0,
		IsOffSale = not productInfo.IsForSale,
		AssetType = Utils.GetAssetTypeFromAssetTypeId(productInfo.AssetTypeId) :: Enum.AssetType,

		Name = productInfo.Name or "",

		Limited = productInfo.CollectiblesItemDetails and productInfo.CollectiblesItemDetails.IsLimited and {
			IsUnique = productInfo.IsLimitedUnique,
			IsReselling = productInfo.CollectiblesItemDetails.CollectibleLowestResalePrice ~= nil,

			LowestResalePrice = productInfo.CollectiblesItemDetails.CollectibleLowestResalePrice,
			Remaining = productInfo.Remaining or 0,
			TotalQuantity = productInfo.CollectiblesItemDetails.TotalQuantity or 0,
		},
	}
	DubitUtils.Table.deepFreeze(assetDetails)
	ItemDetails.cache.CacheAssetDetails(assetDetails)

	ItemDetails.public.OnAssetDataRetrieved:Fire(assetDetails)

	assetStateLookup[assetId] = nil
	return assetDetails
end

function ItemDetails.private.QueryBundleDetails(bundleId: number): Types.BundleDetails?
	local cachedDetails = ItemDetails.cache.GetBundleData(bundleId)
	if cachedDetails then
		return
	end

	local bundleStateLookup = ItemDetails.data.BundleQuerying
	if bundleStateLookup[bundleId] then
		return
	end

	local success, result =
		pcall(AvatarEditorService.GetItemDetails, AvatarEditorService, bundleId, Enum.AvatarItemType.Bundle)
	if not success then
		return
	end

	bundleStateLookup[bundleId] = true

	local itemsAssetIds: { [number]: Types.BundleAsset | Types.BundleAnimation } = {}
	for itemIndex, bundledItem in result.BundledItems do
		if bundledItem.Type ~= "Asset" then
			continue
		end

		-- We cannot determine if an item is an Asset or an Animation so animations will be reported back as Assets!
		itemsAssetIds[itemIndex] = {
			Type = "Asset",
			Id = bundledItem.Id,
		}
	end

	local bundleDetails: Types.BundleDetails = {
		Id = result.Id,
		Price = result.Price or 0,
		IsOffSale = not result.IsPurchasable,

		Name = result.Name or "",

		Items = itemsAssetIds,
	}
	DubitUtils.Table.deepFreeze(bundleDetails)
	ItemDetails.cache.CacheBundleDetails(bundleDetails)

	ItemDetails.public.OnBundleDataRetrieved:Fire(bundleDetails)

	bundleStateLookup[bundleId] = nil
	return bundleDetails
end

function ItemDetails.public.IsAssetOwned(player: Player, assetId: number): boolean
	local cachedOwnershipData = ItemDetails.data.AssetOwnership[player]
	if not cachedOwnershipData then
		return false
	end

	local playerPendingAssetOwnershipRequests = ItemDetails.data.AssetOwnershipPending[player]
	if not playerPendingAssetOwnershipRequests then
		return false
	end

	while playerPendingAssetOwnershipRequests[assetId] do
		task.wait()
	end

	local assetOwned = cachedOwnershipData[assetId]
	if assetOwned then
		return assetOwned
	end

	playerPendingAssetOwnershipRequests[assetId] = true

	assetOwned = ItemDetails.private.QueryMarketplaceService("PlayerOwnsAsset", player, assetId)

	playerPendingAssetOwnershipRequests[assetId] = nil

	if assetOwned == nil then
		return false
	end

	-- if player left when data was being fetched
	if not ItemDetails.data.AssetOwnership[player] then
		return false
	end

	cachedOwnershipData[assetId] = assetOwned

	ItemDetails.public.OnAssetOwnershipRetrieved:Fire(player, assetId, assetOwned)

	return assetOwned
end

function ItemDetails.public.IsAssetCached(assetId: number): boolean
	return ItemDetails.cache.AssetCache[assetId] ~= nil
end

function ItemDetails.public.GetAssetDetails(assetId: number): Types.AssetDetails?
	local itemDetails = ItemDetails.cache.AssetCache[assetId]
	if itemDetails then
		return itemDetails
	end

	return ItemDetails.private.QueryAssetDetails(assetId)
end

function ItemDetails.public.GetAssetDetailsAsync(assetId: number, callback: (assetDetails: Types.AssetDetails?) -> ())
	task.spawn(function()
		local assetDetails = ItemDetails.public.GetAssetDetails(assetId)
		callback(assetDetails)
	end)
end

function ItemDetails.public.PreloadAssetDetails(assetId: number)
	ItemDetails.private.QueryAssetDetails(assetId)
end

function ItemDetails.public.IsBundleOwned(player: Player, bundleId: number): boolean
	local cachedOwnershipData = ItemDetails.data.BundleOwnership[player]
	if not cachedOwnershipData then
		return false
	end

	local playerPendingBundleOwnershipRequests = ItemDetails.data.BundleOwnershipPending[player]

	while playerPendingBundleOwnershipRequests[bundleId] do
		task.wait()
	end

	local bundleOwned = cachedOwnershipData[bundleId]
	if bundleOwned then
		return bundleOwned
	end

	playerPendingBundleOwnershipRequests[bundleId] = true

	bundleOwned = ItemDetails.private.QueryMarketplaceService("PlayerOwnsBundle", player, bundleId)

	playerPendingBundleOwnershipRequests[bundleId] = nil

	if bundleOwned == nil then
		return false
	end

	-- if player left when data was being fetched
	if not ItemDetails.data.BundleOwnership[player] then
		return false
	end

	cachedOwnershipData[bundleId] = bundleOwned

	ItemDetails.public.OnBundleOwnershipRetrieved:Fire(player, bundleId, bundleOwned)

	return bundleOwned
end

function ItemDetails.public.IsBundleCached(bundleId: number): boolean
	return ItemDetails.cache.BundleCache[bundleId] ~= nil
end

function ItemDetails.public.GetBundleDetails(bundleId: number): Types.BundleDetails?
	local itemDetails = ItemDetails.cache.BundleCache[bundleId]
	if itemDetails then
		return itemDetails
	end

	return ItemDetails.private.QueryBundleDetails(bundleId)
end

function ItemDetails.public.GetBundleDetailsAsync(
	bundleId: number,
	callback: (bundleDetails: Types.BundleDetails?) -> ()
)
	task.spawn(function()
		local bundleDetails = ItemDetails.public.GetBundleDetails(bundleId)
		callback(bundleDetails)
	end)
end

function ItemDetails.public.PreloadBundleDetails(bundleId: number)
	ItemDetails.private.QueryBundleDetails(bundleId)
end

ItemDetails.private.Init()

return ItemDetails.public
