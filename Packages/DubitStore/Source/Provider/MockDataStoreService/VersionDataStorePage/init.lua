--[[
	VersionDataStorePage - example of a DataStoreVersionPages object written in the form of a table

	https://create.roblox.com/docs/reference/engine/classes/DataStoreVersionPages
]]
--

local Sift = require(script.Parent.Parent.Parent.Parent.Sift)

local VersionDataStorePage = {}

VersionDataStorePage.prototype = {}
VersionDataStorePage.interface = {}

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStorePages#AdvanceToNextPageAsync
]]
--
function VersionDataStorePage.prototype:AdvanceToNextPageAsync()
	table.sort(self._keys, function(key0, key1)
		if self._sortDirection == Enum.SortDirection.Ascending then
			return self._data[key1].createdTime > self._data[key0].createdTime
		else
			return self._data[key0].createdTime > self._data[key1].createdTime
		end
	end)

	local consumedValues = {}
	local consumedIndex = 0

	-- this loop has multiple break points, however the goal is to fill "consumedValues" with a set of information that'll populate our current page.
	-- this loop should last until the page size is met.
	while consumedIndex < self._pageSize do
		if self._pageIndex == #self._keys then
			self.IsFinished = true

			break
		end

		self._pageIndex += 1

		local key = self._keys[self._pageIndex]
		local value = key and self._data[key]

		if not key or not value then
			self.IsFinished = true

			break
		end

		if self._minDate then
			if value.createdTime < self._minDate then
				continue
			end
		end

		if self._maxDate then
			if value.createdTime > self._maxDate then
				continue
			end
		end

		consumedIndex += 1
		table.insert(consumedValues, {
			CreatedTime = value.createdTime,
			IsDeleted = value.isDeleted,
			Version = value.version,
		})
	end

	if self._pageIndex == #self._keys then
		self.IsFinished = true
	end

	self._page = consumedValues
end

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStorePages#GetCurrentPage
]]
--
function VersionDataStorePage.prototype:GetCurrentPage()
	return self._page
end

--[[
	from our datastore object we've created through tables.
]]
--
function VersionDataStorePage.interface.fromDatastore(dataStore, ...)
	return VersionDataStorePage.interface.new(dataStore._versionOrder, ...)
end

--[[
	constructor used to generate a new VersionDataStorePage
]]
--
function VersionDataStorePage.interface.new(data, sortDirection, minDate, maxDate, pageSize)
	local self = setmetatable({
		IsFinished = false,

		_sortDirection = sortDirection or Enum.SortDirection.Ascending,
		_pageSize = pageSize or 100,
		_minDate = minDate,
		_maxDate = maxDate,

		_page = {},
		_pageIndex = 0,
		_data = Sift.Dictionary.copy(data),
		_keys = Sift.Dictionary.keys(data),
	}, { __index = VersionDataStorePage.prototype })

	self:AdvanceToNextPageAsync()

	return self
end

return VersionDataStorePage.interface :: typeof(VersionDataStorePage.interface)
