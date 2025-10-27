--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Parent.Utils)

local Signal = require(script.Parent.Parent.Parent.Signal)
local DubitUtils = require(script.Parent.Parent.Parent.DubitUtils)
local Stack = DubitUtils.Stack

type Stack<T> = typeof(Stack.new())

type AssetQueue = {
	BatchesStack: Stack<AssetQueueBatch>,
	QueuedItems: { [number]: boolean },

	Processing: boolean,
}

type AssetQueueBatch = {
	GotModifiedLastFrame: boolean,
	QueryHoldFrames: number,

	Queries: { number },
	QueriesCount: number,
}

type BundleQueue = {
	QueriesStack: Stack<number>,
	QueuedItems: { [number]: boolean },
}

-- Some of resellers put up items for sale at absurd prices, we wanna limit it to a number that doesn't overflow u24
local PRICE_CLAMP = 1000000

local STALE_ITEM_DATA_UPDATE_RATE = 45 -- how often Master server should look at "stale" items and fetch new data
local STALE_ITEM_TIME = 60 * 5 -- after how long an item is considered "stale"
local SPOILED_ITEM_TIME = 3600 * 24 -- after how long an item is considered "spoiled" and should be removed from cache

local CACHE_UPDATE_RATE = 30 -- how often Master should upload it's own cache into MemoryStoreService / Slave should pull the data from MemoryStoreService
local CACHE_OWNERSHIP_HEARTBEAT = 60 -- how often Master is updating it's ownership / Slave is looking up to replace the current Master
local CACHE_EXPIRATION = 3600 * 24 -- for how long the cache exists in MemoryStoreService
local CACHE_DATA_SCHEMA_VERSION = 0
local CACHE_ASSET_ENTRY_MAX_SIZE = 346 -- size in bytes
local CACHE_CHUNK_SIZE = 4000000 -- size in bytes

local QUERY_HOLD_LIMIT = 3 -- for how many frames asset query batch can be held if batch was modified in previous frame
local QUERY_TIMEOUT = 15.00 -- after how many seconds request of item details should return nil
local QUERY_RETRY_LIMIT = 5 -- up to how many times library will attempt fetching item details if previous request failed

local ASSET_TYPE_FROM_ID_MAP = Enum.AssetType:GetEnumItems()
DubitUtils.Table.deepFreeze(ASSET_TYPE_FROM_ID_MAP)

local ASSET_TYPE_TO_ID_MAP = DubitUtils.Table.construct(function()
	local reverseEnumItems: { [Enum.AssetType]: number } = {}

	for index, value in Enum.AssetType:GetEnumItems() do
		reverseEnumItems[value] = index
	end

	return reverseEnumItems
end)
DubitUtils.Table.deepFreeze(ASSET_TYPE_TO_ID_MAP)

local ItemDetails = {}
ItemDetails.cache = {
	UpdateTimeAccumulator = 0.00,
	HeartbeatAccumulator = 0.00,
	StaleUpdateAccumulator = 0.00,

	Memory = MemoryStoreService:GetHashMap("__Dubit_ClothingDisplay_Cache"),
	Storage = DataStoreService:GetDataStore("__Dubit_ClothingDisplay_Cache", "v1"),

	Status = nil :: ("Slave" | "Master")?,
	InitialPullDone = false,
	ProcessingStaleItems = false,

	ActiveChunks = {},

	AssetCache = {} :: { Types.AssetDetails },
	AssetCacheLookup = {} :: { [number]: Types.AssetDetails },
	AssetCacheSize = 0,

	BundleCache = {} :: { [number]: Types.BundleDetails },
	BundleCacheSize = 0,
}
ItemDetails.data = {
	AssetQueue = {
		BatchesStack = Stack.new(),
		QueuedItems = {},

		Processing = false,
	} :: AssetQueue,
	AssetOwnership = {} :: { [Player]: { [number]: boolean } },
	AssetOwnershipPending = {} :: { [Player]: { [number]: boolean } },
	AssetUsedThisSession = {} :: { [number]: boolean },
	AssetLastUpdated = {} :: { [number]: number },

	BundleQueue = {
		QueriesStack = Stack.new(),
		QueuedItems = {},
	} :: BundleQueue,
	BundleOwnership = {} :: { [Player]: { [number]: boolean } },
	BundleOwnershipPending = {} :: { [Player]: { [number]: boolean } },
	BundleFetchFails = {} :: { [number]: number },
	BundleLastUpdated = {} :: { [number]: number },
}
ItemDetails.private = {}
ItemDetails.public = {
	OnAssetDataRetrieved = Signal.new(),
	OnAssetDataUpdated = Signal.new(),
	OnBundleDataRetrieved = Signal.new(),

	OnAssetOwnershipRetrieved = Signal.new(),
	OnBundleOwnershipRetrieved = Signal.new(),
}

