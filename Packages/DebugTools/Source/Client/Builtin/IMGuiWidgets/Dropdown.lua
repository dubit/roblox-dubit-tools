local Imgui = require(script.Parent.Parent.Parent.IMGui)

local DropdownPopup = require(script.Parent.Parent.Parent.Builtin.DropdownPopup)

type Dropdown = Imgui.WidgetInstance & {
	Button: TextButton,

	Pressed: boolean,

	PressConnection: RBXScriptConnection,
	MouseEnterConnection: RBXScriptConnection,
	MouseLeaveConnection: RBXScriptConnection,
}

Imgui:NewWidgetDefinition("Dropdown", {
	Events = {
		["changed"] = {
			["Evaluate"] = function(self: Dropdown)
				local choice = self.NewChoice
				self.NewChoice = nil

				return choice
			end,
		},
	},

	Construct = function(self: Dropdown, parent: GuiObject, text: string, activeValue: any, options: { any })
		local buttonInstance: TextButton = Instance.new("TextButton")
		buttonInstance.Name = `Dropdown ({self.ID})`
		buttonInstance.AutomaticSize = Enum.AutomaticSize.XY
		buttonInstance.Text = tostring(activeValue)
		buttonInstance.BackgroundColor3 = Color3.fromRGB(98, 114, 164)
		buttonInstance.BorderSizePixel = 0
		buttonInstance.AutoButtonColor = false

		Imgui.applyTextStyle(buttonInstance)
		Imgui.applyFrameStyle(buttonInstance)

		buttonInstance.Parent = parent

		Imgui.applyMouseDownStyle(buttonInstance, function() end)
		Imgui.applyMouseUpStyle(buttonInstance, function() end)

		self.PressConnection = buttonInstance.Activated:Connect(function()
			print("Pressed")
			local optionsClone = table.clone(options)
			table.remove(optionsClone, table.find(optionsClone, activeValue))

			local dropdown = DropdownPopup.new(buttonInstance, optionsClone, activeValue)
			dropdown.EntrySelected:Connect(function(newValue: string)
				if newValue == activeValue then
					return
				end

				activeValue = newValue
				buttonInstance.Text = tostring(newValue)

				self.NewChoice = newValue
			end)
		end)

		self.Button = buttonInstance

		return buttonInstance
	end,

	Deconstruct = function(self: Dropdown)
		self.PressConnection:Disconnect()
	end,

	Update = function(self: Dropdown, text: string, activeValue: any, options: { any })
		print("Update dropdown")
		self.Button.Text = tostring(activeValue)
	end,
})

return nil
