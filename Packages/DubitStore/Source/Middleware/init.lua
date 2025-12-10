local Middleware = {}

Middleware.interface = {}
Middleware.prototype = {}

Middleware.type = "Middleware"

Middleware.interface.action = table.freeze({
	Get = "Get",
	Set = "Set",
})

function Middleware.prototype:ToString()
	return `{Middleware.type}<{tostring(self._callback)}>`
end

function Middleware.prototype:Call(...)
	return self._callback(...)
end

function Middleware.interface.is(object)
	if typeof(object) ~= "table" then
		return false
	end

	local objectMetatable = getmetatable(object)

	return objectMetatable and objectMetatable.__type == Middleware.type
end

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
