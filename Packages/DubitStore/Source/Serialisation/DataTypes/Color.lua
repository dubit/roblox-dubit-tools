local function deserialiseColor3(object)
	return Color3.new(object.r, object.g, object.b)
end

local function serialiseColor3(object)
	return {
		r = object.R,
		g = object.G,
		b = object.B,
	}
end

return function(Serialisation)
	Serialisation:Implement("Color3", serialiseColor3, deserialiseColor3)
end
