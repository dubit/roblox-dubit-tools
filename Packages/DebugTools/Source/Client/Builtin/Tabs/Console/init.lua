--!strict
local Players = game:GetService("Players")
local LogService = game:GetService("LogService")

local DebugToolRootPath = script.Parent.Parent.Parent
local SharedRootPath = DebugToolRootPath.Parent.Shared

local Tab = require(DebugToolRootPath.Tab)
local Style = require(DebugToolRootPath.Style)
local Networking = require(DebugToolRootPath.Networking)

local Signal = require(SharedRootPath.Signal)

local Message = require(script.Message)
local OutputModal = require(script.OutputModal)

local MAX_MESSAGES: number = 400

local TYPE_PARSER: { [Enum.MessageType | string]: "ERROR" | "WARNING" | "INFO" } = {
	[Enum.MessageType.MessageError] = "ERROR",
	[Enum.MessageType.MessageWarning] = "WARNING",
	[Enum.MessageType.MessageOutput] = "INFO",
	Default = "INFO",
}

table.freeze(TYPE_PARSER)

local ConsoleModule = {}
ConsoleModule.internal = {
	Messages = {} :: { Message.Message },
	LatestMessage = nil :: Message.Message?,

	ParsingMessageStack = false,
	BreakpointNumber = 0,

	Interface = {
		ConsoleFrame = nil :: Frame?,
		MessagesScrollingFrame = nil :: ScrollingFrame?,
	},
}
ConsoleModule.interface = {
	MessageAdded = Signal.new(),
}

function ConsoleModule.internal.mergeLatestExactMessages()
	local internalMessages: { Message.Message } = ConsoleModule.internal.Messages
	local messagesCount: number = #internalMessages

	if messagesCount < 2 then
		return
	end

	local minusOneMessage: any = internalMessages[messagesCount - 1]
	local lastMessage: any = internalMessages[messagesCount]

	local matchingContent: boolean = lastMessage.Content == minusOneMessage.Content
	local matchingType: boolean = lastMessage.ContentType == minusOneMessage.ContentType

	if matchingType and matchingContent then
		minusOneMessage:IncreaseCount()

		lastMessage:Destroy()
		table.remove(internalMessages, table.find(internalMessages, lastMessage))

		ConsoleModule.internal.LatestMessage = minusOneMessage
	end
end

