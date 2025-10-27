--!strict
local TweenService = game:GetService("TweenService")
type ActionData = {
	Name: string,
	RawName: string,
	Description: string?,
	Arguments: any,
	ServerAction: boolean,
}

local DebugToolRootPath = script.Parent.Parent.Parent.Parent.Parent
local SharedPath = DebugToolRootPath.Parent.Shared

local Action = require(SharedPath.Action)

local Console = require(DebugToolRootPath.Builtin.Tabs.Console)
local Style = require(DebugToolRootPath.Style)

local ActionArgument = require(script.Parent.ActionArgument)

return function(actionData: ActionData, parent: GuiObject, layoutOrder: number?)
	local actionFrame: Frame = Instance.new("Frame")
	actionFrame.Name = actionData.RawName
	actionFrame.Size = UDim2.fromScale(1.00, 0.00)
	actionFrame.AutomaticSize = Enum.AutomaticSize.Y
	actionFrame.BackgroundColor3 = Style.BACKGROUND
	actionFrame.BorderSizePixel = 0
	actionFrame.LayoutOrder = layoutOrder or 0

	local headerLabel: TextLabel = Instance.new("TextLabel")
	headerLabel.Name = "Header"
	headerLabel.AutoLocalize = false
	headerLabel.Size = UDim2.new(1.00, 0, 0.00, 16)
	headerLabel.FontFace = Style.FONT_BOLD
	headerLabel.Text = actionData.Name
	headerLabel.TextColor3 = Style.COLOR_WHITE
	headerLabel.TextSize = 16
	headerLabel.TextStrokeTransparency = 0.5
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.BackgroundTransparency = 1.00
	headerLabel.BorderSizePixel = 0
	headerLabel.LayoutOrder = -2

	local sideLabel: TextLabel = Instance.new("TextLabel")
	sideLabel.Name = "Side"
	sideLabel.AutoLocalize = false
	sideLabel.Size = UDim2.new(1.00, 0, 0.00, 14)
	sideLabel.BackgroundTransparency = 1.00
	sideLabel.BorderSizePixel = 0
	sideLabel.FontFace = Style.FONT
	sideLabel.Text = actionData.ServerAction and "Server" or "Client"
	sideLabel.TextColor3 = actionData.ServerAction and Style.COLOR_RED or Style.COLOR_GREEN
	sideLabel.TextSize = 12
	sideLabel.TextXAlignment = Enum.TextXAlignment.Right
	sideLabel.BackgroundColor3 = Style.COLOR_WHITE
	sideLabel.Parent = headerLabel

	headerLabel.Parent = actionFrame

	if actionData.Description then
		local descriptionLabel: TextLabel = Instance.new("TextLabel")
		descriptionLabel.Name = "Description"
		descriptionLabel.AutoLocalize = false
		descriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
		descriptionLabel.Position = UDim2.fromOffset(0, 14)
		descriptionLabel.Size = UDim2.new(1.00, 0, 0.00, 12)
		descriptionLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
		descriptionLabel.Text = actionData.Description
		descriptionLabel.TextColor3 = Style.TAB_NORMAL_TEXT
		descriptionLabel.TextSize = 12
		descriptionLabel.TextStrokeTransparency = 0.75
		descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		descriptionLabel.TextWrapped = true
		descriptionLabel.BackgroundTransparency = 1.00
		descriptionLabel.BorderSizePixel = 0
		descriptionLabel.LayoutOrder = -1
		descriptionLabel.Parent = actionFrame
	end

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 4)
	uiPadding.PaddingLeft = UDim.new(0.00, 4)
	uiPadding.PaddingRight = UDim.new(0.00, 4)
	uiPadding.PaddingTop = UDim.new(0.00, 4)
	uiPadding.Parent = actionFrame

	local executeButton: TextButton = Instance.new("TextButton")
	executeButton.Name = "Execute"
	executeButton.AutoLocalize = false
	executeButton.AnchorPoint = Vector2.new(1.00, 0.00)
	executeButton.Position = UDim2.new(1.00, 0, 0.00, 30)
	executeButton.Size = UDim2.new(1.00, 0, 0.00, 14)
	executeButton.FontFace = Style.FONT
	executeButton.Text = "Execute"
	executeButton.TextColor3 = Style.PRIMARY_TEXT
	executeButton.TextSize = 12
	executeButton.BackgroundColor3 = Style.PRIMARY
	executeButton.BorderSizePixel = 0
	executeButton.LayoutOrder = 100
	executeButton.Parent = actionFrame

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 4)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = actionFrame

	actionFrame.Parent = parent

	local argValues: { any } = {}
	local actionDestroyers: { (...any) -> any } = {}

	if actionData.Arguments then
		for argumentIndex: number, argumentData in actionData.Arguments do
			argValues[argumentIndex] = argumentData.Default

			argumentData.Index = argumentIndex

			table.insert(
				actionDestroyers,
				ActionArgument(actionFrame, argumentData, function(newValue: any)
					argValues[argumentIndex] = newValue
				end)
			)
		end
	end

	local function flashActionFrame(color: Color3)
		actionFrame.BorderColor3 = color
		actionFrame.BorderSizePixel = 3
		TweenService:Create(actionFrame, TweenInfo.new(0.70, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			BorderColor3 = Style.BACKGROUND,
			BorderSizePixel = 0,
		}):Play()
	end

	local executeConnection: RBXScriptConnection = executeButton.Activated:Connect(function()
		local actionOutcome: any = Action:Execute(actionData.RawName, argValues)
		if actionOutcome == nil then
			actionOutcome = true
		end

		if actionOutcome == true then
			flashActionFrame(Style.COLOR_GREEN)
		elseif not actionOutcome then
			flashActionFrame(Style.COLOR_RED)
		elseif typeof(actionOutcome) == "string" then
			flashActionFrame(Style.COLOR_ORANGE)

			-- TODO: Add notification instead?
			Console:AddMessage(
				`Action '{actionData.RawName}' outcome: {actionOutcome}`,
				Enum.MessageType.MessageInfo,
				false
			)
		end
	end)

	return function()
		actionFrame:Destroy()

		executeConnection:Disconnect()

		for _, actionDestroyer in actionDestroyers do
			actionDestroyer()
		end
	end
end
