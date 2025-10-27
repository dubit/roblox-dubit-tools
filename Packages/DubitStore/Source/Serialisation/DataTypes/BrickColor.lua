local function deserialiseBrickColor(object)
	return BrickColor.new(object.name)
end

local function serialiseBrickColor(object)
	return {
		name = object.Name,
	}
end

return function(Serialisation)
	Serialisation:Implement("BrickColor", serialiseBrickColor, deserialiseBrickColor)
end
