local function deserialiseCFrame(object)
	return CFrame.new(table.unpack(object.components))
end

local function serialiseCFrame(object)
	return {
		components = { object:GetComponents() },
	}
end

return function(Serialisation)
	Serialisation:Implement("CFrame", serialiseCFrame, deserialiseCFrame)
end
