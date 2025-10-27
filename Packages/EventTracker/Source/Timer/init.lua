--[[
	Timer:
]]
--

local UTC = require(script.Parent.UTC)

--[=[
	@class Timer

	The 'Timer' class is an internal class that helps to track the time left before the start or end of an event occurs.
]=]
local Timer = {}

Timer.type = "Timer"

Timer.interface = {}
Timer.prototype = {}

--[=[
	This function will let developers know if we've passed the UTC target, then causing the Timer to expire

	@method IsExpired
	@within Timer

	@return number
]=]
--
function Timer.prototype:IsExpired()
	return self._utcObject:GetEpochTime() - UTC.now():GetEpochTime() <= 0
end

--[=[
	This function will return the time required to hit the UTC target

	@method GetDeltaTime
	@within Timer

	@return number
]=]
--
function Timer.prototype:GetDeltaTime()
	return self._utcObject:GetEpochTime() - UTC.now():GetEpochTime()
end

--[=[
	This function generates a string that shows the following; Timer Type, UTC

	@method ToString
	@within Timer

	@return string
]=]
--
function Timer.prototype:ToString()
	return `{Timer.type}<{tostring(self._utcObject)}>`
end

--[=[
	This function will return the current state of the Timer, weather or ot it is active.

	@method IsActive
	@within Timer

	@return boolean
]=]
--
function Timer.prototype:IsActive()
	return self.isActive or false
end

--[=[
	This function constructs a new 'Timer' class

	@function new
	@within Timer

	@param expirationUTC UTC

	@return Timer
]=]
--
function Timer.interface.new(expirationUTC)
	local self = setmetatable({}, {
		__type = Timer.type,
		__index = Timer.prototype,
		__tostring = function(obj)
			return obj:ToString()
		end,
	})

	self._utcObject = expirationUTC

	return self
end

--[=[
	This function compares the first parameter to the 'Timer' class

	@function is
	@within Timer

	@param object Timer?

	@return boolean
]=]
--
function Timer.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == Timer.type
end

return Timer.interface
