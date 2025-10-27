local IMGui = require(script.Parent.Parent.Parent.Parent.IMGui)
local ClassIndex = require(script.Parent.Parent.Parent.Parent.Vendor.ClassIndex)

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

		for property, value in ClassIndex.FetchClassIcon(object.ClassName) do
			imageLabel[property] = value
		end

		imageLabel.Parent = parent

		return imageLabel
	end,

	Update = function(self: IMGuiLabel, size: UDim2, object: Instance)
		self.TopInstance.Size = size

		for property, value in ClassIndex.FetchClassIcon(object.ClassName) do
			self.TopInstance[property] = value
		end
	end,
})

return nil
