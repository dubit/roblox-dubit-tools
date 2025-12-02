local IMGui = require(script.Parent.Parent.Parent.Parent.IMGui)

type IMGuiLabel = IMGui.WidgetInstance & {
	TopInstance: ImageLabel,
}

IMGui:NewWidgetDefinition("ExplorerClassIcon", {
	Construct = function(self: IMGuiLabel, parent: GuiObject, size: UDim2, object: Instance)
		local imageLabel: ImageLabel = Instance.new("ImageLabel")
		imageLabel.Name = `Label ({self.ID})`
		imageLabel.AutomaticSize = Enum.AutomaticSize.XY
		imageLabel.BackgroundTransparency = 1
		imageLabel.BorderSizePixel = 0
		imageLabel.Size = size
		imageLabel.Image = `rbxassetid://15793477861`
		imageLabel.Parent = parent

		return imageLabel
	end,

	Update = function(self: IMGuiLabel, size: UDim2, object: Instance)
		self.TopInstance.Size = size
	end,
})

return nil
