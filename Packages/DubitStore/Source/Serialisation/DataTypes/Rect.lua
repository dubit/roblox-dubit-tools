local function deserialiseRect(object)
	return Rect.new(object.min.x, object.min.y, object.max.x, object.max.y)
end

local function serialiseRect(object)
	return {
		min = {
			x = object.Min.X,
			y = object.Min.Y,
		},
		max = {
			x = object.Max.X,
			y = object.Max.Y,
		},
	}
end

return function(Serialisation)
	Serialisation:Implement("Rect", serialiseRect, deserialiseRect)
end
