local IMGui = require(script.Parent.Parent.Parent.Parent.IMGui)

type IMGuiPropertyLabel = IMGui.WidgetInstance & {
	Label: TextLabel,
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
	Construct = function(
		self: IMGuiPropertyLabel,
		parent: GuiObject,
		object: Instance,
		property: string,
		isAttribute: boolean
	)
		local objectProperty = isAttribute and object:GetAttribute(property) or object[property]
		local objectPropertyTostring = tostring(objectProperty)
		local objectPropertyType = typeof(objectProperty)

		if objectPropertyType == "string" then
			objectPropertyTostring = `"{objectPropertyTostring}"`
		end

		if instanceColorMap[objectPropertyType] then
			objectPropertyTostring =
				`<font color="{instanceColorMap[objectPropertyType]}">{objectPropertyTostring}</font>`
		end

		local propertyNameTextInstance: TextLabel = Instance.new("TextLabel")
		propertyNameTextInstance.Name = `Property ({self.ID})`
		propertyNameTextInstance.Size = UDim2.fromScale(0, 0)
		propertyNameTextInstance.AutomaticSize = Enum.AutomaticSize.XY
		propertyNameTextInstance.Text =
			`  <b>{property}</b>    <mark color="#000000" transparency="0.75">{objectPropertyTostring}</mark>	`
		propertyNameTextInstance.RichText = true
		propertyNameTextInstance.BackgroundTransparency = 1.00
		propertyNameTextInstance.BorderSizePixel = 0
		propertyNameTextInstance.TextXAlignment = Enum.TextXAlignment.Left
		propertyNameTextInstance.Parent = parent

		self.Label = propertyNameTextInstance

		IMGui.applyTextStyle(propertyNameTextInstance)

		return propertyNameTextInstance
	end,

	Update = function(self: IMGuiPropertyLabel, object: Instance, property: string, isAttribute: boolean)
		local objectProperty = isAttribute and object:GetAttribute(property) or object[property]
		local objectPropertyTostring = tostring(objectProperty)
		local objectPropertyType = typeof(objectProperty)

		if objectPropertyType == "string" then
			objectPropertyTostring = `"{objectPropertyTostring}"`
		end

		if instanceColorMap[objectPropertyType] then
			objectPropertyTostring =
				`<font color="{instanceColorMap[objectPropertyType]}">{objectPropertyTostring}</font>`
		end

		self.Label.Text =
			`  <b>{property}</b>    <mark color="#000000" transparency="0.75">{objectPropertyTostring}</mark>	`
	end,
})

return nil
