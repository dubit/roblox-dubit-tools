--[[
	Checks if a GuiBase object and all its ancestors are visible/enabled.
]]
return function(object: GuiBase)
	local objectToValidate = object

	while objectToValidate and objectToValidate:IsA("GuiBase") do
		if objectToValidate:IsA("GuiObject") then
			if not objectToValidate.Visible then
				return false
			end
		elseif objectToValidate:IsA("LayerCollector") then
			if not objectToValidate.Enabled then
				return false
			end
		end

		objectToValidate = objectToValidate.Parent
	end

	return true
end
