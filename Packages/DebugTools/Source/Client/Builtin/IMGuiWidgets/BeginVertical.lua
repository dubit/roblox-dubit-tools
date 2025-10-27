local Imgui = require(script.Parent.Parent.Parent.IMGui)

type ImguiBeginVertical = Imgui.WidgetInstance & {
	UIListLayout: UIListLayout,
}

Imgui:NewWidgetDefinition("BeginVertical", {
	Construct = function(self: ImguiBeginVertical, parent: GuiObject, alignment: Enum.HorizontalAlignment?)
		local Frame = Instance.new("Frame")
		Frame.Name = `Horizontal ({self.ID})`
		Frame.Size = UDim2.fromScale(1.00, 0.00)
		Frame.AutomaticSize = Enum.AutomaticSize.XY
		Frame.BackgroundTransparency = 1.00
		Frame.BorderSizePixel = 0

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.FillDirection = Enum.FillDirection.Vertical
		UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = Frame

		self.UIListLayout = UIListLayout

		Frame.Parent = parent

		return Frame, Frame
	end,

	Update = function(self: ImguiBeginVertical, alignment: Enum.HorizontalAlignment?)
		self.UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
	end,
})

return nil
