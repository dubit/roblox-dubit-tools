local Imgui = require(script.Parent.Parent.Parent.IMGui)

type ImguiCheckbox = Imgui.WidgetInstance & {
	Status: boolean,
	Pressed: boolean,

	TopInstance: Frame,

	TextLabel: TextLabel,
	StatusImageLabel: ImageLabel,

	CheckboxButton: TextButton,

	PressConnection: RBXScriptConnection,
}

Imgui:NewWidgetDefinition("Checkbox", {
	Events = {
		["activated"] = {
			["Evaluate"] = function(self: ImguiCheckbox)
				local wasPressed = self.Pressed
				self.Pressed = false

				return wasPressed
			end,
		},
	},

	Construct = function(self: ImguiCheckbox, parent: GuiObject, text: string, status: boolean)
		local Frame = Instance.new("Frame")
		Frame.Name = `Checkbox ({self.ID})`
		Frame.AutomaticSize = Enum.AutomaticSize.XY
		Frame.BackgroundTransparency = 1.00
		Frame.BorderSizePixel = 0

		local TextLabel: TextLabel = Instance.new("TextLabel")
		TextLabel.Name = "Text"
		TextLabel.Text = text
		TextLabel.AutomaticSize = Enum.AutomaticSize.XY
		TextLabel.BackgroundTransparency = 1
		TextLabel.BorderSizePixel = 0
		TextLabel.LayoutOrder = 1

		Imgui.applyTextStyle(TextLabel)

		TextLabel.Parent = Frame

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = Frame
		UIListLayout.Padding = UDim.new(0.00, Imgui:GetConfig().Sizes.ItemPadding.X)

		local TextButton = Instance.new("TextButton")
		TextButton.Name = "TextButton"
		TextButton.AutoLocalize = false
		TextButton.Size = UDim2.fromOffset(18, 18)
		TextButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		TextButton.Text = ""
		TextButton.TextSize = 14
		TextButton.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
		TextButton.BorderSizePixel = 0

		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
		UIAspectRatioConstraint.Parent = TextButton

		local StatusImageLabel: ImageLabel = Instance.new("ImageLabel")
		StatusImageLabel.Name = "Status ImageLabel"
		StatusImageLabel.Size = UDim2.fromScale(1.00, 1.00)
		StatusImageLabel.Image = "rbxassetid://15225522557"
		StatusImageLabel.ImageColor3 = Imgui:GetConfig().Colors.Checkbox
		StatusImageLabel.Visible = status
		StatusImageLabel.BackgroundTransparency = 1.00
		StatusImageLabel.BorderSizePixel = 0
		StatusImageLabel.Parent = TextButton

		TextButton.Parent = Frame

		Frame.Parent = parent

		self.CheckboxButton = TextButton
		self.TextLabel = TextLabel
		self.StatusImageLabel = StatusImageLabel
		self.Status = status or true

		self.PressConnection = TextButton.Activated:Connect(function()
			self.Pressed = true

			self.Status = not self.Status
		end)

		return Frame
	end,

	Deconstruct = function(self: ImguiCheckbox)
		self.PressConnection:Disconnect()
	end,

	Update = function(self: ImguiCheckbox, text: string, status: boolean)
		self.Status = status
		self.TextLabel.Text = text
		self.StatusImageLabel.Visible = status
	end,
})

return nil
