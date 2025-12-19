--!strict
local RunService = game:GetService("RunService")
local DebugToolRootPath = script.Parent.Parent.Parent

local Console = require(DebugToolRootPath.Console)

local IMGui = require(DebugToolRootPath.IMGui)
local Widget = require(DebugToolRootPath.Widget)

local IMGuiConfig = IMGui:GetConfig()

local WARN_COLOR = Color3.fromRGB(243, 173, 82)
local ERROR_COLOR = Color3.fromRGB(255, 81, 70)

type MessageData = {
	Message: string,
	Type: Enum.MessageType,
	Amount: number,
	TextLabel: TextLabel,
	Lifetime: number,
}

local CodeWarnings = {}
CodeWarnings.internal = {
	ContentFrame = nil :: Frame?,
	OnScreenMessages = {} :: { MessageData },
}

function CodeWarnings.internal.createOutputLabel(): TextLabel
	local outputLabel = Instance.new("TextLabel")
	outputLabel.AutoLocalize = false
	outputLabel.FontFace = IMGuiConfig.Font
	outputLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	outputLabel.TextSize = 14
	outputLabel.TextStrokeTransparency = 1.00
	outputLabel.TextWrapped = true
	outputLabel.TextXAlignment = Enum.TextXAlignment.Left
	outputLabel.AutomaticSize = Enum.AutomaticSize.XY
	outputLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	outputLabel.BackgroundTransparency = 0.50

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0.00, 4)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 4)
	uiPadding.Parent = outputLabel

	local uiCorner = Instance.new("UICorner")
	uiCorner.Parent = outputLabel

	local uiSizeConstraint = Instance.new("UISizeConstraint")
	uiSizeConstraint.MaxSize = Vector2.new(500, math.huge)
	uiSizeConstraint.Parent = outputLabel

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Transparency = 0.50
	uiStroke.Parent = outputLabel

	return outputLabel
end

function CodeWarnings.internal.getLatestMessageData(): MessageData?
	local messagesCount = #CodeWarnings.internal.OnScreenMessages
	if messagesCount == 0 then
		return
	end

	return CodeWarnings.internal.OnScreenMessages[messagesCount]
end

function CodeWarnings.internal.addMessage(message: string, messageType: Enum.MessageType)
	if messageType == Enum.MessageType.MessageOutput then
		return
	end

	local latestMessageData = CodeWarnings.internal.getLatestMessageData()
	if latestMessageData and (latestMessageData.Message == message and latestMessageData.Type == messageType) then
		latestMessageData.Amount += 1
		latestMessageData.Lifetime = 6.00

		local amountLabel = latestMessageData.Amount < 99 and tostring(latestMessageData.Amount) or "99+"
		latestMessageData.TextLabel.Text = `(x{amountLabel}) {latestMessageData.Message}`
		return
	end

	local outputLabel = CodeWarnings.internal.createOutputLabel()
	outputLabel.Text = message

	if messageType == Enum.MessageType.MessageWarning then
		outputLabel.TextColor3 = WARN_COLOR
	elseif messageType == Enum.MessageType.MessageError then
		outputLabel.TextColor3 = ERROR_COLOR
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
	for index, message in CodeWarnings.internal.OnScreenMessages do
		message.Lifetime -= deltaTime

		if message.Lifetime > 0.00 then
			continue
		end

		message.TextLabel:Destroy()
		table.remove(CodeWarnings.internal.OnScreenMessages, index)
	end
end)

Widget.new("Code Warnings", function(parent: ScreenGui)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Position = UDim2.new(0.00, 8, 0.00, 48)
	content.Size = UDim2.fromOffset(32, 32)
	content.BackgroundTransparency = 1.00
	content.AutomaticSize = Enum.AutomaticSize.XY

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 4)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = content

	content.Parent = parent

	CodeWarnings.internal.ContentFrame = content

	local messageAddedConnection = Console.MessageAdded:Connect(function(message, messageType)
		if messageType == Enum.MessageType.MessageInfo then
			return
		end

		CodeWarnings.internal.addMessage(message, messageType)
	end)

	return function()
		for _, messageData in CodeWarnings.internal.OnScreenMessages do
			messageData.TextLabel:Destroy()
		end

		CodeWarnings.internal.OnScreenMessages = {}

		messageAddedConnection:Disconnect()

		content:Destroy()
	end
end)

return nil
