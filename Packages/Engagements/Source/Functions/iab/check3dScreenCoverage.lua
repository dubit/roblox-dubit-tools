local IAB_MIN_AD_SCREEN_COVERAGE = 0.015

local getModelBoundingBoxCorners = require(script.Parent.Parent.geometry.getModelBoundingBoxCorners)
local calculateModelProjectedBounds = require(script.Parent.Parent.geometry.calculateModelProjectedBounds)

--[[
	Determines if a 3D model meets the minimum ad size requirement relative to the screen.

	This function calculates the projected screen-space area of a given model and checks whether it meets the
	IAB (Interactive Advertising Bureau)-defined minimum ad screen ratio. If the model's projected area is too small,
	it is considered ineligible for tracking.
]]
return function(model: Model, viewportSize: Vector2): boolean
	local corners = getModelBoundingBoxCorners(model)
	local projMinX, projMinY, projMaxX, projMaxY = calculateModelProjectedBounds(corners)
	local projectedArea = math.max(0, projMaxX - projMinX) * math.max(0, projMaxY - projMinY)

	local totalScreenArea = viewportSize.X * viewportSize.Y

	return (projectedArea / totalScreenArea) >= IAB_MIN_AD_SCREEN_COVERAGE
end
