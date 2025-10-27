--!strict
local DebugToolRootPath = script.Parent.Parent
local SharedRootPath = DebugToolRootPath.Parent.Shared

local Signal = require(SharedRootPath.Signal)

local Style = require(DebugToolRootPath.Style)

local TabFrame = {}
TabFrame.prototype = {}
TabFrame.interface = {}

function TabFrame.prototype:Focus()
	self.TabButton.TextColor3 = Style.TAB_FOCUSED_TEXT
	self.TabButton.BackgroundColor3 = Style.TAB_FOCUSED_BACKGROUND
end

function TabFrame.prototype:Unfocus()
	self.TabButton.TextColor3 = Style.TAB_NORMAL_TEXT
	self.TabButton.BackgroundColor3 = Style.TAB_NORMAL_BACKGROUND
end

function TabFrame.prototype:Destroy()
	self.TabActivated:Destroy()

	self.TabButton:Destroy()
	self.ButtonActivatedConnection:Disconnect()
end

function TabFrame.interface.new(moduleName: string, tabParent: Frame)
	local tabTextButton: TextButton = Instance.new("TextButton")
	tabTextButton.Name = moduleName
	tabTextButton.AutoLocalize = false
	tabTextButton.Size = UDim2.fromScale(0.00, 1.00)
	tabTextButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	tabTextButton.Text = moduleName
	tabTextButton.TextColor3 = Style.TAB_NORMAL_TEXT
	tabTextButton.TextSize = 14
	tabTextButton.AutomaticSize = Enum.AutomaticSize.X
	tabTextButton.BackgroundColor3 = Style.TAB_NORMAL_BACKGROUND
	tabTextButton.BorderSizePixel = 0

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.Parent = tabTextButton

	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(0.00, 4)
	uiCorner.Parent = tabTextButton

	tabTextButton.Parent = tabParent

	local tabActivatedSignal = Signal.new()

	local self = setmetatable({
		Module = moduleName,

		TabActivated = tabActivatedSignal,

		TabButton = tabTextButton,
		ButtonActivatedConnection = tabTextButton.Activated:Connect(function()
			tabActivatedSignal:Fire()
		end),
	}, {
		__index = TabFrame.prototype,
	})

	return self
end

return TabFrame.interface
