--[[
	UTC: 
]]
--

--[=[
	@class UTC
]=]
local UTC = {}

UTC.interface = {}
UTC.prototype = {}
UTC.internal = {}

UTC.type = "UTC"

UTC.cache = setmetatable({}, { __mode = "kv" })

--[=[
	This function will return the epoch time with an UTC offset applied.

	@method GetEpochTime
	@within UTC

	@return number
]=]
--
function UTC.prototype:GetEpochTime()
	return self._epoch - (self._offset and self._offset or 0)
end

--[=[
	This function will apply a UTC offset to the epoch.

	@method SetUTCOffset
	@within UTC

	@param offset number

	@return UTC
]=]
--
function UTC.prototype:SetUTCOffset(offset)
	self._offset = offset

	return self
end

--[=[
	This function generates a string that shows the following; UTC Type, Epoch

	@method ToString
	@within UTC

	@return string
]=]
--
function UTC.prototype:ToString()
	return `{UTC.type}<{self._epoch}>`
end

--[=[
	This function constructs a new 'UTC' class

	@function new
	@within UTC

	@param dateTable {Year: number, Month: number, Day: number, Hour: number, Minute: number, Second: number}

	@return UTC
]=]
--
function UTC.interface.new(dateTable)
	assert(dateTable.Year, `Expected 'Year' field in 'dataTable' parameter`)
	assert(dateTable.Month, `Expected 'Month' field in 'dataTable' parameter`)
	assert(dateTable.Day, `Expected 'Day' field in 'dataTable' parameter`)
	assert(dateTable.Hour, `Expected 'Hour' field in 'dataTable' parameter`)
	assert(dateTable.Minute, `Expected 'Minute' field in 'dataTable' parameter`)
	assert(dateTable.Second, `Expected 'Second' field in 'dataTable' parameter`)

	local self = setmetatable({}, {
		__type = UTC.type,
		__index = UTC.prototype,
		__tostring = function(obj)
			return obj:ToString()
		end,
	})

	self._epoch = DateTime.fromUniversalTime(
		dateTable.Year,
		dateTable.Month,
		dateTable.Day,
		dateTable.Hour,
		dateTable.Minute,
		dateTable.Second
	).UnixTimestamp

	return self
end

--[=[
	This function constructs a new 'UTC' class from an unix timestamp

	@function from
	@within UTC

	@param epoch number

	@return UTC
]=]
--
function UTC.interface.from(epoch)
	local self = setmetatable({}, {
		__type = UTC.type,
		__index = UTC.prototype,
		__tostring = function(obj)
			return obj:ToString()
		end,
	})

	self._epoch = epoch

	return self
end

--[=[
	This function compares the first parameter to the 'Event' class

	@function is
	@within UTC

	@param object? UTC?
	@return boolean
]=]
--
function UTC.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == UTC.type
end

--[=[
	This function returns the current UTC time.

	@function now
	@within UTC

	@return UTC
]=]
--
function UTC.interface.now()
	if UTC.cache[UTC.currentTimeEpoch] then
		return UTC.cache[UTC.currentTimeEpoch]
	end

	UTC.cache[UTC.currentTimeEpoch] = UTC.interface.from(UTC.currentTimeEpoch)

	return UTC.cache[UTC.currentTimeEpoch]
end

function UTC:Initiate()
	task.spawn(function()
		UTC.currentTimeEpoch = os.time(os.date("!*t"))

		while task.wait(1) do
			UTC.currentTimeEpoch = os.time(os.date("!*t"))
		end
	end)

	return UTC.interface
end

return UTC:Initiate()
