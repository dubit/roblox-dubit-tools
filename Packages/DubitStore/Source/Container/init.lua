--[[
	Roblox Data Container
]]
--

--[=[
	@class Container

	Containers are objects that contain a value, the object will then provide quality of life functions for manipulating this value.
]=]
--

local Container = {}

Container.type = "Container"

Container.interface = {}
Container.prototype = {}

--[=[
	This function generates a string that shows the following; Container Type, Allocated Data Type, Allocated Data Value.

	@method ToString
	@within Container

	@return string
]=]
--
function Container.prototype:ToString()
	return `{Container.type}<{typeof(self._allocated)}<{tostring(self._allocated)}>>`
end

--[=[
	This function returns the allocated Data Value.

	@method ToValue
	@within Container

	@return any
]=]
--
function Container.prototype:ToValue()
	return self._allocated
end

--[=[
	This function returns the type of the allocated Data Value

	@method ToDataType
	@within Container

	@return string
]=]
--
function Container.prototype:ToDataType()
	return typeof(self._allocated)
end

--[=[
	This function compares the first parameter to the class 'Container'

	@function is
	@within Container

	@param object? Container?
	@return boolean
]=]
--
function Container.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == Container.type
end

--[=[
	This function constructs a new 'Container' class

	@function new
	@within Container

	@param data any
	@return Container
]=]
--
function Container.interface.new(data)
	local self = setmetatable({
		_allocated = data,
	}, {
		__type = Container.type,
		__index = Container.prototype,
		__tostring = function(object)
			return object:ToString()
		end,
	})

	return self
end

return Container.interface :: typeof(Container.interface) & {}
