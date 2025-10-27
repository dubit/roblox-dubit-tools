--!strict
local DebugToolRootPath = script.Parent.Parent.Parent.Parent.Parent

local Style = require(DebugToolRootPath.Style)

local ActionFrame = require(script.Parent.ActionFrame)

return function(parent: Frame, selectedGroupValue: any, allActionsValue: any)
	local actionsScrollFrame: ScrollingFrame = Instance.new("ScrollingFrame")
	actionsScrollFrame.Name = "Actions"
	actionsScrollFrame.AnchorPoint = Vector2.new(1.00, 0.00)
	actionsScrollFrame.Position = UDim2.fromScale(1.00, 0.00)
	actionsScrollFrame.Size = UDim2.fromScale(0.75, 1.00)
	actionsScrollFrame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	actionsScrollFrame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	actionsScrollFrame.ScrollBarImageColor3 = Style.COLOR_BLACK
	actionsScrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	actionsScrollFrame.Active = true
	actionsScrollFrame.BackgroundTransparency = 1.00
	actionsScrollFrame.BorderSizePixel = 0
	actionsScrollFrame.CanvasSize = UDim2.new()
	actionsScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = actionsScrollFrame

	local uiListLayout: UIListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0.00, 8)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = actionsScrollFrame

	actionsScrollFrame.Parent = parent

	local instancedActionFrameDestroyers = {}

	local function refreshActions()
		local selectedGroup = selectedGroupValue:Get()
		local allActions = allActionsValue:Get()

		if not selectedGroup then
			return
		end

		local currentGroupActions = {}

		for groupName in allActions do
			table.sort(allActions[groupName], function(a, b)
				return a.Name < b.Name
			end)
		end

		for i, actionData in allActions[selectedGroup] do
			table.insert(currentGroupActions, actionData.RawName)

			if instancedActionFrameDestroyers[actionData.RawName] then
				continue
			end

			instancedActionFrameDestroyers[actionData.RawName] = ActionFrame(actionData, actionsScrollFrame, i)
		end

		for rawActionName, actionCleanupFunction in instancedActionFrameDestroyers do
			if table.find(currentGroupActions, rawActionName) then
				continue
			end

			actionCleanupFunction()
			instancedActionFrameDestroyers[rawActionName] = nil
		end
	end

	local selectedGroupObserverConnection = selectedGroupValue:Observe(function()
		refreshActions()
	end)

	local actionsObserverConnection = allActionsValue:Observe(function()
		refreshActions()
	end)

	refreshActions()

	return function()
		selectedGroupObserverConnection:Disconnect()
		selectedGroupObserverConnection = nil

		actionsObserverConnection:Disconnect()
		actionsObserverConnection = nil

		actionsScrollFrame:Destroy()
		actionsScrollFrame = nil

		for _, actionCleanupFunction in instancedActionFrameDestroyers do
			actionCleanupFunction()
		end

		instancedActionFrameDestroyers = nil
	end
end
