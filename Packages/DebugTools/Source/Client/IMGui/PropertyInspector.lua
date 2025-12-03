local IMGui = require(script.Parent)

local DropdownPopup = require(script.Parent.Parent.Builtin.DropdownPopup)

type PropertyInspector = IMGui.WidgetInstance & {
	NameLabel: TextLabel,

	Value: any,
	NewValue: any,
}

local function createValueField(
	value: any,
	valueType: string,
	parent: Instance,
	changedCallback: (newValue: any) -> ()
): () -> ()
	if valueType == "boolean" then
		local checkbox = Instance.new("ImageButton")
		checkbox.Name = "Checkbox"
		checkbox.Size = UDim2.fromScale(1, 1)
		checkbox.BackgroundColor3 = Color3.new()
		checkbox.BorderColor3 = Color3.new()
		checkbox.BorderSizePixel = 0
		checkbox.ImageTransparency = 1

		local uIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		uIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
		uIAspectRatioConstraint.Parent = checkbox

		local uIPadding = Instance.new("UIPadding")
		uIPadding.Name = "UIPadding"
		uIPadding.PaddingBottom = UDim.new(0, 2)
		uIPadding.PaddingLeft = UDim.new(0, 2)
		uIPadding.PaddingRight = UDim.new(0, 2)
		uIPadding.PaddingTop = UDim.new(0, 2)
		uIPadding.Parent = checkbox

		local frame = Instance.new("Frame")
		frame.Name = "Frame"
		frame.BackgroundColor3 = Color3.new(1, 1, 1)
		frame.BorderColor3 = Color3.new()
		frame.BorderSizePixel = 0
		frame.Size = UDim2.fromScale(1, 1)
		frame.Parent = checkbox

		frame.Visible = value

		checkbox.Parent = parent

		local activatedConnection = checkbox.Activated:Once(function()
			changedCallback(not value)
		end)

		return function()
			activatedConnection:Disconnect()

			checkbox:Destroy()
		end
	elseif valueType == "string" then
		local textBox = Instance.new("TextBox")
		textBox.Name = "TextBox"
		textBox.BackgroundColor3 = Color3.new()
		textBox.BackgroundTransparency = 0.50
		textBox.BorderColor3 = Color3.new()
		textBox.BorderSizePixel = 0
		textBox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		textBox.Size = UDim2.fromScale(1, 1)
		textBox.TextColor3 = Color3.new(1, 1, 1)
		textBox.Text = value
		textBox.TextXAlignment = Enum.TextXAlignment.Left
		textBox.ClearTextOnFocus = false
		textBox.AutoLocalize = false

		IMGui.applyTextStyle(textBox)

		local focusLostConnection = textBox.FocusLost:Once(function(enterPressed)
			if not enterPressed then
				return
			end

			changedCallback(textBox.Text)
		end)

		textBox.Parent = parent

		return function()
			focusLostConnection:Disconnect()

			textBox:Destroy()
		end
	elseif valueType == "number" then
		local textBox = Instance.new("TextBox")
		textBox.Name = "TextBox"
		textBox.BackgroundColor3 = Color3.new()
		textBox.BackgroundTransparency = 0.50
		textBox.BorderColor3 = Color3.new()
		textBox.BorderSizePixel = 0
		textBox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		textBox.Size = UDim2.fromScale(1, 1)
		textBox.TextColor3 = Color3.new(1, 1, 1)
		textBox.Text = value
		textBox.TextXAlignment = Enum.TextXAlignment.Left
		textBox.ClearTextOnFocus = false
		textBox.AutoLocalize = false

		IMGui.applyTextStyle(textBox)

		local validValue = value

		local focusLostConnection = textBox.FocusLost:Once(function(enterPressed)
			if not enterPressed then
				return
			end

			local newNumber = tonumber(textBox.Text)
			if not newNumber then
				textBox.Text = tostring(validValue)
				return
			end

			validValue = newNumber

			changedCallback(validValue)
		end)

		textBox.Parent = parent

		return function()
			focusLostConnection:Disconnect()

			textBox:Destroy()
		end
	elseif valueType == "EnumItem" then
		local textButton = Instance.new("TextButton")
		textButton.Name = "TextBox"
		textButton.BackgroundColor3 = Color3.new()
		textButton.BackgroundTransparency = 0.50
		textButton.BorderColor3 = Color3.new()
		textButton.BorderSizePixel = 0
		textButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		textButton.Size = UDim2.fromScale(1, 1)
		textButton.TextColor3 = Color3.new(1, 1, 1)
		textButton.Text = value.Name
		textButton.TextXAlignment = Enum.TextXAlignment.Left
		textButton.AutoLocalize = false

		IMGui.applyTextStyle(textButton)

		local activatedConnection = textButton.Activated:Once(function()
			local validOptions = value.EnumType:GetEnumItems()

			for i = 1, #validOptions do
				validOptions[i] = validOptions[i].Name
			end

			local dropdown = DropdownPopup.new(textButton, validOptions, value.Name)
			dropdown.EntrySelected:Connect(function(newValue: string)
				changedCallback(value.EnumType:FromName(newValue))
			end)
		end)

		textButton.Parent = parent

		return function()
			activatedConnection:Disconnect()

			textButton:Destroy()
		end
	elseif valueType == "table" then
		local textButton = Instance.new("TextButton")
		textButton.Name = "TextBox"
		textButton.BackgroundColor3 = Color3.new()
		textButton.BackgroundTransparency = 0.50
		textButton.BorderColor3 = Color3.new()
		textButton.BorderSizePixel = 0
		textButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		textButton.Size = UDim2.fromScale(1, 1)
		textButton.TextColor3 = Color3.new(1, 1, 1)
		textButton.Text = tostring(value[1])
		textButton.TextXAlignment = Enum.TextXAlignment.Left
		textButton.AutoLocalize = false

		IMGui.applyTextStyle(textButton)

		local activatedConnection = textButton.Activated:Once(function()
			local dropdown = DropdownPopup.new(textButton, value, value[1])
			dropdown.EntrySelected:Connect(function(newValue)
				changedCallback(newValue)
			end)
		end)

		textButton.Parent = parent

		return function()
			activatedConnection:Disconnect()

			textButton:Destroy()
		end
	else
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "TextLabel"
		textLabel.BackgroundTransparency = 1
		textLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		textLabel.Size = UDim2.fromScale(1, 1)
		textLabel.TextColor3 = Color3.new(0.5, 0.5, 0.5)
		textLabel.Text = tostring(value)
		textLabel.TextSize = 14
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextTransparency = 0.25
		textLabel.AutoLocalize = false
		textLabel.Parent = parent

		IMGui.applyTextStyle(textLabel)

		return function()
			textLabel:Destroy()
		end
	end
