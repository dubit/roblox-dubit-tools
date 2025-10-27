local function deserialiseVector2(object)
	return Vector2.new(object.x, object.y)
end

local function serialiseVector2(object)
	return {
		x = object.X,
		y = object.Y,
	}
end

local function deserialiseVector3(object)
	return Vector3.new(object.x, object.y, object.z)
end

local function serialiseVector3(object)
	return {
		x = object.X,
		y = object.Y,
		z = object.Z,
	}
end

return function(Serialisation)
	Serialisation:Implement("Vector3", serialiseVector3, deserialiseVector3)
	Serialisation:Implement("Vector3int16", serialiseVector3, deserialiseVector3)

	Serialisation:Implement("Vector2", serialiseVector2, deserialiseVector2)
	Serialisation:Implement("Vector2int16", serialiseVector2, deserialiseVector2)
end
