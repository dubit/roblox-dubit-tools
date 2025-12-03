--!strict
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent
local SharedPath = DebugToolRootPath.Parent.Shared

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)
local Authorization = require(DebugToolRootPath.Authorization)

local Console = require(DebugToolRootPath.Console)

local Constants = require(SharedPath.Constants)

local INTERFACE_KEY = Enum.KeyCode.F6

local debugScreenGUI: ScreenGui
local debugScreenTabs: Frame
local debugScreenContentFrame: Frame
local dragOffset: Vector2?

local activeTab: {
	Name: string,
	Destructor: () -> nil,
}? = nil

local DebugInterface = {}
DebugInterface.internal = {}

local function focusTab(tabName: string)
	if activeTab and activeTab.Name == tabName then
		return
	end

	local tabConstructor = Tab.getTabConstructor(tabName)
	if not tabConstructor then
		return
	end

	if activeTab then
		activeTab.Destructor()

		local contentTabFrameChildren = debugScreenContentFrame:GetChildren()

		if #contentTabFrameChildren > 0 then
			warn(`Tab '{activeTab.Name}' didn't cleanup unmounted interface properly, there are leftover elements:`)

			for _, childInstance: Instance in contentTabFrameChildren do
				warn(`    {childInstance.Name}({childInstance.ClassName})`)
				childInstance:Destroy()
			end
		end
	end

	activeTab = {
		Name = tabName,
		Destructor = tabConstructor(debugScreenContentFrame),
	}
end

