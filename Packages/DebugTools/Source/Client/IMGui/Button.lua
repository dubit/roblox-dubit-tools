local IMGui = require(script.Parent)

type ImguiButton = IMGui.WidgetInstance & {
	Button: TextButton,

	Pressed: boolean,
	Clickable: boolean,

	PressConnection: RBXScriptConnection,
	MouseEnterConnection: RBXScriptConnection,
	MouseLeaveConnection: RBXScriptConnection,
	MouseUpConnection: RBXScriptConnection,
	MouseDownConnection: RBXScriptConnection,
}

local IMGUI_CONFIG = IMGui:GetConfig()

IMGui:NewWidgetDefinition("Button", {
	Events = {
		["activated"] = {
			["Evaluate"] = function(self: ImguiButton)
				local wasPressed = self.Pressed
				self.Pressed = false

				return wasPressed
			end,
		},

		["hovered"] = {
			["Evaluate"] = function(self: ImguiButton)
				return self.Hovering
			end,
		},
	},

	Construct = function(self: ImguiButton, parent: GuiObject, text: string, clickable: boolean?)
		local buttonInstance: TextButton = Instance.new("TextButton")
		buttonInstance.Name = `Button ({self.ID})`
		buttonInstance.AutomaticSize = Enum.AutomaticSize.XY
		buttonInstance.Text = text
		buttonInstance.RichText = true
		buttonInstance.BackgroundColor3 = IMGui:GetConfig().Colors.Button
		buttonInstance.BorderSizePixel = 0
		buttonInstance.AutoButtonColor = false

		IMGui.applyTextStyle(buttonInstance)
		IMGui.applyFrameStyle(buttonInstance)

		buttonInstance.Parent = parent

		self.Button = buttonInstance
		self.Clickable = if clickable ~= nil then clickable else true

		self.PressConnection = buttonInstance.Activated:Connect(function()
			if not self.Clickable then
				return
			end

			self.Pressed = true
		end)

		self.MouseEnterConnection = buttonInstance.MouseEnter:Connect(function()
			if not self.Clickable then
				return
			end

			buttonInstance.BackgroundColor3 = IMGUI_CONFIG.Colors.ButtonHovered
			self.Hovering = true
		end)

		self.MouseLeaveConnection = buttonInstance.MouseLeave:Connect(function()
			if not self.Clickable then
				return
			end

			buttonInstance.BackgroundColor3 = IMGUI_CONFIG.Colors.Button
			self.Hovering = false
		end)

		self.MouseUpConnection = buttonInstance.MouseButton1Up:Connect(function()
			if not self.Clickable then
				return
			end

			buttonInstance.BackgroundColor3 = IMGUI_CONFIG.Colors.Button
		end)

		self.MouseDownConnection = buttonInstance.MouseButton1Down:Connect(function()
			if not self.Clickable then
				return
			end

			buttonInstance.BackgroundColor3 = IMGUI_CONFIG.Colors.ButtonActive
		end)

		if not self.Clickable then
			self.Button.BackgroundColor3 = IMGui:GetConfig().Colors.ButtonDisabled
			self.Button.BackgroundTransparency = 0.50
			self.Button.TextTransparency = 0.25
		else
			self.Button.BackgroundColor3 = IMGui:GetConfig().Colors.Button
			self.Button.BackgroundTransparency = 0.00
			self.Button.TextTransparency = 0.00
		end

		return buttonInstance
	end,

	Deconstruct = function(self: ImguiButton)
		self.PressConnection:Disconnect()
		self.MouseEnterConnection:Disconnect()
		self.MouseLeaveConnection:Disconnect()
		self.MouseUpConnection:Disconnect()
		self.MouseDownConnection:Disconnect()
	end,

	Update = function(self: any, text: string, clickable: boolean?)
		self.TopInstance.Text = text
		self.Clickable = if clickable ~= nil then clickable else true

		if not self.Clickable then
			self.Button.BackgroundColor3 = IMGui:GetConfig().Colors.ButtonDisabled
			self.Button.BackgroundTransparency = 0.50
			self.Button.TextTransparency = 0.25
		else
			self.Button.BackgroundColor3 = IMGui:GetConfig().Colors.Button
			self.Button.BackgroundTransparency = 0.00
			self.Button.TextTransparency = 0.00
		end
	end,
})

return nil
