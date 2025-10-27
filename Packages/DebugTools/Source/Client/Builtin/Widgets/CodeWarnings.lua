--!strict
local RunService = game:GetService("RunService")
local DebugToolRootPath = script.Parent.Parent.Parent

local Console = require(DebugToolRootPath.Builtin.Tabs.Console)

local Widget = require(DebugToolRootPath.Widget)
local Style = require(DebugToolRootPath.Style)

type MessageData = {
	Message: string,
	Type: string,
	Amount: number,
	TextLabel: TextLabel,
	Lifetime: number,
}

local CodeWarnings = {}
CodeWarnings.internal = {
	ContentFrame = nil :: Frame?,
	OnScreenMessages = {} :: {
		[number]: MessageData,
	},
}

function CodeWarnings.internal.createOutputLabel(): TextLabel
	local outputLabel: TextLabel = Instance.new("TextLabel")
	outputLabel.Name = "OutputLabel"
	outputLabel.AutoLocalize = false
	outputLabel.FontFace = Style.FONT_BOLD
	outputLabel.TextColor3 = Color3.fromRGB(255, 81, 70)
	outputLabel.TextSize = 14
	outputLabel.TextStrokeTransparency = 0.50
	outputLabel.TextWrapped = true
	outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	outputLabel.AutomaticSize = Enum.AutomaticSize.XY
	outputLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	outputLabel.BackgroundTransparency = 0.50

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 4)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 4)
	uiPadding.Parent = outputLabel

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = outputLabel

	local uiSizeConstraint: UISizeConstraint = Instance.new("UISizeConstraint")
	uiSizeConstraint.Name = "UISizeConstraint"
	uiSizeConstraint.MaxSize = Vector2.new(500, math.huge)
	uiSizeConstraint.Parent = outputLabel

	return outputLabel
end

function CodeWarnings.internal.getLatestMessageData(): MessageData?
	local messagesCount: number = #CodeWarnings.internal.OnScreenMessages
	if messagesCount == 0 then
		return
	end

	return CodeWarnings.internal.OnScreenMessages[messagesCount]
end

function CodeWarnings.internal.addMessage(message: string, messageType: string)
	local latestMessageData = CodeWarnings.internal.getLatestMessageData()
	if latestMessageData and (latestMessageData.Message == message and latestMessageData.Type == messageType) then
		latestMessageData.Amount += 1
		latestMessageData.Lifetime = 6.00

		local amountLabel: string = latestMessageData.Amount < 99 and tostring(latestMessageData.Amount) or "99+"
		latestMessageData.TextLabel.Text = `(x{amountLabel}) {latestMessageData.Message}`
		return
	end

	local outputLabel = CodeWarnings.internal.createOutputLabel()
	outputLabel.Text = message

	if messageType == "WARNING" then
		outputLabel.TextColor3 = Style.COLOR_ORANGE
	elseif messageType == "ERROR" then
		outputLabel.TextColor3 = Style.COLOR_RED
	end

	outputLabel.Parent = CodeWarnings.internal.ContentFrame

	table.insert(CodeWarnings.internal.OnScreenMessages, {
		Message = message,
		Type = messageType,
		Amount = 1,
		TextLabel = outputLabel,
		Lifetime = 6.00,
	})
end

RunService.Heartbeat:Connect(function(deltaTime: number)
	for messageIndex: number, messageData: MessageData in CodeWarnings.internal.OnScreenMessages do
		messageData.Lifetime -= deltaTime

		if messageData.Lifetime > 0.00 then
			continue
		end

		messageData.TextLabel:Destroy()
		table.remove(CodeWarnings.internal.OnScreenMessages, messageIndex)
	end
end)

Widget.new("Code Warnings", function(parent: ScreenGui)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.new(0.00, 8, 0.00, 48)
	content.Size = UDim2.fromOffset(32, 32)
	content.BackgroundTransparency = 1.00
	content.AutomaticSize = Enum.AutomaticSize.XY

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 4)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = content

	content.Parent = parent

	CodeWarnings.internal.ContentFrame = content

	local messageAddedConnection = Console.MessageAdded:Connect(function(message: string, messageType: string)
		if messageType == "INFO" then
			return
		end

		CodeWarnings.internal.addMessage(message, messageType)
	end)

	return function()
		for _, messageData: MessageData in CodeWarnings.internal.OnScreenMessages do
			messageData.TextLabel:Destroy()
		end

		CodeWarnings.internal.OnScreenMessages = {}

		messageAddedConnection:Disconnect()

		content:Destroy()
	end
end)

return nil
