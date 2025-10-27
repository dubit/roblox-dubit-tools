--[[
	DataKeyInfoObject - example of a DataStoreKeyInfo object written in the form of a table

	https://create.roblox.com/docs/reference/engine/classes/DataStoreKeyInfo
]]
--

local DataKeyInfoObject = {}

DataKeyInfoObject.prototype = {}
DataKeyInfoObject.interface = {}

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStoreKeyInfo#GetMetadata
]]
--
function DataKeyInfoObject.prototype:GetMetadata()
	return self._metadata
end

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStoreKeyInfo#GetUserIds
]]
--
function DataKeyInfoObject.prototype:GetUserIds()
	return self._userIds
end

--[[
	from our datastore object we've created through tables.
]]
--
function DataKeyInfoObject.interface.from(keyInfo, version, userIds, metadata)
	local dataStoreKey = DataKeyInfoObject.interface.new(version, userIds, metadata)

	dataStoreKey.CreatedTime = keyInfo.CreatedTime

	return dataStoreKey
end

--[[
	constructor used to generate a new DataKeyInfoObject
]]
--
function DataKeyInfoObject.interface.new(version, userIds, metadata)
	local dateTime = DateTime.now()

	return setmetatable({
		CreatedTime = dateTime.UnixTimestampMillis,
		UpdatedTime = dateTime.UnixTimestampMillis,
		Version = version,

		_userIds = userIds or {},
		_metadata = metadata or {},
	}, { __index = DataKeyInfoObject.prototype })
end

return DataKeyInfoObject.interface :: typeof(DataKeyInfoObject.interface)
