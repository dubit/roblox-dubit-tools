local AvatarEditorService = game:GetService("AvatarEditorService")
local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local resume = require(script.Functions.resume)

local UGC_TOOLKIT_EQUIP_TAG = "Dubit_UgcToolkitAccessory"

local isInitialized = false

--[=[
	@class UgcToolkit
	@__index = internal

	The UGC Toolkit should be a suite/library of functions that enable developers to implement common functions that we
	normally assign the 3d podiums/UGCs in our experiences.

	To be clear, this package isn’t responsible for setting a UGC podium up, because this would require us creating a
	framework which is capable of handling all the edge cases, which falls out of scope for this package because it’s
	not a framework. 

	The implementation of a UGC podium is still up to the developer, this library just makes state/functionality
	surrounding this podium easier
]=]
local UgcToolkit = {}

UgcToolkit.internal = {}
UgcToolkit.interface = {}

UgcToolkit.cache = setmetatable({}, { __mode = "kv" })
UgcToolkit.equippedConnections = {} :: { [Player]: { [number]: { RBXScriptConnection } } }
UgcToolkit.assets = {} :: { [number]: Model }
UgcToolkit.queue = {}

UgcToolkit.queueSpeed = 60

UgcToolkit.queue.immediate = {} :: { [number]: () -> () }
UgcToolkit.queue.lazy = {} :: { [number]: () -> () }

--[[
	Loads an asset from Roblox's asset system using the provided assetId. This function handles caching and queuing of
	asset loading requests to prevent duplicate loads and manage memory efficiently.
	
	If the asset is already loaded, it returns a clone of the cached asset. If the asset is currently being loaded, it
	yields until the load completes.
]]
function UgcToolkit.internal.LoadAsset(assetId: number): Model?
	while UgcToolkit.assets[assetId] == true do
		task.wait()
	end

	if UgcToolkit.assets[assetId] ~= true and UgcToolkit.assets[assetId] ~= nil then
		return UgcToolkit.assets[assetId]
	end

	UgcToolkit.assets[assetId] = true

	local thread = coroutine.running()

	table.insert(
		UgcToolkit.queue.immediate,
		coroutine.create(function()
			UgcToolkit.assets[assetId] = InsertService:LoadAsset(assetId)

			resume(thread, UgcToolkit.assets[assetId])
		end)
	)

	return (coroutine.yield() :: Model):Clone()
end

--[=[
	@within UgcToolkit
	@client
	@server

	Equips a UGC accessory to a player.
	
	This function handles loading the asset, setting up necessary connections for  character events, and attaching the
	accessory to the player's character.
	
	The function maintains connections in the UgcToolkit.equippedConnections table for proper cleanup.
]=]
function UgcToolkit.interface.Equip(player: Player, assetId: number)
	local assetModel = UgcToolkit.internal.LoadAsset(assetId)
	local accessory = assetModel:FindFirstChildOfClass("Accessory")

	assetModel.Parent = workspace

	assert(accessory ~= nil, `Accessory not found in assetId {assetId}`)

	accessory:AddTag(UGC_TOOLKIT_EQUIP_TAG)
	accessory:SetAttribute(`AssetId`, assetId)

	if not UgcToolkit.equippedConnections[player] then
		UgcToolkit.equippedConnections[player] = {}
	end

	if not UgcToolkit.equippedConnections[player][assetId] then
		UgcToolkit.equippedConnections[player][assetId] = {}
	end

	table.insert(
		UgcToolkit.equippedConnections[player][assetId],
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid"):AddAccessory(accessory:Clone())
		end)
	)

	table.insert(
		UgcToolkit.equippedConnections[player][assetId],
		player.CharacterAppearanceLoaded:Connect(function(character)
			character:WaitForChild("Humanoid"):AddAccessory(accessory:Clone())
		end)
	)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:AddAccessory(accessory:Clone())
	end
end

--[=[
	@within UgcToolkit
	@client
	@server

	Unequips a UGC accessory from a player.

	This function handles cleaning up connections and removing accessories from the player's character. If an assetId
	is provided, only that specific accessory will be unequipped. Otherwise, all UGC accessories will be unequipped.
]=]
function UgcToolkit.interface.Unequip(player: Player, assetId: number?)
	if assetId and UgcToolkit.equippedConnections[player] then
		if UgcToolkit.equippedConnections[player][assetId] then
			for _, connection in UgcToolkit.equippedConnections[player][assetId] do
				connection:Disconnect()
			end

			UgcToolkit.equippedConnections[player][assetId] = nil
		end
	elseif UgcToolkit.equippedConnections[player] then
		for _, connections in UgcToolkit.equippedConnections[player] do
			for _, connection in connections do
				connection:Disconnect()
			end
		end

		UgcToolkit.equippedConnections[player] = nil
	end

	for _, object in CollectionService:GetTagged(UGC_TOOLKIT_EQUIP_TAG) do
		if object.Parent ~= player.Character then
			continue
		end

		if assetId then
			local objectAssetId = object:GetAttribute(`AssetId`)

			if assetId ~= objectAssetId then
				continue
			end
		end

		object:Destroy()
	end
