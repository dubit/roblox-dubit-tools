local function deserialiseColorSequenceKeypoint(object)
	return ColorSequenceKeypoint.new(object.time, Color3.new(object.color.r, object.color.g, object.color.b))
end

local function serialiseColorSequenceKeypoint(object)
	return {
		time = object.Time,
		color = {
			r = object.Value.R,
			g = object.Value.G,
			b = object.Value.B,
		},
	}
end

local function deserialiseColorSequence(object)
	local deserialisedKeypoints = {}

	for index, value in object.keypoints do
		deserialisedKeypoints[index] = deserialiseColorSequenceKeypoint(value)
	end

	return ColorSequence.new(deserialisedKeypoints)
end

local function serialiseColorSequence(object)
	local serialisedObject = {
		keypoints = {},
	}

	for index, value in object.Keypoints do
		serialisedObject.keypoints[index] = serialiseColorSequenceKeypoint(value)
	end

	return serialisedObject
end

return function(Serialisation)
	Serialisation:Implement("ColorSequence", serialiseColorSequence, deserialiseColorSequence)
	Serialisation:Implement("ColorSequenceKeypoint", serialiseColorSequenceKeypoint, deserialiseColorSequenceKeypoint)
end
