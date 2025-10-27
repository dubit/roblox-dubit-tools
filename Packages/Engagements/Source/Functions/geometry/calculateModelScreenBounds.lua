--[[
	Calculates the visible screen-space bounding box of a set of 3D corners.

	This function takes an array of Vector3 points (representing the corners of a 3D bounding box) and projects them
	onto the screen using the current camera. It determines the minimum and maximum X and Y coordinates of the
	projected bounding box, but only considers points that are actually visible on the screen.

	If none of the corners are visible, the function returns nil.
]]
return function(corners: { Vector3 }): (number?, number?, number?, number?)
	local camera = workspace.CurrentCamera

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	for _, corner in corners do
		local screenPoint, onScreen = camera:WorldToViewportPoint(corner)
		if onScreen then
			minX = math.min(minX, screenPoint.X)
			minY = math.min(minY, screenPoint.Y)
			maxX = math.max(maxX, screenPoint.X)
			maxY = math.max(maxY, screenPoint.Y)
		end
	end

	if minX == math.huge or minY == math.huge then
		return nil
	end

	local viewportSize = camera.ViewportSize

	minX = math.clamp(minX, 0, viewportSize.X)
	minY = math.clamp(minY, 0, viewportSize.Y)
	maxX = math.clamp(maxX, 0, viewportSize.X)
	maxY = math.clamp(maxY, 0, viewportSize.Y)

	return minX, minY, maxX, maxY
end
