--[[
	Calculates the visibility ratio of an object on the screen.

	This function determines the proportion of an object's projected screen-space area that is actually visible. It
	does so by comparing the visible bounding box area against the total projected bounding box area.

	If the projected area is zero (which may happen if the object is too far or has no meaningful projection), the
	function returns 0 to avoid division by zero errors.
]]
return function(
	visibleMinX: number,
	visibleMinY: number,
	visibleMaxX: number,
	visibleMaxY: number,
	projMinX: number,
	projMinY: number,
	projMaxX: number,
	projMaxY: number
): number
	if visibleMinX > projMaxX or visibleMaxX < projMinX or visibleMinY > projMaxY or visibleMaxY < projMinY then
		return 0
	end

	local visibleArea = math.max(0, visibleMaxX - visibleMinX) * math.max(0, visibleMaxY - visibleMinY)
	local projectedArea = math.max(0, projMaxX - projMinX) * math.max(0, projMaxY - projMinY)

	if projectedArea == 0 then
		return 0
	end

	return visibleArea / projectedArea
end
