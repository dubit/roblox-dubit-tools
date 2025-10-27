--!strict
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Widget = require(DebugToolRootPath.Widget)

local KEY_LIFETIME: number = 1.70
local KEY_NAMES_MAP: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",

	[Enum.KeyCode.Backspace] = "<-",
	[Enum.KeyCode.BackSlash] = "|",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Comma] = ".",
	[Enum.KeyCode.Period] = ",",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.Semicolon] = ";",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",

	[Enum.KeyCode.LeftShift] = "LS",
	[Enum.KeyCode.LeftAlt] = "LA",
	[Enum.KeyCode.LeftControl] = "LC",

	[Enum.KeyCode.RightShift] = "RS",
	[Enum.KeyCode.RightAlt] = "RA",
	[Enum.KeyCode.RightControl] = "RC",

	[Enum.KeyCode.Space] = "⬆️",
}

local function createKeyVisual(keyCode: Enum.KeyCode): Frame
	local keyVisualFrame: Frame = Instance.new("Frame")
	keyVisualFrame.Name = "Key"
	keyVisualFrame.Size = UDim2.fromOffset(32, 32)
	keyVisualFrame.BackgroundColor3 = Color3.fromRGB(49, 47, 40)
	keyVisualFrame.BorderSizePixel = 0

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = keyVisualFrame

	local keyLabel: TextLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.AutoLocalize = false
	keyLabel.Size = UDim2.fromScale(1.00, 1.00)
	keyLabel.FontFace =
		Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	keyLabel.Text = KEY_NAMES_MAP[keyCode] or tostring(keyCode.Name)
	keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyLabel.TextSize = 24
	keyLabel.BackgroundTransparency = 1.00
	keyLabel.LayoutOrder = 1
	keyLabel.Parent = keyVisualFrame

	return keyVisualFrame
end

Widget.new("Keyboard Input", function(parent: ScreenGui)
	local minimalContentFrame: Frame = Instance.new("Frame")
	minimalContentFrame.Name = "MinimalContent"
	minimalContentFrame.AnchorPoint = Vector2.new(0.00, 1.00)
	minimalContentFrame.Position = UDim2.new(0.00, 8, 1.00, -120)
	minimalContentFrame.Size = UDim2.fromOffset(48, 48)
	minimalContentFrame.AutomaticSize = Enum.AutomaticSize.X
	minimalContentFrame.BackgroundTransparency = 1
	minimalContentFrame.BorderSizePixel = 0

	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.fromOffset(48, 48)
	contentFrame.AutomaticSize = Enum.AutomaticSize.XY
	contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	contentFrame.BackgroundTransparency = 0.5
	contentFrame.Visible = false

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = contentFrame

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 2)
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = contentFrame

	contentFrame.Parent = minimalContentFrame

	minimalContentFrame.Parent = parent

	local keys: number = 0

	local inputBeganConnection: RBXScriptConnection = UserInputService.InputBegan:Connect(
		function(inputObject: InputObject)
			if inputObject.KeyCode == Enum.KeyCode.Unknown then
				return
			end

			local visualFrame: Frame = createKeyVisual(inputObject.KeyCode)
			visualFrame.Parent = contentFrame

			keys += 1
			contentFrame.Visible = true

			task.delay(KEY_LIFETIME, function()
				visualFrame:Destroy()

				keys -= 1

				if keys <= 0 and contentFrame then
					contentFrame.Visible = false
				end
			end)
		end
	)

	return function()
		minimalContentFrame:Destroy()
		minimalContentFrame = nil

		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end
end)

return nil