end

IMGui:NewWidgetDefinition("PropertyInspector", {
	Events = {
		["changed"] = {
			["Evaluate"] = function(self: PropertyInspector)
				local newValue = self.NewValue
				self.NewValue = nil

				return newValue
			end,
		},
	},

	Construct = function(self: PropertyInspector, parent: GuiObject, text: string, value: any)
		local inspector = Instance.new("Frame")
		inspector.Name = `Property Inspector ({self.ID})`
		inspector.BackgroundTransparency = 1
		inspector.LayoutOrder = 6
		inspector.Size = UDim2.new(1, 0, 0, 16)

		local uIListLayout = Instance.new("UIListLayout")
		uIListLayout.Name = "UIListLayout"
		uIListLayout.FillDirection = Enum.FillDirection.Horizontal
		uIListLayout.HorizontalFlex = Enum.UIFlexAlignment.Fill
		uIListLayout.Padding = UDim.new(0, 2)
		uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uIListLayout.Parent = inspector

		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.AutoLocalize = false
		name.AutomaticSize = Enum.AutomaticSize.XY
		name.BackgroundTransparency = 1
		name.FontFace = Font.new("rbxassetid://16658221428")
		name.LayoutOrder = 1
		name.RichText = true
		name.Size = UDim2.fromScale(1, 1)
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextSize = 14
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Parent = inspector

		self.NameLabel = name

		local divider = Instance.new("Frame")
		divider.Name = "Divider"
		divider.BackgroundColor3 = Color3.new()
		divider.BorderColor3 = Color3.new()
		divider.BorderSizePixel = 0
		divider.LayoutOrder = 2
		divider.Size = UDim2.new(0, 4, 1, 0)
		divider.Parent = inspector

		local valueFrame = Instance.new("Frame")
		valueFrame.Name = "Value"
		valueFrame.BackgroundTransparency = 1
		valueFrame.LayoutOrder = 3
		valueFrame.Size = UDim2.fromScale(1, 1)
		valueFrame.Parent = inspector

		IMGui.applyTextStyle(name)

		self.ValueFrame = valueFrame

		self.Value = value
		self.ValueFrameCleanup = createValueField(value, typeof(value), self.ValueFrame, function(newValue)
			self.Value = newValue
			self.NewValue = self.Value
		end)

		name.Text = text

		inspector.Parent = parent

		return inspector
	end,

	Update = function(self: PropertyInspector, text: string, value: any)
		self.NameLabel.Text = text

		self.Value = value

		self.ValueFrameCleanup()
		self.ValueFrameCleanup = createValueField(self.Value, typeof(self.Value), self.ValueFrame, function(newValue)
			self.Value = newValue
			self.NewValue = self.Value
		end)
	end,
})

return nil
