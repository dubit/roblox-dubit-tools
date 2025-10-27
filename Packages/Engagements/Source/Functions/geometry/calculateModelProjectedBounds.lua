--[[
	Calculates the projected screen-space bounding box of a set of 3D corners.

	This function takes an array of Vector3 points (representing the corners of a 3D bounding box) and projects them
	onto the screen using the current camera. It returns the minimum and maximum X and Y coordinates of the projected
	bounding box in screen space.
]]
return function(corners: { Vector3 }): (number, number, number, number)
	local camera = workspace.CurrentCamera

	local projMinX, projMinY = math.huge, math.huge
	local projMaxX, projMaxY = -math.huge, -math.huge

	for _, corner in corners do
		local screenPoint = camera:WorldToViewportPoint(corner)

		projMinX = math.min(projMinX, screenPoint.X)
		projMinY = math.min(projMinY, screenPoint.Y)
		projMaxX = math.max(projMaxX, screenPoint.X)
		projMaxY = math.max(projMaxY, screenPoint.Y)
	end

	return projMinX, projMinY, projMaxX, projMaxY
end
