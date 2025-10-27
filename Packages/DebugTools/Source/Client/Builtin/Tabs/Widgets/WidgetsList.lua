--!strict
local DebugToolRootPath = script.Parent.Parent.Parent.Parent

local Widget = require(DebugToolRootPath.Widget)

local WIDGET_ACTIVE_COLOR: Color3 = Color3.fromRGB(183, 241, 77)
local WIDGET_ACTIVE_BACKGROUND_COLOR: Color3 = Color3.fromRGB(132, 156, 137)
local WIDGET_HIDDEN_COLOR: Color3 = Color3.fromRGB(241, 77, 77)
local WIDGET_HIDDEN_BACKGROUND_COLOR: Color3 = Color3.fromRGB(147, 115, 137)

local function createWidgetButton(widgetName: string, parent: ScrollingFrame)
	local isWidgetVisible: boolean = Widget:IsVisible(widgetName)

	local textbutton: TextButton = Instance.new("TextButton")
	textbutton.Name = widgetName
	textbutton.AutoLocalize = false
	textbutton.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	textbutton.Text = ` {widgetName}`
	textbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
	textbutton.TextSize = 12
	textbutton.TextStrokeTransparency = 0
	textbutton.TextXAlignment = Enum.TextXAlignment.Left
	textbutton.BackgroundColor3 = isWidgetVisible and WIDGET_ACTIVE_BACKGROUND_COLOR or WIDGET_HIDDEN_BACKGROUND_COLOR
	textbutton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textbutton.BorderSizePixel = 0
	textbutton.Size = UDim2.new(1, 0, 0, 18)

	local buttonActivatedConnection = textbutton.Activated:Connect(function()
		Widget:SwitchVisibility(widgetName)
	end)

	local statusBlob: Frame = Instance.new("Frame")
	statusBlob.Name = "Frame"
	statusBlob.AnchorPoint = Vector2.new(0, 0.5)
	statusBlob.BackgroundColor3 = isWidgetVisible and WIDGET_ACTIVE_COLOR or WIDGET_HIDDEN_COLOR
	statusBlob.BorderColor3 = Color3.fromRGB(0, 0, 0)
	statusBlob.BorderSizePixel = 0
	statusBlob.Position = UDim2.new(1, -12, 0.5, 0)
	statusBlob.Size = UDim2.new(0, 100, 0.3, 0)

	local uiAspectRatioConstraint: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uiAspectRatioConstraint.Parent = statusBlob

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = statusBlob

	local uiStroke: UIStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.Color = Color3.fromRGB(81, 88, 104)
	uiStroke.Parent = statusBlob

	statusBlob.Parent = textbutton

	textbutton.Parent = parent

	local widgetMountedConnection = Widget.WidgetMounted:Connect(function(otherWidgetName: string)
		if otherWidgetName ~= widgetName then
			return
		end

		statusBlob.BackgroundColor3 = Color3.fromRGB(183, 241, 77)
		textbutton.BackgroundColor3 = Color3.fromRGB(132, 156, 137)
	end)

	local widgetUnmountedConnection = Widget.WidgetUnmounted:Connect(function(otherWidgetName: string)
		if otherWidgetName ~= widgetName then
			return
		end

		statusBlob.BackgroundColor3 = Color3.fromRGB(241, 77, 77)
		textbutton.BackgroundColor3 = Color3.fromRGB(147, 115, 137)
	end)

	return function()
		buttonActivatedConnection:Disconnect()
		buttonActivatedConnection = nil

		widgetMountedConnection:Disconnect()
		widgetMountedConnection = nil

		widgetUnmountedConnection:Disconnect()
		widgetUnmountedConnection = nil

		textbutton:Destroy()
		textbutton = nil
	end
end

return function(parent: Frame)
	local widgetsList: Frame = Instance.new("Frame")
	widgetsList.Name = "Widgets List"
	widgetsList.AnchorPoint = Vector2.new(1, 0)
	widgetsList.BackgroundColor3 = Color3.fromRGB(172, 195, 245)
	widgetsList.BorderColor3 = Color3.fromRGB(0, 0, 0)
	widgetsList.BorderSizePixel = 0
	widgetsList.Position = UDim2.fromScale(1, 0)
	widgetsList.Size = UDim2.fromScale(0.25, 1)

	local gradientFrame: Frame = Instance.new("Frame")
	gradientFrame.Name = "Gradient"
	gradientFrame.AnchorPoint = Vector2.new(1.00, 0.00)
	gradientFrame.Size = UDim2.fromScale(0.05, 1.00)
	gradientFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	gradientFrame.BackgroundTransparency = 0.8
	gradientFrame.BorderSizePixel = 0

	local uiGradient: UIGradient = Instance.new("UIGradient")
	uiGradient.Name = "UIGradient"
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00),
		NumberSequenceKeypoint.new(1.00, 0.00),
	})
	uiGradient.Parent = gradientFrame

	gradientFrame.Parent = widgetsList

	local scrollingFrame: ScrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Size = UDim2.fromScale(1.00, 1.00)
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrollingFrame.BackgroundTransparency = 1.00
	scrollingFrame.BorderSizePixel = 0

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 2)
	uiListLayout.SortOrder = Enum.SortOrder.Name
	uiListLayout.Parent = scrollingFrame

	scrollingFrame.Parent = widgetsList

	widgetsList.Parent = parent

	local widgetButtons = {}

	for widgetName: string in Widget:GetAll() do
		table.insert(widgetButtons, createWidgetButton(widgetName, scrollingFrame))
	end

	local widgetAddedConnection = Widget.WidgetAdded:Connect(function(widgetName)
		table.insert(widgetButtons, createWidgetButton(widgetName, scrollingFrame))
	end)

	return function()
		for _, buttonCleanup in widgetButtons do
			buttonCleanup()
		end

		widgetAddedConnection:Disconnect()
		widgetAddedConnection = nil

		widgetsList:Destroy()
		widgetsList = nil
	end
end
