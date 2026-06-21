local IMGui = require(script.Parent)

type ImguiTextBox = IMGui.WidgetInstance & {
	Status: boolean,
	Pressed: boolean,

	TopInstance: Frame,

	TextBox: TextBox,
}

IMGui:NewWidgetDefinition("TextBox", {
	Construct = function(self: ImguiTextBox, parent: GuiObject, text: string, readonly: boolean?, xAlignment: Enum.TextXAlignment, yAlignment: Enum.TextYAlignment)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1.00, 1.00)
		frame.Name = `TextBox ({self.ID})`
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.BackgroundTransparency = 1.00
		frame.BorderSizePixel = 0

		local textBox: TextBox = Instance.new("TextBox")
		textBox.Size = UDim2.fromScale(1.00, 1.00)
		textBox.Name = "Text"
		textBox.Text = text
		textBox.AutomaticSize = Enum.AutomaticSize.XY
		textBox.BackgroundTransparency = 1
		textBox.BorderSizePixel = 0
		textBox.ClearTextOnFocus = false
		textBox.TextEditable = readonly == false
		textBox.TextXAlignment = xAlignment or Enum.TextXAlignment.Center
		textBox.TextYAlignment = yAlignment or Enum.TextYAlignment.Center

		textBox.BackgroundColor3 = Color3.new()
		textBox.BackgroundTransparency = 0.50
		textBox.BorderColor3 = Color3.new()
		textBox.BorderSizePixel = 0

		IMGui.applyTextStyle(textBox)

		textBox.Parent = frame
		frame.Parent = parent

		self.TextBox = textBox

		return frame
	end,

	Update = function(self: ImguiTextBox, text: string, readonly: boolean?, xAlignment: Enum.TextXAlignment, yAlignment: Enum.TextYAlignment)
		self.TextBox.Text = text
		self.TextBox.TextEditable = readonly == false
		self.TextBox.TextXAlignment = xAlignment or Enum.TextXAlignment.Center
		self.TextBox.TextYAlignment = yAlignment or Enum.TextYAlignment.Center
	end,
})

return nil
