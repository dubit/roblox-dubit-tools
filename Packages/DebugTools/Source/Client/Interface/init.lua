--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local insetSize: Vector2 = GuiService:GetGuiInset()

local DebugToolRootPath = script.Parent
local SharedPath = DebugToolRootPath.Parent.Shared

local Tab = require(DebugToolRootPath.Tab)
local Style = require(DebugToolRootPath.Style)

local Constants = require(SharedPath.Constants)

local TabFrame = require(script.TabFrame)

local DebugInterface = {}
DebugInterface.internal = {
	Tabs = {} :: { [string]: any },

	ActiveTab = nil :: {
		Name: string,
		Destructor: () -> nil,
	}?,

	ActiveContentTabFrame = nil :: Frame?,
}
DebugInterface.private = {
	Dragging = false,
	InterfaceCreated = false,

	InterfaceElements = {
		Tabs = nil,
		ContentFrame = nil :: Frame?,
		ScreenGui = nil :: ScreenGui?,
	},

	Tabs = {},
}
DebugInterface.interface = {}

function DebugInterface.internal.focusModule(tabName: string)
	local activeTab = DebugInterface.internal.ActiveTab
	if activeTab and activeTab.Name == tabName then
		return
	end

	local tabConstructor = Tab.getTabConstructor(tabName)
	if not tabConstructor then
		return
	end

	local activeContentTabFrame: Frame? = DebugInterface.internal.ActiveContentTabFrame
	if not activeContentTabFrame then
		return
	end

	if activeTab then
		DebugInterface.internal.Tabs[activeTab.Name]:Unfocus()
		activeTab.Destructor()

		local contentTabFrameChildren: { Instance } = activeContentTabFrame:GetChildren()

		if #contentTabFrameChildren > 0 then
			warn(`Tab '{activeTab.Name}' didn't cleanup unmounted interface properly, there are leftover elements:`)

			for _, childInstance: Instance in contentTabFrameChildren do
				warn(`  ╠ {childInstance.Name}({childInstance.ClassName})`)
				childInstance:Destroy()
			end
		end
	end

	DebugInterface.internal.ActiveTab = {
		Name = tabName,
		Destructor = tabConstructor(activeContentTabFrame),
	}

	DebugInterface.internal.Tabs[tabName]:Focus()
end

function DebugInterface.internal.tabAdded(tabName: string)
	local tabContainer = TabFrame.new(
		tabName,
		DebugInterface.private.InterfaceElements.Tabs,
		DebugInterface.private.InterfaceElements.ContentFrame
	)

	tabContainer.TabActivated:Connect(function()
		DebugInterface.internal.focusModule(tabName)
	end)

	DebugInterface.internal.Tabs[tabName] = tabContainer

	if not DebugInterface.internal.ActiveTab then
		DebugInterface.internal.focusModule(tabName)
	end
end

