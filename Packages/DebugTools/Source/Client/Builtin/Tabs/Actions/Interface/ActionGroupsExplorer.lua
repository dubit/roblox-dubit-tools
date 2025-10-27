--!strict
local ActionGroupButton = require(script.Parent.ActionGroupButton)

return function(
	parent: Frame,
	actionGroupsValue: any,
	selectedGroupValue: any,
	groupChangeCallback: (groupName: string) -> nil
)
	local actionsexplorer = Instance.new("Frame")
	actionsexplorer.Name = "Actions Explorer"
	actionsexplorer.BackgroundColor3 = Color3.fromRGB(172, 195, 245)
	actionsexplorer.BorderColor3 = Color3.fromRGB(0, 0, 0)
	actionsexplorer.BorderSizePixel = 0
	actionsexplorer.Size = UDim2.fromScale(0.25, 1)

	local gradient = Instance.new("Frame")
	gradient.Name = "Gradient"
	gradient.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	gradient.BackgroundTransparency = 0.8
	gradient.BorderSizePixel = 0
	gradient.Position = UDim2.fromScale(1, 0)
	gradient.Size = UDim2.fromScale(0.05, 1)

	local uigradient = Instance.new("UIGradient")
	uigradient.Name = "UIGradient"
	uigradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	uigradient.Parent = gradient

	gradient.Parent = actionsexplorer

	local scrollingframe = Instance.new("ScrollingFrame")
	scrollingframe.Name = "ScrollingFrame"
	scrollingframe.CanvasSize = UDim2.new()
	scrollingframe.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrollingframe.BackgroundTransparency = 1
	scrollingframe.BorderSizePixel = 0
	scrollingframe.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingframe.ScrollBarThickness = 4
	scrollingframe.Size = UDim2.fromScale(1, 1)

	local uilistlayout = Instance.new("UIListLayout")
	uilistlayout.Name = "UIListLayout"
	uilistlayout.Padding = UDim.new(0, 2)
	uilistlayout.Parent = scrollingframe

	scrollingframe.Parent = actionsexplorer

	actionsexplorer.Parent = parent

	local actionGroupButtons = {}

	actionGroupsValue:Observe(function(actionGroups)
		for _, actionGroup: string in actionGroups do
			if actionGroupButtons[actionGroup] then
				continue
			end

			actionGroupButtons[actionGroup] = ActionGroupButton(
				actionGroup,
				scrollingframe,
				selectedGroupValue,
				function()
					groupChangeCallback(actionGroup)
				end
			)
		end
	end)

	return function()
		actionsexplorer:Destroy()
		actionsexplorer = nil

		for _, groupButtonDestroyer in actionGroupButtons do
			groupButtonDestroyer()
		end

		actionGroupButtons = nil
	end
end