function ItemDetails.cache.PerformStorageAction(method: string, retryCount: number, ...): ...any
	local success, result
	local retries = 0
	while not success do
		local pcallReturn = table.pack(pcall(ItemDetails.cache.Storage[method], ItemDetails.cache.Storage, ...))
		success = table.remove(pcallReturn, 1)
		result = pcallReturn

		retries += 1
		if retries > retryCount then
			break
		end
		task.wait()
	end

	return table.unpack(result)
end

function ItemDetails.cache.PerformMemoryAction(method: string, retryCount: number, ...): ...any
	local success, result
	local retries = 0
	while not success do
		local pcallReturn = table.pack(pcall(ItemDetails.cache.Memory[method], ItemDetails.cache.Memory, ...))
		success = table.remove(pcallReturn, 1)
		result = pcallReturn

		retries += 1
		if retries > retryCount then
			break
		end
		task.wait()
	end

	return table.unpack(result)
end

function ItemDetails.cache.ProcessStaleItems()
	if ItemDetails.cache.ProcessingStaleItems then
		return
	end

	ItemDetails.cache.ProcessingStaleItems = true

	local startTime = os.time()
	local staleItemsCount = 0
	for assetId in ItemDetails.cache.AssetCacheLookup do
		local wasUsedThisSession = ItemDetails.data.AssetUsedThisSession[assetId] ~= nil
		local lastUpdatedDifference = startTime - ItemDetails.data.AssetLastUpdated[assetId]
		local isStale = lastUpdatedDifference >= STALE_ITEM_TIME
		local isSpoiled = lastUpdatedDifference >= SPOILED_ITEM_TIME

		if not wasUsedThisSession and isSpoiled then
			local assetCacheIndex =
				table.find(ItemDetails.cache.AssetCache, ItemDetails.cache.AssetCacheLookup[assetId])

			if assetCacheIndex then
				table.remove(ItemDetails.cache.AssetCache, assetCacheIndex)
			end

			ItemDetails.cache.AssetCacheLookup[assetId] = nil
			ItemDetails.cache.AssetCacheSize -= 1
			continue
		end

		if wasUsedThisSession and not isStale then
			continue
		end

		staleItemsCount += 1

		ItemDetails.private.QueryAssetDetails(assetId)

		-- we need to add some randomization when items got updated otherwise we would get big batches of stale items
		if staleItemsCount % 100 == 0 then
			task.wait(math.random(20, 150) / 100.00)
		end
	end

	ItemDetails.cache.ProcessingStaleItems = false
end

function ItemDetails.cache.WaitForStatus()
	while not ItemDetails.cache.Status do
		task.wait()
	end
end

function ItemDetails.cache.Pull()
	ItemDetails.cache.UpdateTimeAccumulator = 0.00

	local chunksData = ItemDetails.cache.PerformMemoryAction("GetAsync", 5, "Chunks")

	-- cache is empty
	if not chunksData then
		ItemDetails.cache.InitialPullDone = true
		return
	end

	for index, chunkHash in chunksData do
		local activeChunkHash = ItemDetails.cache.ActiveChunks[index]
		if activeChunkHash == chunkHash then
			continue
		end

		ItemDetails.cache.ActiveChunks[index] = chunkHash

		local chunkBuffer = ItemDetails.cache.PerformStorageAction("GetAsync", 5, `Chunk_{index}`)
		if not chunkBuffer then
			continue
		end

		local reader = DubitUtils.BufferReader.new(chunkBuffer)
		while reader.Offset < buffer.len(reader.Buffer) do
			local lastUpdated = reader:Readu56()
			local assetId = reader:Readu56()
			local price = reader:Readu24()
			local assetTypeId = reader:Readu8()
			local bools = reader:Readb8()
			local isAsset = bools[1]
			local isOffSale = bools[2]
			local isLimited = bools[3]
			local lowestResalePrice
			local remaining
			local totalQuantity
			local assetName = reader:ReadVarLenString()

			if isAsset and isLimited then
				lowestResalePrice = reader:Readu24()
				remaining = reader:Readu24()
				totalQuantity = reader:Readu24()
			end

			local itemDetails = {
				Id = assetId,
				Price = price,
				IsOffSale = isOffSale,

				AssetType = ASSET_TYPE_FROM_ID_MAP[assetTypeId] :: Enum.AssetType,

				Name = assetName,

				Limited = isLimited and {
					IsUnique = bools[4],
					IsReselling = bools[5],

					LowestResalePrice = lowestResalePrice,
					Remaining = remaining,
					TotalQuantity = totalQuantity,
				} or nil,
			}
			DubitUtils.Table.deepFreeze(itemDetails)
			ItemDetails.data.AssetLastUpdated[assetId] = lastUpdated

			ItemDetails.cache.CacheAssetDetails(itemDetails)
		end
	end

	ItemDetails.cache.InitialPullDone = true