function DebugInterface.private:CreateInterface()
	assert(not self.InterfaceCreated, `Tried to create interface when it was already created!`)

	self.InterfaceCreated = true

	local backgroundFrame: Frame = Instance.new("Frame")
	backgroundFrame.Name = "Frame"
	backgroundFrame.AnchorPoint = Vector2.new(0.50, 0.50)
	backgroundFrame.Position = UDim2.fromScale(0.50, 0.50)
	backgroundFrame.Size = UDim2.fromOffset(624, 375)
	backgroundFrame.BackgroundTransparency = 0.15
	backgroundFrame.BackgroundColor3 = Style.BACKGROUND
	backgroundFrame.BorderSizePixel = 0

	local uiStroke: UIStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.Color = Color3.fromRGB(98, 114, 164)
	uiStroke.Parent = backgroundFrame

	local headerLabel: TextLabel = Instance.new("TextLabel")
	headerLabel.Name = "Header"
	headerLabel.AutoLocalize = false
	headerLabel.Size = UDim2.new(1.00, 0, 0.00, 18)
	headerLabel.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	headerLabel.Text = "DEBUG TOOLS"
	headerLabel.TextColor3 = Style.TEXT
	headerLabel.TextSize = 18
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.BackgroundColor3 = Style.COLOR_WHITE
	headerLabel.BackgroundTransparency = 1.00
	headerLabel.BorderSizePixel = 0
	headerLabel.Parent = backgroundFrame

	local versionLabel: TextLabel = Instance.new("TextLabel")
	versionLabel.Name = "Version"
	versionLabel.AutoLocalize = false
	versionLabel.Size = UDim2.new(1.00, 0, 0.00, 18)
	versionLabel.FontFace =
		Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	versionLabel.Text = Constants.VERSION
	versionLabel.TextColor3 = Style.TEXT
	versionLabel.TextSize = 10
	versionLabel.TextTransparency = 0.75
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	versionLabel.BackgroundColor3 = Style.COLOR_WHITE
	versionLabel.BackgroundTransparency = 1.00
	versionLabel.BorderSizePixel = 0
	versionLabel.Parent = backgroundFrame

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = backgroundFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(0.00, 4)
	uiCorner.Parent = backgroundFrame

	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content Frame"
	contentFrame.Position = UDim2.fromOffset(0, 24)
	contentFrame.Size = UDim2.new(1.00, 0, 1.00, -24)
	contentFrame.BackgroundTransparency = 1.00
	contentFrame.BorderSizePixel = 0

	local tabContentFrame: Frame = Instance.new("Frame")
	tabContentFrame.Name = `Active Tab Content`
	tabContentFrame.AnchorPoint = Vector2.new(0.00, 1.00)
	tabContentFrame.Position = UDim2.new(0.00, 0, 1.00, 3)
	tabContentFrame.Size = UDim2.new(1.00, 0, 1.00, -16)
	tabContentFrame.BackgroundTransparency = 1.00
	tabContentFrame.BorderSizePixel = 0
	tabContentFrame.ClipsDescendants = true
	tabContentFrame.ZIndex = 2
	tabContentFrame.Parent = contentFrame

	local tabsListFrame: Frame = Instance.new("Frame")
	tabsListFrame.Name = "Tabs"
	tabsListFrame.Size = UDim2.new(1.00, 0, 0.00, 16)
	tabsListFrame.BackgroundTransparency = 1.00
	tabsListFrame.BorderSizePixel = 0

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.SortOrder = Enum.SortOrder.Name
	uiListLayout.Parent = tabsListFrame
	uiListLayout.Padding = UDim.new(0.00, 2)

	tabsListFrame.Parent = contentFrame

	contentFrame.Parent = backgroundFrame

	local dragPanel: TextButton = Instance.new("TextButton")
	dragPanel.Name = "Drag Detector"
	dragPanel.Position = UDim2.new(0.00, -8, 0.00, -8)
	dragPanel.Size = UDim2.new(1.00, 16, 0.00, 30)
	dragPanel.BorderSizePixel = 0
	dragPanel.Selectable = false
	dragPanel.Text = ""
	dragPanel.BackgroundTransparency = 1.00
	-- prevents mouse locking
	dragPanel.Modal = true
	dragPanel.Parent = backgroundFrame

	dragPanel.InputBegan:Connect(function(beganInputObject: InputObject)
		if
			self.Dragging
			or (
				beganInputObject.UserInputType ~= Enum.UserInputType.MouseButton1
				and beganInputObject.UserInputType ~= Enum.UserInputType.Touch
			)
		then
			return
		end

		local frameAbsolutePosition: Vector2 = Vector2.new(
			backgroundFrame.AbsolutePosition.X,
			backgroundFrame.AbsolutePosition.Y
		) + insetSize

		self.Dragging = true
		self.DragOffset = frameAbsolutePosition - UserInputService:GetMouseLocation()

		self.InputChangedConnection = UserInputService.InputChanged:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseMovement
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local anchorOffset: Vector2 = -(backgroundFrame.AbsoluteSize * -backgroundFrame.AnchorPoint)

			local newFramePosition: Vector2 = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
				+ self.DragOffset
				+ insetSize
				+ anchorOffset

			newFramePosition = Vector2.new(math.max(0, newFramePosition.X), math.max(0, newFramePosition.Y))

			backgroundFrame.Position = UDim2.fromOffset(newFramePosition.X, newFramePosition.Y)
		end)

		self.InputEndedConnection = UserInputService.InputEnded:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			self.Dragging = false

			self.InputEndedConnection:Disconnect()
			self.InputChangedConnection:Disconnect()
		end)
	end)

	local debugInterfaceScreenGui: ScreenGui = Instance.new("ScreenGui")
	debugInterfaceScreenGui.Name = "[DEBUG] Main Interface"
	debugInterfaceScreenGui.DisplayOrder = Constants.DEBUG_TOOL_DISPLAY_ORDER
	debugInterfaceScreenGui.IgnoreGuiInset = true
	debugInterfaceScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	debugInterfaceScreenGui.ResetOnSpawn = false
	debugInterfaceScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	debugInterfaceScreenGui.Enabled = false

	backgroundFrame.Parent = debugInterfaceScreenGui

	debugInterfaceScreenGui.Parent = Players.LocalPlayer.PlayerGui

	self.InterfaceElements.ContentFrame = contentFrame
	self.InterfaceElements.Tabs = tabsListFrame
	self.InterfaceElements.ScreenGui = debugInterfaceScreenGui

	DebugInterface.internal.ActiveContentTabFrame = tabContentFrame

	debugInterfaceScreenGui.DescendantAdded:Connect(function(descendantInstance: Instance)
		if
			not descendantInstance:IsA("TextLabel")
			and not descendantInstance:IsA("TextButton")
			and not descendantInstance:IsA("TextBox")
		then
			return
		end

		if descendantInstance.AutoLocalize then
			warn(
				`A descendant was added to Debug Tools interface that has AutoLocalize enabled, every Instance that inherits GuiBase2d should have it's AutoLocalize property set to false!\n{descendantInstance:GetFullName()}`
			)
		end

		descendantInstance.AutoLocalize = false
	end)
end

function DebugInterface.private:ListenToModules()
	for _, tabName: string in Tab.getAllTabs() do
		DebugInterface.internal.tabAdded(tabName)
	end

	Tab.TabAdded:Connect(function(tabName: any)
		DebugInterface.internal.tabAdded(tabName)
	end)
end

function DebugInterface.interface.getTabsFrame()
	return DebugInterface.private.InterfaceElements.Tabs
end

function DebugInterface.interface.init()
	DebugInterface.private:CreateInterface()
	DebugInterface.private:ListenToModules()
end

function DebugInterface.interface.switchVisibility()
	local debugInterfaceScreenGui: ScreenGui? = DebugInterface.private.InterfaceElements.ScreenGui
	if not debugInterfaceScreenGui then
		return
	end

	debugInterfaceScreenGui.Enabled = not debugInterfaceScreenGui.Enabled
end

return DebugInterface.interface
