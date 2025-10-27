--! strict
local DebugToolRootPath = script.Parent.Parent.Parent.Parent.Parent
local SharedRootPath = DebugToolRootPath.Shared

local Signal = require(SharedRootPath.Signal)

local OutputModal = {}
OutputModal.internal = {}
OutputModal.prototype = {}
OutputModal.interface = {}

function OutputModal.internal.createModalInterface(modal, outputLog: string)
	local frame = Instance.new("Frame")
	frame.Name = "Output Modal"
	frame.Size = UDim2.fromScale(1.00, 1.00)
	frame.BackgroundColor3 = Color3.fromRGB(79, 88, 105)
	frame.BackgroundTransparency = 0.10
	frame.BorderColor3 = Color3.fromRGB(79, 88, 105)
	frame.BorderSizePixel = 10
	frame.ZIndex = 10

	local inputCatcher: TextButton = Instance.new("TextButton")
	inputCatcher.AutoLocalize = false
	inputCatcher.Position = UDim2.fromOffset(-8, -8)
	inputCatcher.Size = UDim2.new(1.00, 16, 1.00, 16)
	inputCatcher.BackgroundTransparency = 1.00
	inputCatcher.Text = ""
	inputCatcher.ZIndex = -1
	inputCatcher.Parent = frame

	local infoLabel: TextLabel = Instance.new("TextLabel")
	infoLabel.AutoLocalize = false
	infoLabel.Name = "TextLabel"
	infoLabel.AnchorPoint = Vector2.new(0, 1)
	infoLabel.Position = UDim2.fromScale(0, 1)
	infoLabel.Size = UDim2.new(1, 0, 0, 12)
	infoLabel.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	infoLabel.Text = "Copy the above message and paste it into a file."
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.TextSize = 12
	infoLabel.TextStrokeTransparency = 0.5
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.BackgroundTransparency = 1
	infoLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	infoLabel.BorderSizePixel = 0
	infoLabel.Parent = frame

	local logOutput: TextBox = Instance.new("TextBox")
	logOutput.AutoLocalize = false
	logOutput.Name = "TextBox"
	logOutput.Position = UDim2.fromOffset(0, 16)
	logOutput.Size = UDim2.new(1, 0, 1, -30)
	logOutput.ClearTextOnFocus = false
	logOutput.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	logOutput.Text = outputLog
	logOutput.TextColor3 = Color3.fromRGB(255, 255, 255)
	logOutput.TextSize = 12
	logOutput.TextTruncate = Enum.TextTruncate.AtEnd
	logOutput.TextWrapped = true
	logOutput.TextXAlignment = Enum.TextXAlignment.Left
	logOutput.TextYAlignment = Enum.TextYAlignment.Top
	logOutput.Active = false
	logOutput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	logOutput.BackgroundTransparency = 0.5
	logOutput.BorderSizePixel = 0
	logOutput.TextEditable = false
	logOutput.ZIndex = 10
	logOutput.Parent = frame

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = frame

	local closeButton: TextButton = Instance.new("TextButton")
	closeButton.AutoLocalize = false
	closeButton.Name = "Close Button"
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, 8, 0, -8)
	closeButton.Size = UDim2.fromOffset(32, 16)
	closeButton.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	closeButton.TextSize = 16
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 81, 70)
	closeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	closeButton.BorderSizePixel = 0
	closeButton.Parent = frame

	modal.CloseButtonActivatedConnection = closeButton.Activated:Connect(function()
		modal.CloseActivated:Fire()
	end)

	return frame
end

function OutputModal.prototype:ParentTo(parent: GuiBase)
	self.ModalFrame.Parent = parent
end

function OutputModal.prototype:Destroy()
	self.ModalFrame:Destroy()
	self.ModalFrame = nil

	self.CloseActivated:Destroy()
	self.CloseActivated = nil

	self.CloseButtonActivatedConnection:Disconnect()
	self.CloseButtonActivatedConnection = nil
end

function OutputModal.interface.new(outputLog: string)
	local self = setmetatable({
		ModalFrame = nil,

		CloseActivated = Signal.new(),
	}, {
		__index = OutputModal.prototype,
	})

	self.ModalFrame = OutputModal.internal.createModalInterface(self, outputLog)

	return self
end

return OutputModal.interface
