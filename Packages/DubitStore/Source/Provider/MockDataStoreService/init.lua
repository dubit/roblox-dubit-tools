--[[
	MockDataStoreService - an hacky implementation of the Roblox Data Store service. This module doesn't cover all datastore functionaly.
]]
--

local MockDataStoreService = {}

local DataStoreObject = require(script.DataStoreObject)
local OrderedDataStorePage = require(script.OrderedDataStorePage)
local VersionDataStorePage = require(script.VersionDataStorePage)

MockDataStoreService.interface = {}
MockDataStoreService.datastores = {}
MockDataStoreService.defaultBudgets = {
	[Enum.DataStoreRequestType.GetAsync] = 2500,
	[Enum.DataStoreRequestType.GetSortedAsync] = 2500,
	[Enum.DataStoreRequestType.SetIncrementAsync] = 2500,
	[Enum.DataStoreRequestType.SetIncrementSortedAsync] = 2500,
	[Enum.DataStoreRequestType.UpdateAsync] = 2500,
}

--[[
	getting the default budget for each datastore request type.
]]
--
function MockDataStoreService.interface:GetRequestBudgetForRequestType(DataStoreRequestType)
	return MockDataStoreService.defaultBudgets[DataStoreRequestType]
end

--[[
	fetching an offline datastore object, in our case it'll be a table which'll simulate the same behaviour as a datastore object.
]]
--
function MockDataStoreService.interface:GetDataStore(datastoreIdentifier)
	if MockDataStoreService.datastores[datastoreIdentifier] then
		return MockDataStoreService.datastores[datastoreIdentifier]
	else
		local DataStore = DataStoreObject.new(datastoreIdentifier)

		DataStore.ClassName = "DataStore"

		-- we're creating a new DataStore object, then writing in the functions that only the 'OrderedDataStore' class have

		function DataStore.ListVersionsAsync(object, sortDirection, minDate, maxDate, pageSize)
			assert(object == DataStore, "Expected : instead of . when calling :ListVersionsAsync()")

			return VersionDataStorePage.fromDatastore(DataStore, sortDirection, minDate, maxDate, pageSize)
		end

		MockDataStoreService.datastores[datastoreIdentifier] = DataStore

		return MockDataStoreService.datastores[datastoreIdentifier]
	end
end

--[[
	fetching an offline ordered datastore object, in our case it'll be a table which'll simulate the same behaviour as a datastore object.
]]
--
function MockDataStoreService.interface:GetOrderedDataStore(datastoreIdentifier)
	if MockDataStoreService.datastores[datastoreIdentifier] then
		return MockDataStoreService.datastores[datastoreIdentifier]
	else
		local DataStore = DataStoreObject.new(datastoreIdentifier)

		DataStore.ClassName = "OrderedDataStore"

		-- we're creating a new DataStore object, then writing in the functions that only the 'DataStore' class have

		function DataStore.GetSortedAsync(object, ascending, pageSize, minValue, maxValue)
			assert(object == DataStore, "Expected : instead of . when calling :GetSortedAsync()")

			return OrderedDataStorePage.fromDatastore(DataStore, ascending, pageSize, minValue, maxValue)
		end

		MockDataStoreService.datastores[datastoreIdentifier] = DataStore

		return MockDataStoreService.datastores[datastoreIdentifier]
	end
end

return MockDataStoreService.interface :: typeof(MockDataStoreService.interface)
