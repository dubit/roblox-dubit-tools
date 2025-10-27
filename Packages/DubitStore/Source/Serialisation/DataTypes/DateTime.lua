local function deserialiseDateTime(object)
	return DateTime.fromIsoDate(object.iso)
end

local function serialiseDateTime(object)
	return {
		iso = object:ToIsoDate(),
	}
end

return function(Serialisation)
	Serialisation:Implement("DateTime", serialiseDateTime, deserialiseDateTime)
end
