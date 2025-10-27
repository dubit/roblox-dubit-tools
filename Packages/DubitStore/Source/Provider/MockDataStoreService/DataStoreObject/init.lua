--[[
	DataStoreObject - example of a DataStore object written in the form of a table

	https://create.roblox.com/docs/reference/engine/classes/DataStore
]]
--

local HttpService = game:GetService("HttpService")

local DataKeyInfoObject = require(script.Parent.DataKeyInfoObject)

local DataStoreObject = {}

DataStoreObject.prototype = {}
DataStoreObject.interface = {}

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStore#RemoveAsync
]]
--
function DataStoreObject.prototype:Remove(key)
	if not self._keys[key] then
		return
	end

	self._keys[key].data = nil
end

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStore#UpdateAsync
]]
--
function DataStoreObject.prototype:Update(key, transformFunction)
	if not self._keys[key] then
		self._keys[key] = {}
		self._keys[key].keyInfo = DataKeyInfoObject.new(0)
	end

	local newVersion = HttpService:GenerateGUID(false)
	local dateTime = DateTime.now()

	local data, userIds, metadata = transformFunction(self._keys[key].data, self._keys[key].keyInfo)

	self._keys[key].data = data
	self._keys[key].keyInfo = DataKeyInfoObject.from(self._keys[key].keyInfo, newVersion, userIds, metadata)

	table.insert(self._versionOrder, {
		key = key,
		version = newVersion,
		isDeleted = false,
		createdTime = dateTime.UnixTimestampMillis,
	})

	self._versions[newVersion] = {
		key = key,
		data = self._keys[key].data,
		keyInfo = self._keys[key].keyInfo,
	}

	return data, self._keys[key].keyInfo
end

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStore#GetAsync
]]
--
function DataStoreObject.prototype:Get(key)
	if not self._keys[key] then
		return
	end

	return self._keys[key].data, self._keys[key].keyInfo
end

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStore#GetVersionAsync
]]
--
function DataStoreObject.prototype:GetVersion(_, version)
	if not self._versions[version] then
		return
	end

	return self._versions[version].data, self._versions[version].keyInfo
end

--[[
	constructor used to generate a new DataStoreObject
]]
--
function DataStoreObject.interface.new(source)
	return setmetatable({
		_keys = {},
		_versions = {},
		_versionOrder = {},
		Name = source,
	}, { __index = DataStoreObject.prototype })
end

return DataStoreObject.interface :: typeof(DataStoreObject.interface)