end

--[=[
	@within UgcToolkit
	@client

	Adds the specified asset to the player's favorites list in the Avatar Editor.

	Returns true if the favorite operation was successful, false otherwise.
]=]
function UgcToolkit.interface.Favourite(assetId: number): boolean
	AvatarEditorService:PromptSetFavorite(assetId, Enum.AvatarItemType.Asset, true)

	local result = AvatarEditorService.PromptSetFavoriteCompleted:Wait()

	return result == Enum.AvatarPromptResult.Success
end

--[=[
	@within UgcToolkit
	@client

	Removes the specified asset from the player's favorites list in the Avatar Editor.

	Returns true if the unfavorite operation was successful, false otherwise.
]=]
function UgcToolkit.interface.Unfavourite(assetId: number): boolean
	AvatarEditorService:PromptSetFavorite(assetId, Enum.AvatarItemType.Asset, false)

	local result = AvatarEditorService.PromptSetFavoriteCompleted:Wait()

	return result == Enum.AvatarPromptResult.Success
end

--[=[
	@within UgcToolkit
	@client
	@server

	Prompts the specified player to purchase an asset and waits for their response. Returns true if the purchase was 
	successful, false otherwise. This function will block until the target player completes or cancels the purchase prompt.
]=]
function UgcToolkit.interface.Purchase(targetPlayer: Player, targetAssetId: number)
	MarketplaceService:PromptPurchase(targetPlayer, targetAssetId)

	local player, assetId, isPurchased = MarketplaceService.PromptPurchaseFinished:Wait()

	while player ~= targetPlayer and assetId ~= targetAssetId do
		player, assetId, isPurchased = MarketplaceService.PromptPurchaseFinished:Wait()
	end

	return isPurchased
end

--[=[
	@within UgcToolkit
	@client
	@server

	Loads and returns a Model asset from Roblox's asset catalog using the provided asset ID.
	
	This function handles the  asynchronous loading of the asset and returns nil if the asset cannot be loaded or is
	not a valid Model.
]=]
function UgcToolkit.interface.QueryAsset(targetAssetId: number): Model?
	return UgcToolkit.internal.LoadAsset(targetAssetId)
end

--[=[
	@within UgcToolkit
	@client
	@server

	Returns the remaining quantity of a specific asset in the Roblox catalog. If the asset information is cached, returns
	the cached value.
	
	Otherwise, queries the MarketplaceService asynchronously and caches the result before returning.
]=]
function UgcToolkit.interface.QueryRemaining(targetAssetId: number): number?
	if UgcToolkit.cache[targetAssetId] then
		return UgcToolkit.cache[targetAssetId]
	end

	local thread = coroutine.running()

	table.insert(
		UgcToolkit.queue.lazy,
		coroutine.create(function()
			local data = MarketplaceService:GetProductInfo(targetAssetId, Enum.InfoType.Asset)

			UgcToolkit.cache[targetAssetId] = data.Remaining

			resume(thread, UgcToolkit.cache[targetAssetId])
		end)
	)

	return coroutine.yield()
end

--[=[
	@within UgcToolkit
	@client
	@server

	Sets the speed at which lazy queue items are processed in the UgcToolkit system.
	
	This value determines the time interval between processing batches of lazy queue operations, allowing for better
	performance management and control over resource utilization.
]=]
function UgcToolkit.interface.SetQuerySpeed(targetSpeed: number)
	UgcToolkit.queueSpeed = targetSpeed
end

--[=[
	@within UgcToolkit

	Initializes the UgcToolkit package by setting up necessary event listeners and tracking systems.

	:::caution
	The UgcToolkit package initializes itself automatically. Developers requiring this module do not need to call this
	function.
	:::
]=]
function UgcToolkit.interface.Initialize()
	if isInitialized then
		assert(isInitialized == false, `UgcToolkit package is already initialised!`)
	else
		isInitialized = true
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		UgcToolkit.interface.Unequip(player)
	end)

	local delta = os.clock()

	while true do
		while #UgcToolkit.queue.immediate > 0 do
			local thread = table.remove(UgcToolkit.queue.immediate, 1)

			resume(thread)
		end

		if os.clock() - delta > UgcToolkit.queueSpeed then
			while #UgcToolkit.queue.lazy > 0 do
				local thread = table.remove(UgcToolkit.queue.lazy, 1)

				resume(thread)
			end

			delta = os.clock()
		end

		RunService.Heartbeat:Wait()
	end
end

return UgcToolkit.interface
