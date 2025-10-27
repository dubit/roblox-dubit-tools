--!strict
type Props = {
	PropertyText: string,

	Value: string,
	Options: { string },

	Parent: GuiBase2d,
}

local DebugToolRootPath = script.Parent.Parent

local Style = require(DebugToolRootPath.Style)

local DropdownPopup = require(script.Parent.DropdownPopup)

return function(props: Props, onValueChanged: (newValue: string) -> nil)
	local value: string = props.Value

	local argument = Instance.new("TextLabel")
	argument.Name = "Dropdown"
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
	argument.LayoutOrder = 4
	argument.AutoLocalize = false

	local clickDetector: TextButton = Instance.new("TextButton")
	clickDetector.Name = "Dropdown Click Detector"
	clickDetector.Position = UDim2.fromScale(0.50, 0.00)
	clickDetector.Size = UDim2.fromScale(0.50, 1.00)
	clickDetector.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	clickDetector.Text = tostring(value)
	clickDetector.TextColor3 = Style.COLOR_WHITE
	clickDetector.TextSize = 12
	clickDetector.TextWrapped = true
	clickDetector.AutoButtonColor = false
	clickDetector.AutomaticSize = Enum.AutomaticSize.Y
	clickDetector.BackgroundColor3 = Style.BACKGROUND_DARK
	clickDetector.BorderSizePixel = 0
	clickDetector.AutoLocalize = false
	clickDetector.Parent = argument

	local isOpen = false
	local clickConnection: RBXScriptConnection = clickDetector.Activated:Connect(function()
		if isOpen or #props.Options <= 1 then
			return
		end
		isOpen = true

		local optionsClone = table.clone(props.Options)
		table.remove(optionsClone, table.find(optionsClone, value))

		local dropdown = DropdownPopup.new(clickDetector, optionsClone, props.Value)
		dropdown.EntrySelected:Connect(function(newValue: string)
			if newValue == value then
				return
			end

			value = newValue
			clickDetector.Text = newValue

			onValueChanged(newValue)
		end)
		dropdown.Closed:Connect(function()
			isOpen = false
		end)
	end)

	argument.Parent = props.Parent

	return function()
		argument:Destroy()
		clickConnection:Disconnect()
	end
end
