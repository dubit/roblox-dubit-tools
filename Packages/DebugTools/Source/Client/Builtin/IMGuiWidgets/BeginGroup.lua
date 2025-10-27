local IMGui = require(script.Parent.Parent.Parent.IMGui)

type IMGuiBeginGroup = IMGui.WidgetInstance & {
	UIListLayout: UIListLayout,
}

IMGui:NewWidgetDefinition("BeginGroup", {
	Construct = function(self: IMGuiBeginGroup, parent: GuiObject, size: UDim2, alignment: Enum.HorizontalAlignment?)
		local Frame = Instance.new("Frame")
		Frame.Name = `Group ({self.ID})`
		Frame.Size = size
		Frame.BackgroundTransparency = 1.00
		Frame.BorderSizePixel = 0

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = Frame

		self.UIListLayout = UIListLayout

		Frame.Parent = parent

		return Frame, Frame
	end,

	Update = function(self: IMGuiBeginGroup, size: UDim2, alignment: Enum.HorizontalAlignment?)
		self.TopInstance.Size = size
		self.UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
	end,
})

return nil
