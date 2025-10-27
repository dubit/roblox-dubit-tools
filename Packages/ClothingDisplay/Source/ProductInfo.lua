-- !strict
local MarketplaceService = game:GetService("MarketplaceService")

local ProductInfo = {}
ProductInfo.public = {}
ProductInfo.cache = {}

function ProductInfo.public:Get(productID: number)
	if not ProductInfo.cache[productID] then
		ProductInfo.cache[productID] = MarketplaceService:GetProductInfo(productID)
	end

	return ProductInfo.cache[productID]
end

return ProductInfo.public
