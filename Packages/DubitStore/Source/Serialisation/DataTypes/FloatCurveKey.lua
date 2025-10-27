local function deserialiseFloatCurveKey(object)
	return FloatCurveKey.new(object.time, object.value, Enum.KeyInterpolationMode[object.interpolation])
end

local function serialiseFloatCurveKey(object)
	return {
		time = object.Time,
		value = object.Value,
		interpolation = object.Interpolation.Name,
	}
end

return function(Serialisation)
	Serialisation:Implement("FloatCurveKey", serialiseFloatCurveKey, deserialiseFloatCurveKey)
end