end

function ItemDetails.cache.Upload()
	local chunks = {}

	local activeWriter = DubitUtils.BufferWriter.new(CACHE_CHUNK_SIZE)
	for _, cachedAsset in ItemDetails.cache.AssetCache do
		if activeWriter.Offset + CACHE_ASSET_ENTRY_MAX_SIZE > CACHE_CHUNK_SIZE then
			activeWriter:Fit()
			table.insert(chunks, activeWriter.Buffer)

			activeWriter = DubitUtils.BufferWriter.new(CACHE_CHUNK_SIZE)
			activeWriter:Writeu8(CACHE_DATA_SCHEMA_VERSION)
			activeWriter:Writeu24(game.PlaceVersion)
		end

		activeWriter:Writeu56(ItemDetails.data.AssetLastUpdated[cachedAsset.Id])
		activeWriter:Writeu56(cachedAsset.Id)
		activeWriter:Writeu24(math.clamp(cachedAsset.Price or 0, 0, PRICE_CLAMP))
		activeWriter:Writeu8(ASSET_TYPE_TO_ID_MAP[cachedAsset.AssetType])
		activeWriter:Writeb8(
			true,
			cachedAsset.IsOffSale,
			cachedAsset.Limited ~= nil,
			cachedAsset.Limited and cachedAsset.Limited.IsUnique or false,
			cachedAsset.Limited and cachedAsset.Limited.IsReselling or false
		)

		local assetName = cachedAsset.Name or ""
		-- As of writing this the current asset name limit is 50 chars, but for sake of future proofing
		--  i'll add this just to be safe.
		-- - Kuba, 11 Apr 2024
		-- I've decided to stick to the current asset name limit which is still 50 chars, I've made that
		--  choice because I need a better and realistic approximate of the 'average' asset entry size.
		--   So with all of that the max size of this is ~53 bytes, could be way more if emojis are used.
		--   From my testing an emoji takes up about ~3 bytes so worst case scenario that's 153 bytes,
		--    150 - 50 chars * 3 bytes + 3 chars for '...' which are 1 byte each
		-- - Kuba, 3 Jun 2024
		local formattedAssetName = string.sub(assetName, 1, 50)
		if #assetName > 50 then
			formattedAssetName ..= "..."
		end

		-- WriteVarLenString writes additional byte for the name so the worst case scenario for the name is
		-- 154 bytes, these names are heavy...
		activeWriter:WriteVarLenString(formattedAssetName)

		if cachedAsset.Limited then
			activeWriter:Writeu24(math.clamp(cachedAsset.Limited.LowestResalePrice or 0, 0, PRICE_CLAMP))
			activeWriter:Writeu24(cachedAsset.Limited.Remaining or 0)
			activeWriter:Writeu24(cachedAsset.Limited.TotalQuantity or 0)
		end
	end

	activeWriter:Fit()
	table.insert(chunks, activeWriter.Buffer)

	local md5Hashes = {}
	for index, chunkBuffer in chunks do
		md5Hashes[index] = DubitUtils.MD5(buffer.tostring(chunkBuffer))
	end

	ItemDetails.cache.PerformMemoryAction("SetAsync", 5, `Chunks`, md5Hashes, CACHE_EXPIRATION)

	-- Master will always initially send all of the chunks as the order of items isn't the same between server instances (Luau dictionaries have no guaranteed ordering),
	--  and because of that different MD5 hashes are generated, we might wanna revisit it in the future if it becomes a problem,
	--  it can become a problem because when a master switches ownership the other slaves will notice the difference in hashes and all of the
	--  servers will try to fetch new chunks.
	-- - Kuba, 3 Jun 2024
	for index, chunkBuffer in chunks do
		local activeChunkHash = ItemDetails.cache.ActiveChunks[index]
		if activeChunkHash == md5Hashes[index] then
			continue
		end

		ItemDetails.cache.PerformStorageAction("SetAsync", 5, `Chunk_{index}`, chunkBuffer)
	end

	ItemDetails.cache.ActiveChunks = md5Hashes
