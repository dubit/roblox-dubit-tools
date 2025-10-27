local IMGui = require(script.Parent.Parent.Parent.Parent.IMGui)

local acceptedInputTypes = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}

type IMGuiBeginExplorerHorizontal = IMGui.WidgetInstance & {
	UIListLayout: UIListLayout,
	TopInstance: Frame,

	WasPressed: boolean,
}

IMGui:NewWidgetDefinition("BeginExplorerHorizontal", {
	Events = {
		["activated"] = {
			["Setup"] = function(self: IMGuiBeginExplorerHorizontal)
				self.TopInstance.InputBegan:Connect(function(inputObject: InputObject)
					if not acceptedInputTypes[inputObject.UserInputType] then
						return
					end

					self.WasPressed = true
				end)
			end,

			["Evaluate"] = function(self: IMGuiBeginExplorerHorizontal)
				local wasPressed = self.WasPressed
				self.WasPressed = false

				return wasPressed
			end,
		},
	},

	Construct = function(
		self: IMGuiBeginExplorerHorizontal,
		parent: GuiObject,
		selected: boolean?,
		alignment: Enum.HorizontalAlignment?
	)
		local Frame = Instance.new("Frame")
		Frame.Name = `ExplorerHorizontal ({self.ID})`
		Frame.Size = UDim2.fromScale(1, 0)
		Frame.AutomaticSize = Enum.AutomaticSize.XY
		Frame.BackgroundTransparency = selected and 0.50 or 1
		Frame.BorderSizePixel = 0
		Frame.Active = true
		Frame.BackgroundColor3 = Color3.fromHex("#0b5aaf")

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = Frame

		self.TopInstance = Frame
		self.UIListLayout = UIListLayout

		Frame.Parent = parent

		return Frame, Frame
	end,

	Update = function(self: IMGuiBeginExplorerHorizontal, selected: boolean?, alignment: Enum.HorizontalAlignment?)
		self.UIListLayout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
		self.TopInstance.BackgroundTransparency = selected and 0 or 1
	end,
})

return nil
