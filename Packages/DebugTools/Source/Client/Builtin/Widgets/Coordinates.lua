--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent.Parent.Parent

local didShowCoordinatesTip = false

local Widget = require(DebugToolRootPath.Widget)

Widget.new("Coordinates", function(parent: ScreenGui)
	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.AnchorPoint = Vector2.new(0.50, 1.00)
	contentFrame.Position = UDim2.new(0.50, 0, 1.00, -8)
	contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	contentFrame.BackgroundTransparency = 0.50
	contentFrame.AutomaticSize = Enum.AutomaticSize.XY

	local uiPadding: UIPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0.00, 4)
	uiPadding.PaddingLeft = UDim.new(0.00, 4)
	uiPadding.PaddingRight = UDim.new(0.00, 4)
	uiPadding.PaddingTop = UDim.new(0.00, 4)
	uiPadding.Parent = contentFrame

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = contentFrame

	local coordinatesTextBox: TextBox = Instance.new("TextBox")
	coordinatesTextBox.Name = "CoordinatesTextBox"
	coordinatesTextBox.AutoLocalize = false
	coordinatesTextBox.Size = UDim2.fromOffset(0, 14)
	coordinatesTextBox.BackgroundTransparency = 1.00
	coordinatesTextBox.FontFace =
		Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	coordinatesTextBox.Text = "X: 0.00 Y: 0.00 Z: 0.00"
	coordinatesTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	coordinatesTextBox.TextSize = 14
	coordinatesTextBox.TextTransparency = 0.33
	coordinatesTextBox.AutomaticSize = Enum.AutomaticSize.X
	coordinatesTextBox.LayoutOrder = 3
	coordinatesTextBox.Visible = false
	coordinatesTextBox.TextEditable = false
	coordinatesTextBox.ClearTextOnFocus = false
	coordinatesTextBox.Parent = contentFrame

	local coordinatesLabel: TextLabel = Instance.new("TextLabel")
	coordinatesLabel.Name = "CoordinatesLabel"
	coordinatesLabel.AutoLocalize = false
	coordinatesLabel.Size = UDim2.fromOffset(0, 14)
	coordinatesLabel.BackgroundTransparency = 1.00
	coordinatesLabel.FontFace =
		Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	coordinatesLabel.Text = "X: 0.00 Y: 0.00 Z: 0.00"
	coordinatesLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coordinatesLabel.TextSize = 14
	coordinatesLabel.TextTransparency = 0.33
	coordinatesLabel.AutomaticSize = Enum.AutomaticSize.X
	coordinatesLabel.LayoutOrder = 3
	coordinatesLabel.Parent = contentFrame

	contentFrame.Parent = parent

	-- When the player clicks the coordinates widget, put their coordinates in the output, and give them a one-time tip!
	coordinatesLabel.InputBegan:Connect(function(inputObject: InputObject)
		if inputObject.UserInputState ~= Enum.UserInputState.Begin then
			return
		end

		if
			inputObject.UserInputType == Enum.UserInputType.MouseButton1
			or inputObject.UserInputType == Enum.UserInputType.Touch
		then
			print(`Player {Players.LocalPlayer.Name} coordinates - {coordinatesLabel.Text}`)

			if not didShowCoordinatesTip then
				didShowCoordinatesTip = true
				print("Tip - if you press 'Alt', it will allow you to copy the contents of the coordinates widget!")
			end
		end
	end)

	local heartbeatConneciton: RBXScriptConnection = RunService.Heartbeat:Connect(function()
		if not Players.LocalPlayer.Character then
			coordinatesLabel.Text = "No character"
			return
		end

		local characterPrimaryPart: BasePart? = Players.LocalPlayer.Character.PrimaryPart
		if not characterPrimaryPart then
			coordinatesLabel.Text = "No character"
			return
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
			coordinatesTextBox.Visible = true
			coordinatesLabel.Visible = false
		else
			coordinatesTextBox.Visible = false
			coordinatesLabel.Visible = true
		end

		local characterPosition: Vector3 = characterPrimaryPart.Position

		coordinatesTextBox.Text = `{string.format("%.3f", characterPosition.X)}, {string.format(
			"%.3f",
			characterPosition.Y
		)}, {string.format("%.3f", characterPosition.Z)}`
		coordinatesLabel.Text = `X: {string.format("%.3f", characterPosition.X)} Y: {string.format(
			"%.3f",
			characterPosition.Y
		)} Z: {string.format("%.3f", characterPosition.Z)}`
	end)

	return function()
		contentFrame:Destroy()
		contentFrame = nil

		heartbeatConneciton:Disconnect()
		heartbeatConneciton = nil
	end
end)

return nil
