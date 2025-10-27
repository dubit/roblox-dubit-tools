--[[
	Roblox Middleware
]]
--

--[=[
	@class Middleware

	Middleware represents an object that we can create to help transform an input into something else we can use.
]=]
--
local Middleware = {}

Middleware.interface = {}
Middleware.prototype = {}

Middleware.type = "Middleware"

--[=[
	@prop action MiddlewareActionType
	@within Middleware
]=]
--
Middleware.interface.action = table.freeze({
	Get = "Get",
	Set = "Set",
})

--[=[
	This function generates a string that shows the following; Middleware Type, Allocated Data Type, Allocated Data Value.

	@method ToString
	@within Middleware

	@return string
]=]
--
function Middleware.prototype:ToString()
	return `{Middleware.type}<{tostring(self._callback)}>`
end

--[=[
	insert_class_comment

	@method Call
	@within Middleware
	@param ... ...any

	@return ...
]=]
--
function Middleware.prototype:Call(...)
	return self._callback(...)
end

--[=[
	This function compares the first parameter to the 'Middleware' class

	@function is
	@within Middleware

	@param object? Middleware?
	@return boolean
]=]
--
function Middleware.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == Middleware.type
end

--[=[
	This function constructs a new 'Middleware' class

	@function new
	@within Middleware

	@param callback (...) -> ...
	@return Middleware
]=]
--
function Middleware.interface.new(callback)
	local self = setmetatable({
		_callback = callback,
	}, {
		__type = Middleware.type,
		__index = Middleware.prototype,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	return self
end

return Middleware.interface :: typeof(Middleware.interface)