end

function ItemDetails.cache.Update()
	if not ItemDetails.cache.InitialPullDone then
		ItemDetails.cache.Pull()
		return
	end

	if not ItemDetails.cache.Status then
		ItemDetails.cache.WaitForStatus()
	end

	if ItemDetails.cache.Status == "Master" then
		ItemDetails.cache.Upload()
	elseif ItemDetails.cache.Status == "Slave" then
		ItemDetails.cache.Pull()
	end
end

function ItemDetails.cache.Heartbeat()
	pcall(function()
		ItemDetails.cache.PerformMemoryAction("UpdateAsync", 5, "Master", function(masterData: any)
			if masterData and masterData == game.JobId then
				-- the server is master and stays master
				ItemDetails.cache.Status = "Master"
				return game.JobId
			elseif masterData and masterData ~= game.JobId then
				-- the server is staying a slave
				ItemDetails.cache.Status = "Slave"
				return nil
			end

			if ItemDetails.cache.Status == "Slave" then
				-- slave becomes master
				ItemDetails.cache.Pull()
			end

			-- there is no master so this server becomes master
			ItemDetails.cache.Status = "Master"
			return game.JobId
		end, CACHE_OWNERSHIP_HEARTBEAT * 1.70) -- giving Master some extra room in case he struggles with updating his ownership
	end)
end

function ItemDetails.cache.CacheAssetDetails(assetDetails: Types.AssetDetails)
	assert(table.isfrozen(assetDetails), "Asset details need to be frozen before they can be cached")
	assert(assetDetails.AssetType ~= nil, "Asset details need to contain Asset Type field!")
	assert(ASSET_TYPE_TO_ID_MAP[assetDetails.AssetType] ~= nil, "Asset details need to contain valid Asset Type field!")
	assert(assetDetails.Price ~= nil, "Asset details need to contain Price field!")
	assert(assetDetails.IsOffSale ~= nil, "Asset details need to contain IsOffSale field!")

	local cachedAsset = ItemDetails.cache.AssetCacheLookup[assetDetails.Id]
	if cachedAsset and Utils.AreTablesDifferent(cachedAsset, assetDetails) then
		local existingAssetIndex = table.find(ItemDetails.cache.AssetCache, cachedAsset)

		if existingAssetIndex then -- shouldn't be false ever
			ItemDetails.cache.AssetCache[existingAssetIndex] = assetDetails
		end

		ItemDetails.cache.AssetCacheLookup[assetDetails.Id] = assetDetails

		ItemDetails.public.OnAssetDataUpdated:Fire(assetDetails)
		return
	end

	table.insert(ItemDetails.cache.AssetCache, assetDetails)
	ItemDetails.cache.AssetCacheLookup[assetDetails.Id] = assetDetails
	ItemDetails.cache.AssetCacheSize += 1

	ItemDetails.public.OnAssetDataRetrieved:Fire(assetDetails)
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

	ItemDetails.public.OnBundleDataRetrieved:Fire(bundleDetails)
end

function ItemDetails.cache.GetAssetData(assetId: number): Types.AssetDetails?
	while not ItemDetails.cache.InitialPullDone do
		task.wait()
	end

	return ItemDetails.cache.AssetCacheLookup[assetId]
end

function ItemDetails.cache.GetBundleData(bundleId: number): Types.BundleDetails?
	-- we don't need to wait for InitialPullDone as bundles currently aren't cached into MemoryStoreService
	return ItemDetails.cache.BundleCache[bundleId]
end

function ItemDetails.private.QueryMarketplaceService(method: string, ...): any
	local success, data = pcall(MarketplaceService[method], MarketplaceService, ...)
	if not success then
		return
	end

	return data
end

