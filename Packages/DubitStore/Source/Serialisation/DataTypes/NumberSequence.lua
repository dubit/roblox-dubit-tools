local function deserialiseNumberSequenceKeypoint(object)
	return NumberSequenceKeypoint.new(object.time, object.value, object.envelope)
end

local function serialiseNumberSequenceKeypoint(object)
	return {
		time = object.Time,
		value = object.Value,
		envelope = object.Envelope,
	}
end

local function deserialiseNumberSequence(object)
	local deserialisedKeypoints = {}

	for index, value in object.keypoints do
		deserialisedKeypoints[index] = deserialiseNumberSequenceKeypoint(value)
	end

	return NumberSequence.new(deserialisedKeypoints)
end

local function serialiseNumberSequence(object)
	local serialisedObject = {
		keypoints = {},
	}

	for index, value in object.Keypoints do
		serialisedObject.keypoints[index] = serialiseNumberSequenceKeypoint(value)
	end

	return serialisedObject
end

return function(Serialisation)
	Serialisation:Implement("NumberSequence", serialiseNumberSequence, deserialiseNumberSequence)
	Serialisation:Implement(
		"NumberSequenceKeypoint",
		serialiseNumberSequenceKeypoint,
		deserialiseNumberSequenceKeypoint
	)
end
