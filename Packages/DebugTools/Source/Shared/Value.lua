local Signal = require(script.Parent.Signal)

local Value = {}
Value.__index = Value

function Value.new(initialValue: any)
	local newValue = setmetatable({
		_value = initialValue,
		_changed = Signal.new(),
		__tostring = function(self)
			return "Value<" .. self._value .. ">"
		end,
	}, Value)

	return newValue
end

function Value:Observe(callback: (any) -> ())
	callback(self._value)
	return self._changed:Connect(callback)
end

function Value:Subscribe(callback: (any) -> ())
	return self._changed:Connect(callback)
end

function Value:Set(newValue: any, forceNotify: boolean?)
	if not forceNotify and newValue == self._value then
		return
	end

	self._value = newValue
	self._changed:Fire(newValue)
end

function Value:Get()
	return self._value
end

function Value:Destroy()
	self._changed:Destroy()
end

return Value
