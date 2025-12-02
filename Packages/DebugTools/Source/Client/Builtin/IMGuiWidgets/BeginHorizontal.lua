local Imgui = require(script.Parent.Parent.Parent.IMGui)

type ImguiBeginHorizontal = Imgui.WidgetInstance & {
	UIListLayout: UIListLayout,
}

local IMGUI_CONFIG = Imgui:GetConfig()

Imgui:NewWidgetDefinition("BeginHorizontal", {
	Construct = function(self: ImguiBeginHorizontal, parent: GuiObject, alignment: Enum.HorizontalAlignment?)
		local Frame = Instance.new("Frame")
		Frame.Name = `Horizontal ({self.ID})`
		Frame.Size = UDim2.fromScale(1.00, 0.00)
		Frame.AutomaticSize = Enum.AutomaticSize.XY
		Frame.BackgroundTransparency = 1.00
		Frame.BorderSizePixel = 0

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.Padding = UDim.new(0, IMGUI_CONFIG.Sizes.ItemPadding.X)
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
		UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = Frame

		self.UIListLayout = UIListLayout

		Frame.Parent = parent

		return Frame, Frame
	end,

	Update = function(self: ImguiBeginHorizontal, alignment: Enum.HorizontalAlignment?)
		self.UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
	end,
})

return nil
