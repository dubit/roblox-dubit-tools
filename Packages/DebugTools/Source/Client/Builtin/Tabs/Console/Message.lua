--!strict
local DebugToolRootPath = script.Parent.Parent.Parent.Parent

local Style = require(DebugToolRootPath.Style)

export type MessageType = "INFO" | "ERROR" | "WARNING"

export type Message = {
	Content: string,
	ContentShort: string,
	ContentType: MessageType,

	CanExpand: boolean,
	Expanded: boolean,
	Amount: number,
	ServerSide: boolean,

	Timestamp: number,

	MessageTextButton: TextButton?,
	MoreLabel: TextLabel?,
	CountLabel: TextLabel?,

	Expand: (self: Message) -> nil,
	ChangeType: (self: Message, newType: MessageType) -> nil,
	IncreaseCount: (self: Message, count: number) -> nil,
	Concatenate: (self: Message, string: string) -> nil,
	Destroy: (self: Message) -> nil,
}

local MESSAGE_COLORS: { [string]: Color3 } = {
	["INFO"] = Style.COLOR_WHITE,
	["ERROR"] = Color3.fromRGB(255, 81, 70),
	["WARNING"] = Color3.fromRGB(243, 173, 82),
}

local Message = {}
Message.internal = {}
Message.prototype = {}
Message.interface = {}

function Message.internal.createMessageFrame(message: Message, serverSide: boolean)
	local messageBackgroundColor: Color3 = serverSide and Style.COLOR_GREEN or Style.COLOR_BLUE
	local boldMessage: boolean = message.ContentType == "WARNING" or message.ContentType == "ERROR"

	local messageTextButton: TextButton = Instance.new("TextButton")
	messageTextButton.Name = "Console Message"
	messageTextButton.AutoLocalize = false
	messageTextButton.Size = UDim2.new(1.00, 0, 0.00, 12)
	messageTextButton.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		boldMessage and Enum.FontWeight.Bold or Enum.FontWeight.Regular
	)
	messageTextButton.BackgroundColor3 = messageBackgroundColor
	messageTextButton.BackgroundTransparency = 0.80
	messageTextButton.Text = message.ContentShort
	messageTextButton.TextSize = 12
	messageTextButton.TextTruncate = Enum.TextTruncate.AtEnd
	messageTextButton.TextXAlignment = Enum.TextXAlignment.Left
	messageTextButton.TextColor3 = MESSAGE_COLORS[message.ContentType]
	messageTextButton.BorderSizePixel = 0
	messageTextButton.AutomaticSize = Enum.AutomaticSize.Y

	message.MessageTextButton = messageTextButton

	local uiStroke: UIStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.Transparency = 0.60
	uiStroke.Parent = messageTextButton

	local moreLabel: TextLabel = Instance.new("TextLabel")
	moreLabel.Name = "More"
	moreLabel.AutoLocalize = false
	moreLabel.AnchorPoint = Vector2.new(1.00, 0.00)
	moreLabel.Position = UDim2.fromScale(1.00, 0.00)
	moreLabel.Size = UDim2.fromOffset(0, 12)
	moreLabel.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	moreLabel.Text = "..."
	moreLabel.TextColor3 = Style.COLOR_WHITE
	moreLabel.TextSize = 14
	moreLabel.AutomaticSize = Enum.AutomaticSize.X
	moreLabel.BackgroundTransparency = 1.00
	moreLabel.BorderSizePixel = 0
	moreLabel.Visible = false
	moreLabel.Parent = messageTextButton

	message.MoreLabel = moreLabel

	local numberLabel: TextLabel = Instance.new("TextLabel")
	numberLabel.Name = "TextLabel"
	numberLabel.AutoLocalize = false
	numberLabel.AnchorPoint = Vector2.new(1.00, 0.00)
	numberLabel.Position = UDim2.new(1.00, -24, 0.00, 0)
	numberLabel.Size = UDim2.fromScale(0.00, 1.00)
	numberLabel.FontFace = Style.FONT_BOLD
	numberLabel.Text = "x1"
	numberLabel.TextColor3 = Style.COLOR_WHITE
	numberLabel.TextSize = 12
	numberLabel.AutomaticSize = Enum.AutomaticSize.X
	numberLabel.BackgroundColor3 = Style.COLOR_BLACK
	numberLabel.BackgroundTransparency = 0.25
	numberLabel.BorderSizePixel = 0
	numberLabel.Visible = false
	numberLabel.Parent = messageTextButton

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingLeft = UDim.new(0.00, 2)
	uiPadding.PaddingRight = UDim.new(0.00, 2)
	uiPadding.Parent = numberLabel

	local messageSideFrame = Instance.new("Frame")
	messageSideFrame.Name = "Frame"
	messageSideFrame.AnchorPoint = Vector2.new(1, 0)
	messageSideFrame.BackgroundColor3 = messageBackgroundColor
	messageSideFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	messageSideFrame.BorderSizePixel = 0
	messageSideFrame.Size = UDim2.new(0, 4, 1, 0)
	messageSideFrame.Parent = messageTextButton

	message.CountLabel = numberLabel
end

function Message.prototype:SetParent(parent: GuiBase)
	self.MessageTextButton.Parent = parent
end

function Message.prototype:Destroy()
	self.MessageTextButton:Destroy()
	self.MessageTextButton = nil

	self._TextButtonActivatedConnection:Disconnect()
	self._TextButtonActivatedConnection = nil
end

function Message.prototype:Concatenate(message: string)
	self.Content ..= message

	local newLineIndex: number = string.find(self.Content, "\n") or 0
	local shortMessage: string = newLineIndex > 0 and string.sub(self.Content, 0, newLineIndex - 1) or self.Content

	self.ContentShort = shortMessage
	self.CanExpand = newLineIndex > 0

	self.MoreLabel.Visible = newLineIndex ~= nil

	self.MessageTextButton.Text = self.Expanded and self.Content or self.ContentShort
end

function Message.prototype:IncreaseCount(number: number?)
	self.Amount += number or 1

	self.CountLabel.Visible = true
	self.CountLabel.Text = `x{self.Amount}`
end

function Message.prototype:ChangeType(newType: MessageType)
	self.ContentType = newType
	self.MessageTextButton.BackgroundColor3 = MESSAGE_COLORS[self.ContentType] or Style.PRIMARY_DARK
end

function Message.prototype:Expand()
	if not self.CanExpand then
		return
	end

	self.Expanded = not self.Expanded

	self.MessageTextButton.Text = self.Expanded and self.Content or self.ContentShort
end

function Message.interface.new(
	message: string,
	messageType: MessageType,
	isServerSide: boolean?,
	timestamp: number?
): Message
	local serverSide: boolean = isServerSide or false
	local newLineIndex: number? = string.find(message, "\n")
	local shortMessage: string = newLineIndex and string.sub(message, 0, newLineIndex - 1) or message

	local self = setmetatable({
		Content = message,
		ContentShort = shortMessage,
		ContentType = messageType,
		ServerSide = serverSide,

		CanExpand = newLineIndex ~= nil,
		Expanded = false,
		Amount = 1,

		Timestamp = timestamp or os.clock(),
	}, {
		__index = Message.prototype,
	})

	Message.internal.createMessageFrame(self, serverSide)

	self.MoreLabel.Visible = self.CanExpand

	self._TextButtonActivatedConnection = self.MessageTextButton.Activated:Connect(function()
		self:Expand()
	end)

	return self
end

return Message.interface