local function setupInterface()
	local backgroundFrame = Instance.new("Frame")
	backgroundFrame.Name = "Frame"
	backgroundFrame.AnchorPoint = Vector2.new(0.50, 0.50)
	backgroundFrame.Position = UDim2.fromScale(0.50, 0.50)
	backgroundFrame.Size = UDim2.fromOffset(600, 400)
	backgroundFrame.BackgroundTransparency = 0.33
	backgroundFrame.BackgroundColor3 = Color3.new()
	backgroundFrame.BorderSizePixel = 0

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(12, 38, 177)
	uiStroke.Thickness = 2
	uiStroke.Transparency = 0.50
	uiStroke.Parent = backgroundFrame

	local resizeButton = Instance.new("TextButton")
	resizeButton.AutoButtonColor = false
	resizeButton.Name = "Resize Area"
	resizeButton.Text = ""
	resizeButton.AnchorPoint = Vector2.new(1, 1)
	resizeButton.BackgroundColor3 = Color3.fromRGB(12, 38, 177)
	resizeButton.BorderColor3 = Color3.new()
	resizeButton.BorderSizePixel = 0
	resizeButton.Position = UDim2.fromScale(1, 1)
	resizeButton.Size = UDim2.fromOffset(12, 12)

	resizeButton.Parent = backgroundFrame

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
	headerUIPadding.PaddingLeft = UDim.new(0, 8)
	headerUIPadding.PaddingRight = UDim.new(0, 8)
	headerUIPadding.Parent = headerLabel

	local sendLogsButton = Instance.new("ImageButton")
	sendLogsButton.Name = "Send Logs"
	sendLogsButton.AnchorPoint = Vector2.new(1, 0)
	sendLogsButton.BackgroundTransparency = 1
	sendLogsButton.Image = "rbxassetid://116990081986995"
	sendLogsButton.Position = UDim2.fromScale(1, 0)
	sendLogsButton.Size = UDim2.fromScale(1, 1)

	local uIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint.Parent = sendLogsButton

	sendLogsButton.Activated:Connect(function()
		warn(Console:GetOutputLog())
	end)

	sendLogsButton.Parent = headerLabel

	headerLabel.Parent = backgroundFrame

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content Frame"
	contentFrame.Position = UDim2.fromOffset(0, 24)
	contentFrame.Size = UDim2.new(1.00, 0, 1.00, -24)
	contentFrame.BackgroundTransparency = 1.00
	contentFrame.BorderSizePixel = 0

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Padding = UDim.new(0, 4)
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalFlex = Enum.UIFlexAlignment.Fill
	uIListLayout.Parent = contentFrame

	local tabContentFrame = Instance.new("Frame")
	tabContentFrame.Name = `Active Tab Content`
	tabContentFrame.Size = UDim2.fromScale(1.00, 1.00)
	tabContentFrame.BackgroundTransparency = 1.00
	tabContentFrame.BorderSizePixel = 0
	tabContentFrame.ClipsDescendants = true
	tabContentFrame.LayoutOrder = 2
	tabContentFrame.Parent = contentFrame

	local tabsListFrame = Instance.new("Frame")
	tabsListFrame.Name = "Tabs"
	tabsListFrame.AutomaticSize = Enum.AutomaticSize.Y
	tabsListFrame.Size = UDim2.fromScale(1.00, 0.00)
	tabsListFrame.BackgroundTransparency = 1.00
	tabsListFrame.BorderSizePixel = 0

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.SortOrder = Enum.SortOrder.Name
	uiListLayout.Parent = tabsListFrame
	uiListLayout.Padding = UDim.new(0.00, 2)

	tabsListFrame.Parent = contentFrame

	contentFrame.Parent = backgroundFrame

	headerLabel.InputBegan:Connect(function(beganInputObject: InputObject)
		if
			dragOffset
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

		dragOffset = frameAbsolutePosition - UserInputService:GetMouseLocation()

		local inputChanged, inputEnded
		inputChanged = UserInputService.InputChanged:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseMovement
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			if not dragOffset then
				return
			end

			local anchorOffset: Vector2 = -(backgroundFrame.AbsoluteSize * -backgroundFrame.AnchorPoint)

			local newFramePosition: Vector2 = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
				+ dragOffset
				+ insetSize
				+ anchorOffset

			newFramePosition = Vector2.new(math.max(0, newFramePosition.X), math.max(0, newFramePosition.Y))

			backgroundFrame.Position = UDim2.fromOffset(newFramePosition.X, newFramePosition.Y)
		end)

		inputEnded = UserInputService.InputEnded:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			dragOffset = nil

			inputEnded:Disconnect()
			inputChanged:Disconnect()
		end)
	end)

	debugScreenGUI = Instance.new("ScreenGui")
	debugScreenGUI.Name = "[DEBUG] Main Interface"
	debugScreenGUI.DisplayOrder = Constants.DEBUG_TOOL_DISPLAY_ORDER
	debugScreenGUI.IgnoreGuiInset = true
	debugScreenGUI.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	debugScreenGUI.ResetOnSpawn = false
	debugScreenGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	debugScreenGUI.Enabled = false

	if Authorization:IsLocalPlayerAuthorized() then
		debugScreenGUI.Parent = Players.LocalPlayer.PlayerGui
	else
		debugScreenGUI.Parent = script
	end

	backgroundFrame.Parent = debugScreenGUI

	debugScreenTabs = tabsListFrame

	debugScreenContentFrame = tabContentFrame

	debugScreenGUI.DescendantAdded:Connect(function(descendantInstance: Instance)
		if
			not descendantInstance:IsA("TextLabel")
			or not descendantInstance:IsA("TextButton")
			or not descendantInstance:IsA("TextBox")
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
			local isActive = activeTab and activeTab.Name == tab

			if IMGui:Button(isActive and `<b>{tab}</b>` or tab, not isActive).activated() then
				focusTab(tab)
			end
		end

		IMGui:End()
	end)

	resizeButton.InputBegan:Connect(function(beganInputObject: InputObject)
		if
			beganInputObject.UserInputType ~= Enum.UserInputType.MouseButton1
			and beganInputObject.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local insetSize: Vector2 = GuiService:GetGuiInset()

		local widgetRepresentationAbsolutePosition: Vector2 = backgroundFrame.AbsolutePosition + insetSize

		local offset: Vector2 = UserInputService:GetMouseLocation() - widgetRepresentationAbsolutePosition
		offset = Vector2.new(math.floor(offset.X), math.floor(offset.Y))

		local sizeBeforeDragging = backgroundFrame.AbsoluteSize
		local positionBeforeDragging = backgroundFrame.AbsolutePosition

		local inputChangedConnection, inputEndedConnection
		inputChangedConnection = UserInputService.InputChanged:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseMovement
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local newOffset = UserInputService:GetMouseLocation() - widgetRepresentationAbsolutePosition
			local growthVector = newOffset - offset
			local newSize = sizeBeforeDragging + growthVector
			newSize = Vector2.new(math.max(newSize.X, 600), math.max(newSize.Y, 400))

			local newPosition = positionBeforeDragging
				+ (newSize * backgroundFrame.AnchorPoint)
				+ GuiService:GetGuiInset()

			backgroundFrame.Position = UDim2.fromOffset(newPosition.X, newPosition.Y)
			backgroundFrame.Size = UDim2.fromOffset(newSize.X, newSize.Y)
		end)

		inputEndedConnection = UserInputService.InputEnded:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			inputEndedConnection:Disconnect()
			inputChangedConnection:Disconnect()
		end)
	end)
