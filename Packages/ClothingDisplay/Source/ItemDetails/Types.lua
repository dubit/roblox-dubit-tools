local Signal = require(script.Parent.Parent.Parent.Signal)

type Signal = typeof(Signal.new())

export type BundleAsset = {
	Type: "Asset",

	Id: number,
}

export type BundleAnimation = {
	Type: "Animation",

	Id: number,
	AnimationId: number,
}

export type AssetDetails = {
	Id: number,
	Price: number,
	IsOffSale: boolean,
	AssetType: Enum.AssetType,

	Name: string,

	Limited: {
		IsUnique: boolean,
		IsReselling: boolean,

		LowestResalePrice: number?,
		Remaining: number?,
		TotalQuantity: number?,
	}?,

	-- TODO: Implement PremiumPricing field
	-- PremiumPricing: { -- if assetDetails.PremiumPricing ~= nil
	-- 	Discount: number, -- assetDetails.PremiumPricing.PremiumDiscountPercentage
	-- 	Price: number, -- assetDetails.PremiumPricing.PremiumPriceInRobux
	-- },
}

export type BundleDetails = {
	Id: number,
	Price: number,
	IsOffSale: boolean,

	Name: string?,

	Items: { BundleAsset | BundleAnimation },
}

export type ItemDetails = {
	IsAssetOwned: (player: Player, assetId: number) -> boolean,
	IsAssetCached: (assetId: number) -> boolean,
	GetAssetDetails: (assetId: number) -> AssetDetails?,
	GetAssetDetailsAsync: (assetId: number, callback: (assetDetails: AssetDetails?) -> ()) -> (),
	PreloadAssetDetails: (assetId: number) -> (),

	IsBundleOwned: (player: Player, bundleId: number) -> boolean,
	IsBundleCached: (bundleId: number) -> boolean,
	GetBundleDetails: (bundleId: number) -> BundleDetails?,
	GetBundleDetailsAsync: (bundleId: number, callback: (bundleDetails: BundleDetails?) -> ()) -> (),
	PreloadBundleDetails: (bundleId: number) -> (),

	OnAssetDataRetrieved: Signal,
	OnBundleDataRetrieved: Signal,

	OnAssetOwnershipRetrieved: Signal,
	OnBundleOwnershipRetrieved: Signal,
}

return nil