function ItemDetails.private.ProcessAssetDetailsQuerying()
	local assetQueue = ItemDetails.data.AssetQueue
	if assetQueue.Processing or assetQueue.BatchesStack.size <= 0 then
		return
	end

	assetQueue.Processing = true
	while assetQueue.BatchesStack.size > 0 do
		local batch = assetQueue.BatchesStack:peek()
		local wasModifiedLastFrame = batch.GotModifiedLastFrame
		batch.GotModifiedLastFrame = false

		if (wasModifiedLastFrame or batch.QueriesCount < 10) and batch.QueryHoldFrames < QUERY_HOLD_LIMIT then
			batch.QueryHoldFrames += 1
			-- we wanna break the while loop as this should be last batch either way
			break
		end

		local success, result = pcall(
			AvatarEditorService.GetBatchItemDetails,
			AvatarEditorService,
			batch.Queries,
			Enum.AvatarItemType.Asset
		)

		if success then
			assetQueue.BatchesStack:popFirst()
			for _, assetDetails in result do
				if not assetDetails.AssetType then
					warn(`Item details didn't contain "AssetType" field for "{assetDetails.Id or "unknown"}"`)
					continue
				end

				local firstItemRestriction = assetDetails.ItemRestrictions[1]
				local isOffSale = assetDetails.PriceStatus == "Off Sale"

				local cachedDetails: Types.AssetDetails = {
					Id = assetDetails.Id,
					Price = assetDetails.Price or 0,
					IsOffSale = isOffSale,
					AssetType = Enum.AssetType[assetDetails.AssetType],

					Name = assetDetails.Name or "",

					Limited = firstItemRestriction
						and {
							IsUnique = firstItemRestriction == "Collectible" or firstItemRestriction == "LimitedUnique",
							IsReselling = assetDetails.HasResellers,

							LowestResalePrice = assetDetails.LowestResalePrice,
							Remaining = assetDetails.UnitsAvailableForConsumption,
							TotalQuantity = assetDetails.TotalQuantity,
						},
				}
				DubitUtils.Table.deepFreeze(cachedDetails)

				ItemDetails.data.AssetLastUpdated[assetDetails.Id] = os.time()

				ItemDetails.cache.CacheAssetDetails(cachedDetails)

				assetQueue.QueuedItems[assetDetails.Id] = nil
			end
		else
			warn(`Fetching batch item details failed, reason: {result}`)
		end
	end
	assetQueue.Processing = false
end

function ItemDetails.private.ProcessBundleDetailsQuerying()
	local bundleQueue = ItemDetails.data.BundleQueue

	if bundleQueue.QueriesStack.size <= 0 then
		return
	end

	local bundleId = bundleQueue.QueriesStack:pop() :: any

	local success, result =
		pcall(AvatarEditorService.GetItemDetails, AvatarEditorService, bundleId, Enum.AvatarItemType.Bundle)

	local function fetchingFailed(reason: any)
		local bundleFetchFails = ItemDetails.data.BundleFetchFails[bundleId]

		if bundleFetchFails and bundleFetchFails >= QUERY_RETRY_LIMIT then
			ItemDetails.data.BundleFetchFails[bundleId] = nil
			return
		end

		if not bundleFetchFails then
			ItemDetails.data.BundleFetchFails[bundleId] = 1
		else
			ItemDetails.data.BundleFetchFails[bundleId] += 1
		end

		bundleQueue.QueriesStack:pushLast(bundleId)

		warn(`Fetching bundle details failed, reason: {reason}`)
	end

	if not success then
		fetchingFailed(result)
		return
	end

	local itemsAssetIds: { [number]: Types.BundleAsset | Types.BundleAnimation } = {}
	for itemIndex, bundledItem in result.BundledItems do
		if bundledItem.Type ~= "Asset" then
			continue
		end

		local loadAssetSuccess, loadAssetResult = pcall(InsertService.LoadAsset, InsertService, bundledItem.Id)
		if not loadAssetSuccess then
			fetchingFailed(loadAssetResult)
			return
		end

		local animation = loadAssetResult:FindFirstChildWhichIsA("Animation", true)
		if animation then
			local animationIdNumber = tonumber(string.match(animation.AnimationId, "%d+"))

			if animationIdNumber then
				itemsAssetIds[itemIndex] = {
					Type = "Animation",
					Id = bundledItem.Id,
					AnimationId = animationIdNumber,
				}
			else
				itemsAssetIds[itemIndex] = {
					Type = "Asset",
					Id = bundledItem.Id,
				}
			end
		else
			itemsAssetIds[itemIndex] = {
				Type = "Asset",
				Id = bundledItem.Id,
			}
		end

		loadAssetResult:Destroy()
	end

	local cachedDetails: Types.BundleDetails = {
		Id = result.Id,
		Price = result.Price or 0,
		IsOffSale = not result.IsPurchasable,

		Name = result.Name or "",

		Items = itemsAssetIds,
	}
	DubitUtils.Table.deepFreeze(cachedDetails)

	ItemDetails.data.BundleLastUpdated[result.Id] = os.time()

	ItemDetails.cache.CacheBundleDetails(cachedDetails)

	bundleQueue.QueuedItems[bundleId] = nil
