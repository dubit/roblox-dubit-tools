--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent
local SharedPath = DebugToolRootPath.Parent.Shared

local Tab = require(DebugToolRootPath.Tab)
local Style = require(DebugToolRootPath.Style)
local IMGui = require(DebugToolRootPath.IMGui)

local Constants = require(SharedPath.Constants)

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
		activeTab.Destructor()

		local contentTabFrameChildren = activeContentTabFrame:GetChildren()

		if #contentTabFrameChildren > 0 then
			warn(`Tab '{activeTab.Name}' didn't cleanup unmounted interface properly, there are leftover elements:`)

			for _, childInstance: Instance in contentTabFrameChildren do
				warn(`    {childInstance.Name}({childInstance.ClassName})`)
				childInstance:Destroy()
			end
		end
	end

	DebugInterface.internal.ActiveTab = {
		Name = tabName,
		Destructor = tabConstructor(activeContentTabFrame),
	}
end

function DebugInterface.internal.tabAdded(tabName: string)
	DebugInterface.internal.Tabs[tabName] = {
		Name = tabName,
	}

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
	uiStroke.Color = Color3.fromRGB(12, 38, 177)
	uiStroke.Thickness = 2
	uiStroke.Transparency = 0.50
	uiStroke.Parent = backgroundFrame

	local headerLabel = Instance.new("TextButton")
	headerLabel.Name = "Header"
	headerLabel.AutoButtonColor = false
	headerLabel.AutoLocalize = false
	headerLabel.Selectable = false
	headerLabel.BackgroundColor3 = Color3.fromRGB(12, 38, 177)
	headerLabel.BackgroundTransparency = 0.5
	headerLabel.BorderColor3 = Color3.new()
	headerLabel.BorderSizePixel = 0
	headerLabel.FontFace = Font.new("rbxassetid://16658221428", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	headerLabel.Size = UDim2.new(1, 0, 0, 24)
	headerLabel.Text = `DEBUG TOOLS v{Constants.VERSION}`
	headerLabel.TextColor3 = Color3.new(1, 1, 1)
	headerLabel.TextSize = 14
	headerLabel.Modal = true
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left

	local headerUIPadding = Instance.new("UIPadding")
	headerUIPadding.Name = "UIPadding"
	headerUIPadding.PaddingLeft = UDim.new(0, 8)
	headerUIPadding.Parent = headerLabel

	headerLabel.Parent = backgroundFrame

	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content Frame"
	contentFrame.Position = UDim2.fromOffset(0, 24)
	contentFrame.Size = UDim2.new(1.00, 0, 1.00, -24)
	contentFrame.BackgroundTransparency = 1.00
	contentFrame.BorderSizePixel = 0

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 4)
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
	uIListLayout.Parent = contentFrame

	local tabContentFrame: Frame = Instance.new("Frame")
	tabContentFrame.Name = `Active Tab Content`
	tabContentFrame.Size = UDim2.fromScale(1.00, 1.00)
	tabContentFrame.BackgroundTransparency = 1.00
	tabContentFrame.BorderSizePixel = 0
	tabContentFrame.ClipsDescendants = true
	tabContentFrame.LayoutOrder = 2
	tabContentFrame.Parent = contentFrame

	local tabsListFrame: Frame = Instance.new("Frame")
	tabsListFrame.Name = "Tabs"
	tabsListFrame.AutomaticSize = Enum.AutomaticSize.Y
	tabsListFrame.Size = UDim2.fromScale(1.00, 0.00)
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

	headerLabel.InputBegan:Connect(function(beganInputObject: InputObject)
		if
			self.Dragging
			or (
				beganInputObject.UserInputType ~= Enum.UserInputType.MouseButton1
				and beganInputObject.UserInputType ~= Enum.UserInputType.Touch
			)
		then
			return
		end

		local insetSize: Vector2 = GuiService:GetGuiInset()

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

	IMGui:Connect(tabsListFrame, function()
		IMGui:BeginHorizontal()

		for _, tab in Tab.getAllTabs() do
			local isActive = DebugInterface.internal.ActiveTab and DebugInterface.internal.ActiveTab.Name == tab

			if IMGui:Button(isActive and `<b>{tab}</b>` or tab, not isActive).activated() then
				DebugInterface.internal.focusModule(tab)
			end
		end

		IMGui:End()
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
