local Imgui = require(script.Parent.Parent.Parent.IMGui)

type ImguiLabel = Imgui.WidgetInstance & {
	TopInstance: TextLabel,
}

Imgui:NewWidgetDefinition("Label", {
	Construct = function(self: ImguiLabel, parent: GuiObject, text: string)
		local textInstance: TextLabel = Instance.new("TextLabel")
		textInstance.Name = `Label ({self.ID})`
		textInstance.AutomaticSize = Enum.AutomaticSize.XY
		textInstance.Text = text
		textInstance.RichText = true
		textInstance.BackgroundTransparency = 1
		textInstance.BorderSizePixel = 0

		Imgui.applyTextStyle(textInstance)

		textInstance.Parent = parent

		return textInstance
	end,

	Update = function(self: ImguiLabel, text: string)
		self.TopInstance.Text = text
	end,
})

return nil
