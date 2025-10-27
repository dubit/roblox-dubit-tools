local function deserialiseRegion3int16(object)
	return Region3int16.new(
		Vector3int16.new(object.bottomCorner.x, object.bottomCorner.y, object.bottomCorner.z),
		Vector3int16.new(object.topCorner.x, object.topCorner.y, object.topCorner.z)
	)
end

local function serialiseRegion3int16(object)
	return {
		bottomCorner = {
			x = object.Min.X,
			y = object.Min.Y,
			z = object.Min.Z,
		},
		topCorner = {
			x = object.Max.X,
			y = object.Max.Y,
			z = object.Max.Z,
		},
	}
end

local function deserialiseRegion3(object)
	return Region3.new(
		Vector3.new(object.bottomCorner.x, object.bottomCorner.y, object.bottomCorner.z),
		Vector3.new(object.topCorner.x, object.topCorner.y, object.topCorner.z)
	)
end

local function serialiseRegion3(object)
	local bottomCorner = object.CFrame * CFrame.new(-object.Size)
	local topCorner = object.CFrame * CFrame.new(object.Size)

	return {
		bottomCorner = {
			x = bottomCorner.X,
			y = bottomCorner.Y,
			z = bottomCorner.Z,
		},
		topCorner = {
			x = topCorner.X,
			y = topCorner.Y,
			z = topCorner.Z,
		},
	}
end

return function(Serialisation)
	Serialisation:Implement("Region3", serialiseRegion3, deserialiseRegion3)
	Serialisation:Implement("Region3int16", serialiseRegion3int16, deserialiseRegion3int16)
end
