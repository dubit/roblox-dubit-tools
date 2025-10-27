local Imgui = require(script.Parent.Parent.Parent.IMGui)

type ImguiButton = Imgui.WidgetInstance & {
	Button: TextButton,

	Pressed: boolean,

	PressConnection: RBXScriptConnection,
	MouseEnterConnection: RBXScriptConnection,
	MouseLeaveConnection: RBXScriptConnection,
}

Imgui:NewWidgetDefinition("Button", {
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

	Construct = function(self: ImguiButton, parent: GuiObject, text: string)
		local buttonInstance: TextButton = Instance.new("TextButton")
		buttonInstance.Name = `Button ({self.ID})`
		buttonInstance.AutomaticSize = Enum.AutomaticSize.XY
		buttonInstance.Text = text
		buttonInstance.BackgroundColor3 = Color3.fromRGB(98, 114, 164)
		buttonInstance.BorderSizePixel = 0
		buttonInstance.AutoButtonColor = false

		Imgui.applyTextStyle(buttonInstance)
		Imgui.applyFrameStyle(buttonInstance)

		buttonInstance.Parent = parent

		Imgui.applyMouseDownStyle(buttonInstance, function() end)
		Imgui.applyMouseUpStyle(buttonInstance, function() end)

		self.PressConnection = buttonInstance.Activated:Connect(function()
			self.Pressed = true
		end)

		self.MouseEnterConnection = Imgui.applyMouseHoverStyle(buttonInstance, function()
			self.Hovering = true
		end)

		self.MouseLeaveConnection = Imgui.applyMouseHoverEndStyle(buttonInstance, function()
			self.Hovering = false
		end)

		self.Button = buttonInstance

		return buttonInstance
	end,

	Deconstruct = function(self: ImguiButton)
		self.PressConnection:Disconnect()
		self.MouseEnterConnection:Disconnect()
		self.MouseLeaveConnection:Disconnect()
	end,

	Update = function(self: any, text: string)
		self.TopInstance.Text = text
	end,
})

return nil
