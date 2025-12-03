local IMGui = require(script.Parent)

type ImguiLabel = IMGui.WidgetInstance & {
	TopInstance: TextLabel,
}

IMGui:NewWidgetDefinition("Label", {
	Construct = function(self: ImguiLabel, parent: GuiObject, text: string)
		local textInstance: TextLabel = Instance.new("TextLabel")
		textInstance.Name = `Label ({self.ID})`
		textInstance.AutomaticSize = Enum.AutomaticSize.XY
		textInstance.Text = text
		textInstance.RichText = true
		textInstance.BackgroundTransparency = 1
		textInstance.BorderSizePixel = 0

		IMGui.applyTextStyle(textInstance)

		textInstance.Parent = parent

		return textInstance
	end,

	Update = function(self: ImguiLabel, text: string)
		self.TopInstance.Text = text
	end,
})

return nil
