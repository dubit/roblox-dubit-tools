local IAB_MIN_VISIBLE_RATIO = 0.5

local getModelBoundingBoxCorners = require(script.Parent.Parent.geometry.getModelBoundingBoxCorners)
local calculateModelScreenBounds = require(script.Parent.Parent.geometry.calculateModelScreenBounds)
local calculateModelProjectedBounds = require(script.Parent.Parent.geometry.calculateModelProjectedBounds)
local calculateVisibleRatio = require(script.Parent.Parent.calculateVisibleRatio)

--[[
	Determines if a 3D model meets the minimum visibility ratio requirement.

	This function calculates the visible area of a model relative to its projected area on the screen and checks if the
	visible-to-projected area ratio exceeds a defined threshold. It uses utility functions to get the model's bounding
	box corners, calculate its screen bounds, projected bounds, and visible ratio.

	The function ensures that an ad or tracked object is visible enough on the screen to meet IAB (Interactive Advertising Bureau) standards before it
	can be considered for tracking or engagement.
]]
return function(model: Model): boolean
	local corners = getModelBoundingBoxCorners(model)
	local visibleBounds = { calculateModelScreenBounds(corners) }

	if not visibleBounds[1] then
		return false
	end

	local projMinX, projMinY, projMaxX, projMaxY = calculateModelProjectedBounds(corners)

	local visibleRatio = calculateVisibleRatio(
		visibleBounds[1],
		visibleBounds[2],
		visibleBounds[3],
		visibleBounds[4],
		projMinX,
		projMinY,
		projMaxX,
		projMaxY
	)

	return visibleRatio >= IAB_MIN_VISIBLE_RATIO
end