end

local function switchVisibility()
	if not Authorization:IsLocalPlayerAuthorized() then
		return
	end

	debugScreenGUI.Enabled = not debugScreenGUI.Enabled

	if debugScreenGUI.Enabled then
		if not activeTab then
			focusTab(Tab.getAllTabs()[1])
		end
	end
end

local function observeKeyBinds()
	UserInputService.InputBegan:Connect(function(inputObject: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent or inputObject.KeyCode ~= INTERFACE_KEY then
			return
		end

		switchVisibility()
	end)
end

local function observeMobileGesture()
	local touchPoints: { InputObject } = {}

	local function removeTouchPoint(inputObject: InputObject)
		for objectIndex: number, otherInputObject: InputObject in touchPoints do
			if otherInputObject == inputObject then
				table.remove(touchPoints, objectIndex)
				return
			end
		end
	end

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local viewportSize: Vector2 = workspace.CurrentCamera.ViewportSize

		local pointXMiddlePercentage: number =
			math.abs((viewportSize.X / 2.00 - inputObject.Position.X) / viewportSize.X)
		local pointYPercentage: number = inputObject.Position.Y / viewportSize.Y
		if pointYPercentage > 0.00 or pointXMiddlePercentage >= 0.10 then
			return
		end

		table.insert(touchPoints, inputObject)

		if #touchPoints >= 3 then
			for _, otherInputObject: InputObject in touchPoints do
				removeTouchPoint(otherInputObject)
			end

			switchVisibility()
		end

		task.delay(0.75, function()
			removeTouchPoint(inputObject)
		end)
	end)
end

local function observeConsoleKeyBinds()
	local consoleActivationButtons = {
		[Enum.KeyCode.ButtonL1] = true,
		[Enum.KeyCode.ButtonR1] = true,
		[Enum.KeyCode.ButtonY] = true,
	}

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if consoleActivationButtons[inputObject.KeyCode] then
			for buttonKey in consoleActivationButtons do
				if not UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, buttonKey) then
					return
				end
			end

			switchVisibility()

			GuiService.SelectedObject = debugScreenTabs:FindFirstChildWhichIsA("TextButton")
		end
	end)
end

local function observeConsoleKeyBindsForDevConsole()
	local consoleActivationButtons = {
		[Enum.KeyCode.ButtonL1] = true,
		[Enum.KeyCode.ButtonR1] = true,
		[Enum.KeyCode.ButtonX] = true,
	}

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if consoleActivationButtons[inputObject.KeyCode] then
			for buttonKey in consoleActivationButtons do
				if not UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, buttonKey) then
					return
				end
			end

			StarterGui:SetCore("DevConsoleVisible", not StarterGui:GetCore("DevConsoleVisible"))
		end
	end)
end

setupInterface()
observeKeyBinds()
observeMobileGesture()
observeConsoleKeyBinds()
observeConsoleKeyBindsForDevConsole()

Authorization.StatusChanged:Connect(function(authorized)
	debugScreenGUI.Parent = authorized and Players.LocalPlayer.PlayerGui or script
end)

return nil
