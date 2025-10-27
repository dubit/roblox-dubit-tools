--[[
	Retrieves the corner coordinates of a model's bounding box in world space.

	This function takes a model, calculates its bounding box using its CFrame and size, and then computes the eight
	corner points of the bounding box. These corner points are returned as a list of Vector3 positions in world space. 

	These corners are essential for various geometric calculations, including determining if the model is on screen,
	calculating visible areas, or projecting the model's size onto the screen.
]]
return function(model: Model): { Vector3 }
	local boxCFrame, boxSize = model:GetBoundingBox()
	local halfSize = boxSize * 0.5

	return {
		boxCFrame * Vector3.new(halfSize.X, halfSize.Y, halfSize.Z),
		boxCFrame * Vector3.new(halfSize.X, halfSize.Y, -halfSize.Z),
		boxCFrame * Vector3.new(halfSize.X, -halfSize.Y, halfSize.Z),
		boxCFrame * Vector3.new(halfSize.X, -halfSize.Y, -halfSize.Z),
		boxCFrame * Vector3.new(-halfSize.X, halfSize.Y, halfSize.Z),
		boxCFrame * Vector3.new(-halfSize.X, halfSize.Y, -halfSize.Z),
		boxCFrame * Vector3.new(-halfSize.X, -halfSize.Y, halfSize.Z),
		boxCFrame * Vector3.new(-halfSize.X, -halfSize.Y, -halfSize.Z),
	}
end
