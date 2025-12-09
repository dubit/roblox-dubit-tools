--!strict
local DebugToolRootPath = script.Parent.Parent.Parent.Parent

local Widget = require(DebugToolRootPath.Widget)

local WIDGET_ACTIVE_BACKGROUND_COLOR = Color3.fromRGB(132, 156, 137)
local WIDGET_HIDDEN_BACKGROUND_COLOR = Color3.fromRGB(147, 115, 137)

local function createWidgetButton(widgetName: string, parent: ScrollingFrame)
	local isWidgetVisible: boolean = Widget:IsVisible(widgetName)

	local textbutton = Instance.new("TextButton")
	textbutton.Name = widgetName
	textbutton.AutoLocalize = false
	textbutton.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	textbutton.Text = ` {widgetName}`
	textbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
	textbutton.TextSize = 12
	textbutton.TextStrokeTransparency = 0.50
	textbutton.TextXAlignment = Enum.TextXAlignment.Left
	textbutton.BackgroundColor3 = isWidgetVisible and WIDGET_ACTIVE_BACKGROUND_COLOR or WIDGET_HIDDEN_BACKGROUND_COLOR
	textbutton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textbutton.BorderSizePixel = 0
	textbutton.Size = UDim2.new(1, 0, 0, 18)

	local buttonActivatedConnection = textbutton.Activated:Connect(function()
		Widget:SwitchVisibility(widgetName)
	end)

	textbutton.Parent = parent

	local widgetMountedConnection = Widget.WidgetMounted:Connect(function(otherWidgetName: string)
		if otherWidgetName ~= widgetName then
			return
		end

		textbutton.BackgroundColor3 = Color3.fromRGB(132, 156, 137)
	end)

	local widgetUnmountedConnection = Widget.WidgetUnmounted:Connect(function(otherWidgetName: string)
		if otherWidgetName ~= widgetName then
			return
		end

		textbutton.BackgroundColor3 = Color3.fromRGB(147, 115, 137)
	end)

	return function()
		textbutton:Destroy()

		buttonActivatedConnection:Disconnect()
		widgetMountedConnection:Disconnect()
		widgetUnmountedConnection:Disconnect()
	end
end

return function(parent: Frame)
	local widgetsList = Instance.new("Frame")
	widgetsList.AnchorPoint = Vector2.new(1, 0)
	widgetsList.Position = UDim2.fromScale(1, 0)
	widgetsList.Size = UDim2.fromScale(0.25, 1)
	widgetsList.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	widgetsList.BackgroundTransparency = 0.50
	widgetsList.BorderSizePixel = 0

	local gradientFrame = Instance.new("Frame")
	gradientFrame.AnchorPoint = Vector2.new(1.00, 0.00)
	gradientFrame.Size = UDim2.fromScale(0.05, 1.00)
	gradientFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	gradientFrame.BackgroundTransparency = 0.8
	gradientFrame.BorderSizePixel = 0

	local uiGradient = Instance.new("UIGradient")
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1.00),
		NumberSequenceKeypoint.new(1.00, 0.00),
	})
	uiGradient.Parent = gradientFrame

	gradientFrame.Parent = widgetsList

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.fromScale(1.00, 1.00)
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrollingFrame.BackgroundTransparency = 1.00
	scrollingFrame.BorderSizePixel = 0

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0.00, 2)
	uiListLayout.SortOrder = Enum.SortOrder.Name
	uiListLayout.Parent = scrollingFrame

	scrollingFrame.Parent = widgetsList

	widgetsList.Parent = parent

	local widgetButtons = {}

	for widgetName in Widget:GetAll() do
		table.insert(widgetButtons, createWidgetButton(widgetName, scrollingFrame))
	end

	local widgetAddedConnection = Widget.WidgetAdded:Connect(function(widgetName)
		table.insert(widgetButtons, createWidgetButton(widgetName, scrollingFrame))
	end)

	return function()
		for _, buttonCleanup in widgetButtons do
			buttonCleanup()
		end

		widgetsList:Destroy()

		widgetAddedConnection:Disconnect()
	end
end