function ConsoleModule.internal.createModuleInterface()
	local consoleFrame: Frame = Instance.new("Frame")
	consoleFrame.Size = UDim2.fromScale(1.00, 1.00)
	consoleFrame.BackgroundTransparency = 1.00
	consoleFrame.BorderSizePixel = 0
	consoleFrame.Parent = script

	local messagesList: ScrollingFrame = Instance.new("ScrollingFrame")
	messagesList.Name = "Messages"
	messagesList.Size = UDim2.new(1.00, 0, 1.00, -20)
	messagesList.CanvasSize = UDim2.new(0.00, 0, 0.00, 0)
	messagesList.BackgroundColor3 = Style.COLOR_BLACK
	messagesList.BackgroundTransparency = 0.50
	messagesList.TopImage = messagesList.MidImage
	messagesList.BottomImage = messagesList.MidImage
	messagesList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	messagesList.ScrollingDirection = Enum.ScrollingDirection.Y
	messagesList.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	messagesList.BorderSizePixel = 0
	messagesList.Parent = consoleFrame

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 1)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = messagesList

	local messagesListPadding: UIPadding = Instance.new("UIPadding")
	messagesListPadding.Name = "UIPadding"
	messagesListPadding.PaddingLeft = UDim.new(0, 8)
	messagesListPadding.PaddingRight = UDim.new(0, 8)
	messagesListPadding.PaddingTop = UDim.new(0, 8)
	messagesListPadding.PaddingBottom = UDim.new(0, 8)
	messagesListPadding.Parent = messagesList

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 10)
	uiPadding.Parent = consoleFrame

	local bottomButtons: Frame = Instance.new("Frame")
	bottomButtons.Name = "Bottom Buttons"
	bottomButtons.AnchorPoint = Vector2.new(0.00, 1.00)
	bottomButtons.Position = UDim2.new(0.00, 0, 1.00, 0)
	bottomButtons.Size = UDim2.new(1.00, 0, 0.00, 12)
	bottomButtons.BackgroundTransparency = 1.00
	bottomButtons.BorderSizePixel = 0
	bottomButtons.Parent = consoleFrame

	local bottomUILayout: UIListLayout = Instance.new("UIListLayout")
	bottomUILayout.Name = "UIListLayout"
	bottomUILayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomUILayout.FillDirection = Enum.FillDirection.Horizontal
	bottomUILayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	bottomUILayout.Padding = UDim.new(0, 8)
	bottomUILayout.Parent = bottomButtons

	local clearButton: TextButton = Instance.new("TextButton")
	clearButton.Size = UDim2.fromOffset(0, 12)
	clearButton.AutoLocalize = false
	clearButton.BackgroundColor3 = Style.COLOR_RED
	clearButton.AutomaticSize = Enum.AutomaticSize.X
	clearButton.BorderSizePixel = 0
	clearButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	clearButton.Text = "Clear"
	clearButton.TextSize = 12
	clearButton.LayoutOrder = 3
	clearButton.Parent = bottomButtons

	local clearButtonPadding: UIPadding = Instance.new("UIPadding")
	clearButtonPadding.Name = "UIPadding"
	clearButtonPadding.PaddingLeft = UDim.new(0, 8)
	clearButtonPadding.PaddingRight = UDim.new(0, 8)
	clearButtonPadding.Parent = clearButton

	clearButton.Activated:Connect(function()
		ConsoleModule.interface:ClearOutput()
	end)

	local breakpointButton: TextButton = Instance.new("TextButton")
	breakpointButton.AutoLocalize = false
	breakpointButton.Size = UDim2.fromOffset(0, 12)
	breakpointButton.BackgroundColor3 = Style.TAB_FOCUSED_BACKGROUND
	breakpointButton.AutomaticSize = Enum.AutomaticSize.X
	breakpointButton.BorderSizePixel = 0
	breakpointButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	breakpointButton.Text = "Breakpoint (1)"
	breakpointButton.TextSize = 12
	breakpointButton.LayoutOrder = 1
	breakpointButton.Parent = bottomButtons

	local breakpointButtonPadding: UIPadding = Instance.new("UIPadding")
	breakpointButtonPadding.Name = "UIPadding"
	breakpointButtonPadding.PaddingLeft = UDim.new(0, 8)
	breakpointButtonPadding.PaddingRight = UDim.new(0, 8)
	breakpointButtonPadding.Parent = breakpointButton

	breakpointButton.Activated:Connect(function()
		ConsoleModule.internal.BreakpointNumber += 1

		breakpointButton.Text = `Breakpoint ({ConsoleModule.internal.BreakpointNumber + 1})`

		ConsoleModule.interface:AddMessage(
			`Breakpoint {ConsoleModule.internal.BreakpointNumber}`,
			Enum.MessageType.MessageInfo,
			false
		)
	end)

	local outputButton: TextButton = Instance.new("TextButton")
	outputButton.AutoLocalize = false
	outputButton.Size = UDim2.fromOffset(0, 12)
	outputButton.BackgroundColor3 = Style.TAB_FOCUSED_BACKGROUND
	outputButton.AutomaticSize = Enum.AutomaticSize.X
	outputButton.BorderSizePixel = 0
	outputButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	outputButton.Text = "Output Log"
	outputButton.TextSize = 12
	outputButton.LayoutOrder = 2
	outputButton.Parent = bottomButtons

	local outputButtonPadding: UIPadding = Instance.new("UIPadding")
	outputButtonPadding.Name = "UIPadding"
	outputButtonPadding.PaddingLeft = UDim.new(0, 8)
	outputButtonPadding.PaddingRight = UDim.new(0, 8)
	outputButtonPadding.Parent = outputButton

	outputButton.Activated:Connect(function()
		local outputModal = OutputModal.new(ConsoleModule.interface:GetOutputLog())
		outputModal:ParentTo(consoleFrame)
		outputModal.CloseActivated:Connect(function()
			outputModal:Destroy()
			outputModal = nil
		end)
	end)

	ConsoleModule.internal.Interface.ConsoleFrame = consoleFrame
	ConsoleModule.internal.Interface.MessagesScrollingFrame = messagesList
end

