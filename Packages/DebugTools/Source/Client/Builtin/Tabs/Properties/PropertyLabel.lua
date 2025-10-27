local IMGui = require(script.Parent.Parent.Parent.Parent.IMGui)

type IMGuiPropertyLabel = IMGui.WidgetInstance & {
	TopInstance: Frame,
}

local instanceColorMap = {
	["string"] = "#adf195",
	["number"] = "#ffc600",
	["Vector3"] = "#ffc600",
	["CFrame"] = "#ffc600",
	["Instance"] = "#61a1f1",
	["EnumItem"] = "#61a1f1",
	["boolean"] = "#ff1a1a",
	["nil"] = "#ffc600",
}

IMGui:NewWidgetDefinition("PropertyLabel", {
	Construct = function(self: IMGuiPropertyLabel, parent: GuiObject, object: Instance, property: string)
		local objectProperty = object[property]
		local objectPropertyTostring = tostring(objectProperty)
		local objectPropertyType = typeof(objectProperty)

		if objectPropertyType == "string" then
			objectPropertyTostring = `"{objectPropertyTostring}"`
		end

		if instanceColorMap[objectPropertyType] then
			objectPropertyTostring =
				`<font color="{instanceColorMap[objectPropertyType]}">{objectPropertyTostring}</font>`
		end

		local Frame = Instance.new("Frame")
		Frame.Name = `ExplorerHorizontal ({self.ID})`
		Frame.Size = UDim2.new(1.00, 0, 0.00, 15)
		Frame.BackgroundTransparency = 1.00
		Frame.BorderSizePixel = 0
		Frame.Active = true

		local UIListLayout = Instance.new("UIListLayout")
		UIListLayout.Name = "UIListLayout"
		UIListLayout.Padding = UDim.new(0, 2)
		UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Parent = Frame

		local propertyNameTextInstance: TextLabel = Instance.new("TextLabel")
		propertyNameTextInstance.Name = `Label ({self.ID})`
		propertyNameTextInstance.Size = UDim2.fromScale(0.35, 1)
		propertyNameTextInstance.Text = `<b>{property}</b>`
		propertyNameTextInstance.RichText = true
		propertyNameTextInstance.BackgroundTransparency = 1.00
		propertyNameTextInstance.BorderSizePixel = 0
		propertyNameTextInstance.Parent = Frame
		propertyNameTextInstance.TextXAlignment = Enum.TextXAlignment.Left

		local propertyValueTextInstance: TextLabel = Instance.new("TextLabel")
		propertyValueTextInstance.Name = `Label ({self.ID})`
		propertyValueTextInstance.Size = UDim2.fromScale(0.65, 1)
		propertyValueTextInstance.Position = UDim2.fromScale(0.35, 0)
		propertyValueTextInstance.Text = `<i>{objectPropertyType}</i> [{objectPropertyTostring}]`
		propertyValueTextInstance.RichText = true
		propertyValueTextInstance.BackgroundTransparency = 1.00
		propertyValueTextInstance.BorderSizePixel = 0
		propertyValueTextInstance.Parent = Frame
		propertyValueTextInstance.TextXAlignment = Enum.TextXAlignment.Left

		IMGui.applyTextStyle(propertyNameTextInstance)
		IMGui.applyTextStyle(propertyValueTextInstance)

		self.TopInstance = Frame

		Frame.Parent = parent

		return Frame
	end,

	Update = function(_: IMGuiPropertyLabel, _: Instance, _: string) end,
})

return nil