end

function ItemDetails.private.QueryBundleDetails(bundleId: number)
	local cachedDetails = ItemDetails.cache.GetBundleData(bundleId)
	if cachedDetails then
		return
	end

	local bundleQueue = ItemDetails.data.BundleQueue
	if bundleQueue.QueuedItems[bundleId] then
		return
	end

	bundleQueue.QueuedItems[bundleId] = true
	bundleQueue.QueriesStack:pushLast(bundleId)
end

function ItemDetails.private.QueryAssetDetails(assetId: number)
	ItemDetails.data.AssetUsedThisSession[assetId] = true

	local cachedDetails = ItemDetails.cache.GetAssetData(assetId)
	-- checking if item exsits and if it's not stale, then we don't want to query any details
	if cachedDetails and os.time() - ItemDetails.data.AssetLastUpdated[assetId] < STALE_ITEM_TIME then
		return
	end

	local assetQueue = ItemDetails.data.AssetQueue
	if assetQueue.QueuedItems[assetId] then
		return
	end

	local batch = assetQueue.BatchesStack:peekLast()
	if not batch or batch.QueriesCount >= 100 then -- 100 is a max value for AvatarEditorService:GetBatchItemDetails
		local newBatch = {
			GotModifiedLastFrame = false,
			QueryHoldFrames = 0,

			Queries = {},
			QueriesCount = 0,
		}
		batch = newBatch

		assetQueue.BatchesStack:pushLast(newBatch)
	end

	table.insert(batch.Queries, assetId)
	batch.QueriesCount += 1
	batch.GotModifiedLastFrame = true
	assetQueue.QueuedItems[assetId] = true
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

	MarketplaceService.PromptBundlePurchaseFinished:Connect(function(player: Player, itemId: number, success: boolean)
		if not success then
			return
		end

		if not ItemDetails.data.BundleOwnership[player] then
			return
		end

		ItemDetails.data.BundleOwnership[player][itemId] = true
		ItemDetails.public.OnBundleOwnershipRetrieved:Fire(player, itemId, true)
	end)

	MarketplaceService.PromptPurchaseFinished:Connect(function(player: Player, itemId: number, success: boolean)
		if not success then
			return
		end

		if not ItemDetails.data.AssetOwnership[player] then
			return
		end

		ItemDetails.data.AssetOwnership[player][itemId] = true
		ItemDetails.public.OnAssetOwnershipRetrieved:Fire(player, itemId, true)
	end)

	RunService.Heartbeat:Connect(function(deltaTime: number)
		ItemDetails.cache.HeartbeatAccumulator += deltaTime
		ItemDetails.cache.UpdateTimeAccumulator += deltaTime

		if ItemDetails.cache.HeartbeatAccumulator >= CACHE_OWNERSHIP_HEARTBEAT then
			ItemDetails.cache.HeartbeatAccumulator = 0.00
			ItemDetails.cache.Heartbeat()
		end

		if ItemDetails.cache.UpdateTimeAccumulator >= CACHE_UPDATE_RATE then
			ItemDetails.cache.UpdateTimeAccumulator = 0.00
			ItemDetails.cache.Update()
		end

		if ItemDetails.cache.Status == "Master" then
			ItemDetails.cache.StaleUpdateAccumulator += deltaTime

			if ItemDetails.cache.StaleUpdateAccumulator >= STALE_ITEM_DATA_UPDATE_RATE then
				ItemDetails.cache.StaleUpdateAccumulator = 0.00
				ItemDetails.cache.ProcessStaleItems()
			end
		end

		ItemDetails.private.ProcessAssetDetailsQuerying()
		ItemDetails.private.ProcessBundleDetailsQuerying()
	end)

	task.spawn(function()
		ItemDetails.cache.Update()
		ItemDetails.cache.Heartbeat()
	end)