function ConsoleModule.interface:GetOutputLog(): string
	local currentDate = os.date(`*t`)
	local currentDateFormatted: string =
		`{string.format("%02d", currentDate.hour)}:{string.format("%02d", currentDate.min)}:{string.format(
			"%02d",
			currentDate.sec
		)}/{string.format("%02d", currentDate.day)}.{string.format("%02d", currentDate.month)}.{currentDate.year}`
	local outputLog: string =
		`p{game.PlaceId}_v{game.PlaceVersion}_{os.time()}\nGenerated at [{currentDateFormatted}] by {Players.LocalPlayer.Name}@{Players.LocalPlayer.DisplayName}\n`

	for _, messageData in ConsoleModule.internal.Messages do
		local milliseconds: string =
			tostring(math.floor((messageData.Timestamp - math.floor(messageData.Timestamp)) * 1000))
		local messageCount: string = messageData.Amount > 1 and `[x{messageData.Amount}]` or ""

		outputLog ..= `{messageCount}[{messageData.ServerSide and "SERVER" or "CLIENT"}][{os.date(
			`%X`,
			messageData.Timestamp
		)}.{milliseconds}][{messageData.ContentType}] {messageData.Content}\n`
	end

	return outputLog
end

function ConsoleModule.internal:Init()
	ConsoleModule.internal.createModuleInterface()

	for _, messageData in LogService:GetLogHistory() do
		ConsoleModule.interface:AddMessage(messageData.message, messageData.messageType, false, messageData.timestamp)
	end

	LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
		ConsoleModule.interface:AddMessage(message, messageType, false)
	end)

	Networking:SubscribeToTopic(
		"console_messages",
		function(messageType: Enum.MessageType, message: string, timestamp: number)
			ConsoleModule.interface:AddMessage(message, messageType, true, timestamp)
		end
	)
end

function ConsoleModule.internal:MountInterface(parent: Frame)
	if not ConsoleModule.internal.Interface.ConsoleFrame then
		return
	end

	ConsoleModule.internal.Interface.ConsoleFrame.Parent = parent
end

function ConsoleModule.internal:UnmountInterface()
	if not ConsoleModule.internal.Interface.ConsoleFrame then
		return
	end

	ConsoleModule.internal.Interface.ConsoleFrame.Parent = script
end

function ConsoleModule.interface:AddMessage(
	message: string,
	messageType: Enum.MessageType,
	isServerSide: boolean,
	timestamp: number?
)
	if ConsoleModule.internal.LatestMessage and messageType == Enum.MessageType.MessageInfo then
		if message == "Stack Begin" then
			ConsoleModule.internal.ParsingMessageStack = true

			-- The errors report stack trace as an information not as a part of the error message.
			if ConsoleModule.internal.LatestMessage.ContentType == "INFO" then
				ConsoleModule.internal.LatestMessage:ChangeType("ERROR")
			end
			return
		elseif message == "Stack End" then
			ConsoleModule.internal.ParsingMessageStack = false
			return
		end

		if ConsoleModule.internal.ParsingMessageStack then
			ConsoleModule.internal.LatestMessage:Concatenate(`\n  ╠ {message}`)
			ConsoleModule.internal.mergeLatestExactMessages()
			return
		end
	end

	local convertedMessageType: string = TYPE_PARSER[messageType] or TYPE_PARSER.Default

	local newMessage = Message.new(message, convertedMessageType, isServerSide, timestamp)
	newMessage:SetParent(ConsoleModule.internal.Interface.MessagesScrollingFrame)

	table.insert(ConsoleModule.internal.Messages, newMessage)

	if #ConsoleModule.internal.Messages > MAX_MESSAGES then
		ConsoleModule.internal.Messages[1]:Destroy()

		table.remove(ConsoleModule.internal.Messages, 1)
	end

	ConsoleModule.internal.LatestMessage = newMessage

	ConsoleModule.internal.mergeLatestExactMessages()

	ConsoleModule.interface.MessageAdded:Fire(message, convertedMessageType)
end

function ConsoleModule.interface:ClearOutput()
	for _, message in ConsoleModule.internal.Messages do
		message:Destroy()
	end

	ConsoleModule.internal.Messages = {}
	ConsoleModule.internal.ParsingMessageStack = false
end

ConsoleModule.internal:Init()

Tab.new("Console", function(parent: Frame)
	ConsoleModule.internal:MountInterface(parent)

	return function()
		ConsoleModule.internal:UnmountInterface()
	end
end)

return ConsoleModule.interface
