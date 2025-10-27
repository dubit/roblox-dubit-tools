--!strict
local DebugToolRootPath = script.Parent.Parent.Parent.Parent.Parent

local Style = require(DebugToolRootPath.Style)

return function(groupName: string, parent: ScrollingFrame, selectedGroupValue: any, callback: () -> nil)
	local groupButton: TextButton = Instance.new("TextButton")
	groupButton.Name = `Action Group ({groupName})`
	groupButton.AutoLocalize = false
	groupButton.Size = UDim2.new(1.00, 0, 0.00, 18)
	groupButton.FontFace = Style.FONT_BOLD
	groupButton.Text = ` {groupName}`
	groupButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	groupButton.TextSize = 12
	groupButton.TextStrokeTransparency = 0
	groupButton.TextXAlignment = Enum.TextXAlignment.Left
	groupButton.BackgroundColor3 = Style.PRIMARY_DARK
	groupButton.BorderSizePixel = 0

	groupButton.Parent = parent

	local buttonActivatedConnection = groupButton.Activated:Connect(function()
		callback()
	end)

	local selectedGroupObserver = selectedGroupValue:Observe(function(selectedGroup: string)
		groupButton.BackgroundColor3 = groupName == selectedGroup and Style.PRIMARY_TEXT or Style.PRIMARY_DARK
	end)

	return function()
		selectedGroupObserver:Disconnect()
		selectedGroupObserver = nil

		buttonActivatedConnection:Disconnect()
		buttonActivatedConnection = nil

		groupButton:Destroy()
		groupButton = nil
	end
end
