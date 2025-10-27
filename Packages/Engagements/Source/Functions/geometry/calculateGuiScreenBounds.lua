--[[
	Calculates the visible screen-space bounding box of a set of 2D corners.

	This function takes an array of Vector2 points and determines the minimum and maximum X and Y coordinates
	of the bounding box, properly handling elements that are partially visible on screen.

	If the element is completely outside the viewport, the function returns nil.
]]
return function(corners: { Vector2 }, viewportSize: Vector2): (number?, number?, number?, number?)
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	for _, corner in corners do
		minX = math.min(minX, corner.X)
		minY = math.min(minY, corner.Y)
		maxX = math.max(maxX, corner.X)
		maxY = math.max(maxY, corner.Y)
	end

	if minX == math.huge or minY == math.huge then
		return nil
	end

	if maxX < 0 or minX > viewportSize.X or maxY < 0 or minY > viewportSize.Y then
		return nil
	end

	local visibleMinX = math.clamp(minX, 0, viewportSize.X)
	local visibleMinY = math.clamp(minY, 0, viewportSize.Y)
	local visibleMaxX = math.clamp(maxX, 0, viewportSize.X)
	local visibleMaxY = math.clamp(maxY, 0, viewportSize.Y)

	return visibleMinX, visibleMinY, visibleMaxX, visibleMaxY
end
