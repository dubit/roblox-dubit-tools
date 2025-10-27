local function deserialiseFaces(object)
	local trueNormalIds = {}

	for _, value in object.normalIds do
		table.insert(trueNormalIds, Enum.NormalId[value])
	end

	return Faces.new(table.unpack(trueNormalIds))
end

local function serialiseFaces(object)
	local serialisedObject = {
		normalIds = {},
	}

	if object.Top then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Top.Name)
	end

	if object.Bottom then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Bottom.Name)
	end

	if object.Top then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Top.Name)
	end

	if object.Left then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Left.Name)
	end

	if object.Right then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Right.Name)
	end

	if object.Back then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Back.Name)
	end

	if object.Front then
		table.insert(serialisedObject.normalIds, Enum.NormalId.Front.Name)
	end

	return serialisedObject
end

return function(Serialisation)
	Serialisation:Implement("Faces", serialiseFaces, deserialiseFaces)
end
