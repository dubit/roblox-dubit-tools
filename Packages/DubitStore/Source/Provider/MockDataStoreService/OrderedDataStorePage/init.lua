--[[
	OrderedDataStorePage - example of a DataStorePages object written in the form of a table

	https://create.roblox.com/docs/reference/engine/classes/DataStorePages
]]
--

local Sift = require(script.Parent.Parent.Parent.Parent.Sift)

local OrderedDataStorePage = {}

OrderedDataStorePage.prototype = {}
OrderedDataStorePage.interface = {}

--[[
	https://create.roblox.com/docs/reference/engine/classes/DataStorePages#AdvanceToNextPageAsync
]]
--
function OrderedDataStorePage.prototype:AdvanceToNextPageAsync()
	table.sort(self._keys, function(key0, key1)
		if self._ascending then
			return self._data[key1] > self._data[key0]
		else
			return self._data[key0] > self._data[key1]
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

		if self._minValue then
			if value < self._minValue then
				continue
			end
		end

		if self._maxValue then
			if value > self._maxValue then
				continue
			end
		end

		consumedIndex += 1
		table.insert(consumedValues, {
			key = key,
			value = value,
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
function OrderedDataStorePage.prototype:GetCurrentPage()
	return self._page
end

--[[
	from our datastore object we've created through tables.
]]
--
function OrderedDataStorePage.interface.fromDatastore(dataStore, ...)
	local data = {}

	for keyName, keyValue in dataStore._keys do
		data[keyName] = keyValue.data
	end

	return OrderedDataStorePage.interface.new(data, ...)
end

--[[
	constructor used to generate a new OrderedDataStorePage
]]
--
function OrderedDataStorePage.interface.new(data, ascending, pageSize, minValue, maxValue)
	local self = setmetatable({
		IsFinished = false,

		_ascending = ascending,
		_pageSize = pageSize,
		_minValue = minValue,
		_maxValue = maxValue,

		_page = {},
		_pageIndex = 0,
		_data = Sift.Dictionary.copy(data),
		_keys = Sift.Dictionary.keys(data),
	}, { __index = OrderedDataStorePage.prototype })

	self:AdvanceToNextPageAsync()

	return self
end

return OrderedDataStorePage.interface :: typeof(OrderedDataStorePage.interface)
