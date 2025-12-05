--!strict
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local DebugToolRootPath = script.Parent.Parent.Parent

local Widget = require(DebugToolRootPath.Widget)
local Networking = require(DebugToolRootPath.Networking)

Widget.new("Place Stats", function(parent: ScreenGui)
	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.AnchorPoint = Vector2.new(0.00, 1.00)
	contentFrame.Position = UDim2.new(0.00, 8, 1.00, -8)
	contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	contentFrame.BackgroundTransparency = 0.50
	contentFrame.AutomaticSize = Enum.AutomaticSize.XY

	local fpsLabel = Instance.new("TextLabel")
	fpsLabel.AutoLocalize = false
	fpsLabel.Size = UDim2.fromOffset(0, 24)
	fpsLabel.FontFace =
		Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	fpsLabel.Text = "FPS: 0"
	fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	fpsLabel.TextSize = 24
	fpsLabel.TextTransparency = 0.33
	fpsLabel.AutomaticSize = Enum.AutomaticSize.X
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.LayoutOrder = 1
	fpsLabel.Parent = contentFrame

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.Parent = contentFrame

	local physicsFPSLabel = Instance.new("TextLabel")
	physicsFPSLabel.Name = "PhysicsFPSLabel"
	physicsFPSLabel.AutoLocalize = false
	physicsFPSLabel.Size = UDim2.fromOffset(0, 14)
	physicsFPSLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	physicsFPSLabel.Text = "Physics FPS: 0"
	physicsFPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	physicsFPSLabel.TextSize = 14
	physicsFPSLabel.TextTransparency = 0.33
	physicsFPSLabel.AutomaticSize = Enum.AutomaticSize.X
	physicsFPSLabel.BackgroundTransparency = 1.00
	physicsFPSLabel.LayoutOrder = 3
	physicsFPSLabel.Parent = contentFrame

	local placeVersionLabel: TextLabel = Instance.new("TextLabel")
	placeVersionLabel.Name = "PlaceVersionLabel"
	placeVersionLabel.AutoLocalize = false
	placeVersionLabel.Size = UDim2.fromOffset(0, 14)
	placeVersionLabel.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	placeVersionLabel.Text = `Version: {game.PlaceVersion}`
	placeVersionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	placeVersionLabel.TextSize = 14
	placeVersionLabel.TextTransparency = 0.33
	placeVersionLabel.AutomaticSize = Enum.AutomaticSize.X
	placeVersionLabel.BackgroundTransparency = 1.00
	placeVersionLabel.LayoutOrder = 4
	placeVersionLabel.Parent = contentFrame

	local serverIp = Instance.new("TextLabel")
	serverIp.AutoLocalize = false
	serverIp.Size = UDim2.fromOffset(0, 14)
	serverIp.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	serverIp.Text = "Server IP: 192.168.1.144"
	serverIp.TextColor3 = Color3.fromRGB(255, 255, 255)
	serverIp.TextSize = 14
	serverIp.TextTransparency = 0.33
	serverIp.AutomaticSize = Enum.AutomaticSize.X
	serverIp.BackgroundTransparency = 1.00
	serverIp.LayoutOrder = 5
	serverIp.Parent = contentFrame

	local serverLocation = Instance.new("TextLabel")
	serverLocation.AutoLocalize = false
	serverLocation.Size = UDim2.fromOffset(0, 14)
	serverLocation.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	serverLocation.Text = "Server Location: England, United Kingdom"
	serverLocation.TextColor3 = Color3.fromRGB(255, 255, 255)
	serverLocation.TextSize = 14
	serverLocation.TextTransparency = 0.33
	serverLocation.AutomaticSize = Enum.AutomaticSize.X
	serverLocation.BackgroundTransparency = 1.00
	serverLocation.LayoutOrder = 6
	serverLocation.Parent = contentFrame

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Padding = UDim.new(0, 2)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = contentFrame

	contentFrame.Parent = parent

	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		fpsLabel.Text = `FPS: {math.floor(1 / Stats.FrameTime)}`
		physicsFPSLabel.Text = `Physics Step Time: {string.format("%.4f", Stats.PhysicsStepTime)}`
	end)

	Networking:SubscribeToTopic("server_info", function(ip, location)
		serverLocation.Text = `Server Location: {location}`
		serverIp.Text = `Server Ip: {ip}`
	end)

	return function()
		contentFrame:Destroy()

		heartbeatConnection:Disconnect()
	end
end)

return nil
