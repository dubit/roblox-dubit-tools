--!strict
type Props = {
	PropertyText: string,

	Value: number?,
	Default: number?,

	Parent: GuiBase2d,
}

local DebugToolRootPath = script.Parent.Parent

local Style = require(DebugToolRootPath.Style)

return function(props: Props, onValueChanged: (newValue: number) -> nil)
	local value: number = props.Value or 0

	local argument = Instance.new("TextLabel")
	argument.Name = "Argument [number]"
	argument.Size = UDim2.new(1.00, 0, 0.00, 16)
	argument.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	argument.Text = props.PropertyText
	argument.TextColor3 = Style.COLOR_WHITE
	argument.TextSize = 12
	argument.TextStrokeTransparency = 0.75
	argument.TextWrapped = true
	argument.TextXAlignment = Enum.TextXAlignment.Left
	argument.AutomaticSize = Enum.AutomaticSize.Y
	argument.BackgroundTransparency = 1.00
	argument.BorderSizePixel = 0
	argument.LayoutOrder = 1
	argument.AutoLocalize = false

	local textBox: TextBox = Instance.new("TextBox")
	textBox.Name = "Value [TextBox]"
	textBox.Position = UDim2.fromScale(0.50, 0.00)
	textBox.Size = UDim2.fromScale(0.50, 1.00)
	textBox.ClearTextOnFocus = false
	textBox.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textBox.PlaceholderText = props.Default and tostring(props.Default) or "number"
	textBox.Text = tostring(value)
	textBox.TextColor3 = Style.COLOR_WHITE
	textBox.TextSize = 12
	textBox.TextWrapped = true
	textBox.AutomaticSize = Enum.AutomaticSize.Y
	textBox.BackgroundColor3 = Style.BACKGROUND_DARK
	textBox.BorderSizePixel = 0
	textBox.AutoLocalize = false
	textBox.Parent = argument

	local changedConnection = textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local newNumber: number? = tonumber(textBox.Text)
		if not newNumber then
			textBox.Text = tostring(value)
			return
		end

		value = newNumber

		onValueChanged(newNumber)
	end)

	argument.Parent = props.Parent

	return function()
		argument:Destroy()
		changedConnection:Disconnect()
	end
end
