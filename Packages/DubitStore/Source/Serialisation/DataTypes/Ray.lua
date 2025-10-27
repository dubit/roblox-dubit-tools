local function deserialiseRay(object)
	return Ray.new(
		Vector3.new(object.origin.x, object.origin.y, object.origin.z),
		Vector3.new(object.direction.x, object.direction.y, object.direction.z)
	)
end

local function serialiseRay(object)
	return {
		origin = {
			x = object.Origin.X,
			y = object.Origin.Y,
			z = object.Origin.Z,
		},
		direction = {
			x = object.Direction.X,
			y = object.Direction.Y,
			z = object.Direction.Z,
		},
	}
end

return function(Serialisation)
	Serialisation:Implement("Ray", serialiseRay, deserialiseRay)
end
