local IMGui = require(script.Parent)

type ImguiImageButton = IMGui.WidgetInstance & {
	ImageButton: ImageButton,

	Pressed: boolean,
	WasPressed: boolean,

	PressConnection: RBXScriptConnection,
	MouseEnterConnection: RBXScriptConnection,
	MouseLeaveConnection: RBXScriptConnection,
}

IMGui:NewWidgetDefinition("ImageButton", {
	Events = {
		["activated"] = {
			["Evaluate"] = function(self: ImguiImageButton)
				local wasPressed = self.Pressed
				self.Pressed = false

				return wasPressed
			end,
		},

		["hovered"] = {
			["Evaluate"] = function(self: ImguiImageButton)
				return self.Hovering
			end,
		},
	},

	Construct = function(self: ImguiImageButton, parent: GuiObject, size: UDim2, image: string, rotation: number?)
		local buttonInstance: ImageButton = Instance.new("ImageButton")
		buttonInstance.Name = `ImageButton ({self.ID})`
		buttonInstance.AutomaticSize = Enum.AutomaticSize.XY
		buttonInstance.BorderSizePixel = 0
		buttonInstance.BackgroundTransparency = 1
		buttonInstance.AutoButtonColor = false
		buttonInstance.Image = image or ""
		buttonInstance.Rotation = rotation or 0
		buttonInstance.Size = size

		buttonInstance.Parent = parent

		self.PressConnection = buttonInstance.Activated:Connect(function()
			self.Pressed = true
		end)

		self.MouseEnterConnection = buttonInstance.MouseEnter:Connect(function()
			self.Hovering = true
		end)

		self.MouseLeaveConnection = buttonInstance.MouseLeave:Connect(function()
			self.Hovering = false
		end)

		self.ImageButton = buttonInstance

		return buttonInstance
	end,

	Deconstruct = function(self: ImguiImageButton)
		self.PressConnection:Disconnect()
		self.MouseEnterConnection:Disconnect()
		self.MouseLeaveConnection:Disconnect()
	end,

	Update = function(self: any, size: UDim2, image: string)
		self.TopInstance.Image = image
		self.TopInstance.Size = size
	end,

	Return = function(self: ImguiImageButton)
		local wasPressed: boolean = self.Pressed
		self.Pressed = false

		return wasPressed or false
	end,
})

return nil
