local function deserialiseNumberRange(object)
	return NumberRange.new(object.min, object.max)
end

local function serialiseNumberRange(object)
	return {
		min = object.Min,
		max = object.Max,
	}
end

return function(Serialisation)
	Serialisation:Implement("NumberRange", serialiseNumberRange, deserialiseNumberRange)
end
