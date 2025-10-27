local IAB_MIN_AD_SCREEN_COVERAGE = 0.015

--[[
	Determines if a 2D GUI object meets the minimum ad size requirement relative to the screen.

	This function calculates the screen-space area of a given GUI object and checks whether it meets the
	IAB (Interactive Advertising Bureau)-defined minimum ad screen ratio. If the GUI object's area is too small, it is
	considered ineligible for tracking.
]]
return function(guiObject: GuiObject, viewportSize: Vector2): boolean
	local projectedArea = guiObject.AbsoluteSize.X * guiObject.AbsoluteSize.Y
	local totalScreenArea = viewportSize.X * viewportSize.Y

	local rounded = math.round((projectedArea / totalScreenArea) * 1000) / 1000

	return rounded >= IAB_MIN_AD_SCREEN_COVERAGE
end
