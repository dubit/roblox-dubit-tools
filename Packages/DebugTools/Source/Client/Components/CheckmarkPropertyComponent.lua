--!strict
type Props = {
	PropertyText: string,

	Value: boolean,

	Parent: GuiBase2d,
}

local DebugToolRootPath = script.Parent.Parent

local Style = require(DebugToolRootPath.Style)

return function(props: Props, onValueChanged: (newValue: boolean) -> nil)
	local value: boolean = props.Value

	local argument: TextLabel = Instance.new("TextLabel")
	argument.Name = "Argument [boolean]"
	argument.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	argument.Text = props.PropertyText or ""
	argument.TextColor3 = Style.COLOR_WHITE
	argument.TextSize = 12
	argument.TextStrokeTransparency = 0.75
	argument.TextWrapped = true
	argument.TextXAlignment = Enum.TextXAlignment.Left
	argument.AutomaticSize = Enum.AutomaticSize.Y
	argument.BackgroundTransparency = 1.00
	argument.BorderSizePixel = 0
	argument.LayoutOrder = 1
	argument.Size = UDim2.new(1, 0, 0, 16)
	argument.AutoLocalize = false

	local clickDetector: TextButton = Instance.new("TextButton")
	clickDetector.Name = "Checkmark Click Detector"
	clickDetector.AnchorPoint = Vector2.new(1.00, 0.00)
	clickDetector.Position = UDim2.fromScale(1.00, 0.00)
	clickDetector.Size = UDim2.fromScale(0.10, 1.00)
	clickDetector.Text = ""
	clickDetector.TextSize = 12
	clickDetector.TextWrapped = true
	clickDetector.AutoButtonColor = false
	clickDetector.AutomaticSize = Enum.AutomaticSize.Y
	clickDetector.BackgroundColor3 = Style.BACKGROUND_DARK
	clickDetector.BorderSizePixel = 0
	clickDetector.AutoLocalize = false
	clickDetector.Parent = argument

	local uiAspectRatioConstraint: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uiAspectRatioConstraint.Parent = clickDetector

	local fill: Frame = Instance.new("Frame")
	fill.Name = "Value [TextBox]"
	fill.AnchorPoint = Vector2.new(0.50, 0.50)
	fill.Position = UDim2.fromScale(0.50, 0.50)
	fill.Size = UDim2.fromScale(0.75, 0.75)
	fill.BackgroundColor3 = Style.PRIMARY
	fill.BorderSizePixel = 0
	fill.Visible = value
	fill.Parent = clickDetector

	argument.Parent = props.Parent

	local clickConnection: RBXScriptConnection = clickDetector.Activated:Connect(function()
		value = not value

		fill.Visible = value
		onValueChanged(value)
	end)

	return function()
		argument:Destroy()
		clickConnection:Disconnect()
	end
end
