--[[
	Retrieves the corner coordinates of a GuiBase's bounding box.

	This function takes a GuiObject and determines the four corner points of its bounding box using
	AbsolutePosition and AbsoluteSize properties.

	Returns an array of Vector2 points representing the corners in screen space, used for visibility
	testing and geometric calculations.
]]
return function(guiBase: GuiObject): { Vector2 }
	local position = guiBase.AbsolutePosition
	local size = guiBase.AbsoluteSize

	return {
		Vector2.new(position.X, position.Y),
		Vector2.new(position.X + size.X, position.Y),
		Vector2.new(position.X, position.Y + size.Y),
		Vector2.new(position.X + size.X, position.Y + size.Y),
	}
end
