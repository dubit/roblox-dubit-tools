--!strict
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local DebugToolRootPath = script.Parent.Parent.Parent

local Widget = require(DebugToolRootPath.Widget)

Widget.new("Performance Stats", function(parent: ScreenGui)
	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.AnchorPoint = Vector2.new(0.00, 1.00)
	contentFrame.Position = UDim2.new(0.00, 8, 0.7, -8)
	contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	contentFrame.BackgroundTransparency = 0.50
	contentFrame.AutomaticSize = Enum.AutomaticSize.XY

	local instanceCountLabel: TextLabel = Instance.new("TextLabel")
	instanceCountLabel.Name = "InstanceCountLabel"
	instanceCountLabel.AutoLocalize = false
	instanceCountLabel.Size = UDim2.fromOffset(0, 14)
	instanceCountLabel.FontFace =
		Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	instanceCountLabel.Text = "Instances: 0"
	instanceCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instanceCountLabel.TextSize = 14
	instanceCountLabel.TextTransparency = 0.33
	instanceCountLabel.AutomaticSize = Enum.AutomaticSize.X
	instanceCountLabel.BackgroundTransparency = 1
	instanceCountLabel.LayoutOrder = 1
	instanceCountLabel.Parent = contentFrame

	local sceneDrawCallCountLabel = instanceCountLabel:Clone()
	sceneDrawCallCountLabel.Name = "DrawCallLabel"
	sceneDrawCallCountLabel.Text = "Draw Calls: 0"
	sceneDrawCallCountLabel.Parent = contentFrame

	local sceneTriCountLabel = instanceCountLabel:Clone()
	sceneTriCountLabel.Name = "TriCountLabel"
	sceneTriCountLabel.Text = "Tri Count: 0"
	sceneTriCountLabel.Parent = contentFrame

	local shadowDrawCallCountLabel = instanceCountLabel:Clone()
	shadowDrawCallCountLabel.Name = "ShadowDrawCallLabel"
	shadowDrawCallCountLabel.Text = "Shadow Draw Calls: 0"
	shadowDrawCallCountLabel.Parent = contentFrame

	local uiDrawCallCountLabel = instanceCountLabel:Clone()
	uiDrawCallCountLabel.Name = "DrawCallLabelUI2D"
	uiDrawCallCountLabel.Text = "2D UI Draw Calls: 0"
	uiDrawCallCountLabel.Parent = contentFrame

	local uiDrawCallCountLabel3D = instanceCountLabel:Clone()
	uiDrawCallCountLabel3D.Name = "DrawCallLabelUI3D"
	uiDrawCallCountLabel3D.Text = "3D UI Draw Calls: 0"
	uiDrawCallCountLabel3D.Parent = contentFrame

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = contentFrame

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 2)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = contentFrame

	contentFrame.Parent = parent

	local heartbeatConnection: RBXScriptConnection = RunService.Heartbeat:Connect(function()
		local instanceCount = Stats.InstanceCount
		instanceCountLabel.Text = `Instances: {instanceCount}`

		local drawCallCount = Stats.SceneDrawcallCount
		sceneDrawCallCountLabel.Text = `Draw Calls: {drawCallCount}`

		local triCount = Stats.SceneTriangleCount
		shadowDrawCallCountLabel.Text = `Tri Count: {triCount}`

		local shadowDrawCallCount = Stats.ShadowsDrawcallCount
		shadowDrawCallCountLabel.Text = `Shadow Draw Calls: {shadowDrawCallCount}`

		local drawCallCountUI2D = Stats.UI2DDrawcallCount
		uiDrawCallCountLabel.Text = `2D UI Draw Calls: {drawCallCountUI2D}`

		local drawCallCountUI3D = Stats.UI3DDrawcallCount
		uiDrawCallCountLabel3D.Text = `3D UI Draw Calls: {drawCallCountUI3D}`
	end)

	return function()
		contentFrame:Destroy()
		contentFrame = nil

		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end)

Widget:Hide("Performance Stats")

return nil
