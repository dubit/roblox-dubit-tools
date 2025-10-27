local function deserialiseUDim(object)
	return UDim2.new(object.scale, object.offset)
end

local function serialiseUDim(object)
	return {
		scale = object.Scale,
		offset = object.Offset,
	}
end

local function deserialiseUDim2(object)
	return UDim2.new(object.xScale, object.xOffset, object.yScale, object.yOffset)
end

local function serialiseUDim2(object)
	return {
		xScale = object.X.Scale,
		xOffset = object.X.Offset,
		yScale = object.Y.Scale,
		yOffset = object.Y.Offset,
	}
end

return function(Serialisation)
	Serialisation:Implement("UDim2", serialiseUDim2, deserialiseUDim2)
	Serialisation:Implement("UDim", serialiseUDim, deserialiseUDim)
end
