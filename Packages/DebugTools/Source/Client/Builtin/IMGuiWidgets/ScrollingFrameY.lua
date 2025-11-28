local Imgui = require(script.Parent.Parent.Parent.IMGui)

type ImguiScrollingFrameY = Imgui.WidgetInstance & {
	UIListLayout: UIListLayout,
}

Imgui:NewWidgetDefinition("ScrollingFrameY", {
	Construct = function(
		self: ImguiScrollingFrameY,
		parent: GuiObject,
		size: UDim2,
		alignment: Enum.HorizontalAlignment?
	)
		local ScrollingFrameY: ScrollingFrame = Instance.new("ScrollingFrame")
		ScrollingFrameY.Name = `ScrollingFrameY ({self.ID})`
		ScrollingFrameY.Size = size
		ScrollingFrameY.BackgroundTransparency = 1
		ScrollingFrameY.BorderSizePixel = 0
		ScrollingFrameY.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ScrollingFrameY.CanvasSize = UDim2.fromScale(0, 0)
		ScrollingFrameY.ScrollBarThickness = 5
		ScrollingFrameY.Selectable = false
		ScrollingFrameY.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		ScrollingFrameY.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		ScrollingFrameY.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.FillDirection = Enum.FillDirection.Vertical
		UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = ScrollingFrameY

		self.UIListLayout = UIListLayout

		ScrollingFrameY.Parent = parent

		return ScrollingFrameY, ScrollingFrameY
	end,

	Update = function(self: ImguiScrollingFrameY, size: UDim2, alignment: Enum.HorizontalAlignment?)
		self.TopInstance.Size = size
		self.UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
	end,
})

return nil
