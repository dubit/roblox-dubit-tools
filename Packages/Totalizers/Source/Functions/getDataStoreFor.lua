--[[
	Will return the DataStore that the Totalizers will use.
]]
local DataStoreService = game:GetService("DataStoreService")

local Package = script.Parent.Parent

local isOffline = require(Package.Functions.isOffline)

return function(): DataStore?
	if isOffline() then
		return
	end

	local dataStore = DataStoreService:GetDataStore(`Dubit_Totalizers`)

	return dataStore
end
