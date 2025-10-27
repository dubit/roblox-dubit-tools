local IAB_MIN_VISIBLE_RATIO = 0.5

local getGuiBoundingBoxCorners = require(script.Parent.Parent.geometry.getGuiBoundingBoxCorners)
local calculateGuiScreenBounds = require(script.Parent.Parent.geometry.calculateGuiScreenBounds)
local calculateVisibleRatio = require(script.Parent.Parent.calculateVisibleRatio)

--[[
	Determines if a 2D GUI object meets the minimum visibility ratio requirement.

	This function calculates the visible area of a GUI object relative to its total area on the screen and checks if the
	visible-to-total area ratio exceeds a defined threshold. It uses utility functions to get the GUI's bounding
	box corners, calculate its screen bounds, and visible ratio.

	The function ensures that an ad or tracked GUI object is visible enough on the screen to meet IAB (Interactive
	Advertising Bureau) standards before it can be considered for tracking or engagement.
]]
return function(guiObject: GuiObject): boolean
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize

	local corners = getGuiBoundingBoxCorners(guiObject)
	local visibleBounds = { calculateGuiScreenBounds(corners, viewportSize) }

	if not visibleBounds[1] then
		return false
	end

	local visibleRatio = calculateVisibleRatio(
		visibleBounds[1],
		visibleBounds[2],
		visibleBounds[3],
		visibleBounds[4],
		corners[1].X,
		corners[1].Y,
		corners[4].X,
		corners[4].Y
	)

	return visibleRatio >= IAB_MIN_VISIBLE_RATIO
end