end

function ItemDetails.public.IsAssetOwned(player: Player, assetId: number): boolean
	local playerAssetOwnershipCache = ItemDetails.data.AssetOwnership[player]
	if not playerAssetOwnershipCache then
		return false
	end

	local pendingRequests = ItemDetails.data.AssetOwnershipPending[player]
	while pendingRequests[assetId] do
		task.wait()
	end

	if playerAssetOwnershipCache[assetId] then
		return playerAssetOwnershipCache[assetId]
	end

	pendingRequests[assetId] = true

	-- TODO: Improve it by having MarketplaceService limited to X amount of queries per minute
	local playerOwnsItem = ItemDetails.private.QueryMarketplaceService("PlayerOwnsAsset", player, assetId)
	playerAssetOwnershipCache[assetId] = playerOwnsItem

	ItemDetails.public.OnAssetOwnershipRetrieved:Fire(player, assetId, playerOwnsItem)

	pendingRequests[assetId] = nil

	return playerOwnsItem
end

function ItemDetails.public.IsAssetCached(assetId: number): boolean
	return ItemDetails.cache.GetAssetData(assetId) ~= nil
end

function ItemDetails.public.GetAssetDetails(assetId: number): Types.AssetDetails?
	local cachedDetails = ItemDetails.cache.GetAssetData(assetId)
	if cachedDetails then
		return cachedDetails
	end

	ItemDetails.private.QueryAssetDetails(assetId)

	local totalWaitTime = 0.00
	while not cachedDetails do
		cachedDetails = ItemDetails.cache.AssetCacheLookup[assetId]

		totalWaitTime += task.wait()
		if totalWaitTime >= QUERY_TIMEOUT then
			break
		end
	end

	return cachedDetails
end

function ItemDetails.public.GetAssetDetailsAsync(assetId: number, callback: (assetDetails: Types.AssetDetails?) -> ())
	task.spawn(callback, ItemDetails.public.GetAssetDetails(assetId))
end

function ItemDetails.public.PreloadAssetDetails(assetId: number)
	ItemDetails.private.QueryAssetDetails(assetId)
end

function ItemDetails.public.IsBundleOwned(player: Player, bundleId: number): boolean
	local playerBundleOwnershipCache = ItemDetails.data.BundleOwnership[player]
	if not playerBundleOwnershipCache then
		return false
	end

	local pendingRequests = ItemDetails.data.BundleOwnershipPending[player]
	while pendingRequests[bundleId] do
		task.wait()
	end

	if playerBundleOwnershipCache[bundleId] then
		return playerBundleOwnershipCache[bundleId]
	end

	pendingRequests[bundleId] = true

	-- TODO: Improve it by having MarketplaceService limited to X amount of queries per minute
	local playerOwnsItem = ItemDetails.private.QueryMarketplaceService("PlayerOwnsBundle", player, bundleId)
	playerBundleOwnershipCache[bundleId] = playerOwnsItem

	ItemDetails.public.OnBundleOwnershipRetrieved:Fire(player, bundleId, playerOwnsItem)

	pendingRequests[bundleId] = nil

	return playerOwnsItem
end

function ItemDetails.public.IsBundleCached(bundleId: number): boolean
	return ItemDetails.cache.GetBundleData(bundleId) ~= nil
end

function ItemDetails.public.GetBundleDetails(bundleId: number): Types.BundleDetails?
	local cachedDetails = ItemDetails.cache.GetBundleData(bundleId)
	if cachedDetails then
		return cachedDetails
	end

	ItemDetails.private.QueryBundleDetails(bundleId)

	local totalWaitTime = 0.00
	while not cachedDetails do
		cachedDetails = ItemDetails.cache.BundleCache[bundleId]

		totalWaitTime += task.wait()
		if totalWaitTime >= QUERY_TIMEOUT then
			break
		end
	end

	return cachedDetails
end

function ItemDetails.public.GetBundleDetailsAsync(
	bundleId: number,
	callback: (bundleDetails: Types.BundleDetails?) -> ()
)
	task.spawn(callback, ItemDetails.public.GetBundleDetails(bundleId))
end

function ItemDetails.public.PreloadBundleDetails(bundleId: number)
	ItemDetails.private.QueryBundleDetails(bundleId)
end

ItemDetails.private.Init()

export type ItemDetails = typeof(ItemDetails.public)

return ItemDetails.public
