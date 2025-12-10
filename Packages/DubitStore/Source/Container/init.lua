local Container = {}

Container.type = "Container"

Container.interface = {}
Container.prototype = {}

function Container.prototype:ToString()
	return `{Container.type}<{typeof(self._allocated)}<{tostring(self._allocated)}>>`
end

function Container.prototype:ToValue()
	return self._allocated
end

function Container.prototype:ToDataType()
	return typeof(self._allocated)
end

function Container.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == Container.type
end

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
