local IMGui = require(script.Parent.Parent.Parent.IMGui)

type UISizeConstraint = Imgui.WidgetInstance & {
	Constraint: UISizeConstraint,
}

IMGui:NewWidgetDefinition("UISizeConstraint", {
	Construct = function(self: UISizeConstraint, parent: GuiObject, minSize: Vector2?, maxSize: Vector2?)
		local constraint = Instance.new("UISizeConstraint")
		constraint.Name = `UISizeConstraint ({self.ID})`
		constraint.MinSize = minSize or Vector2.zero
		constraint.MaxSize = maxSize or Vector2.new(math.huge, math.huge)
		constraint.Parent = parent

		self.Constraint = constraint

		return parent
	end,

	Update = function(self: UISizeConstraint, minSize: Vector2?, maxSize: Vector2?)
		self.Constraint.MinSize = minSize or Vector2.zero
		self.Constraint.MaxSize = maxSize or Vector2.new(math.huge, math.huge)
	end,
})

return nil
