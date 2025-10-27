local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)

local ClassIndex = require(DebugToolRootPath.Vendor:WaitForChild("ClassIndex") :: ModuleScript)

local Explorer = require(script.Parent.Explorer)

require(script.PropertyLabel)

local Properties = {}

Properties.interface = {}
Properties.internal = {}

function Properties.internal.getPropertiesFor(object)
	local superclasses = ClassIndex.FetchClassSuperclasses(object.ClassName)
	local properties = {}

	table.insert(superclasses, 1, object.ClassName)

	for _, superclass in superclasses do
		properties[superclass] = {}
	end

	for _, superclass in superclasses do
		if superclass == "<<<ROOT>>>" then
			continue
		end

		local members = ClassIndex.FetchClassMembers(superclass)

		for _, member in members do
			local memberType = ClassIndex.FetchClassMemberType(superclass, member)
			local memberTags = ClassIndex.FetchClassMemberTags(superclass, member)

			if memberTags.Deprecated then
				continue
			end

			if memberType == "Property" then
				table.insert(properties[superclass], member)
			end
		end
	end

	return properties
end

Tab.new("Properties", function(parent: Frame)
	return IMGui:Connect(parent, function()
		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))
		IMGui:BeginVertical()

		local object = Explorer.getSelectedObject()

		if not object then
			IMGui:Label(
				`No instace currently selected, please go to the 'Explorer'/'Components' page and select an instance.`
			)
		else
			local objectProperties = Properties.internal.getPropertiesFor(object)

			IMGui:Label(`<b><i>{object.ClassName}</i> ["{object:GetFullName()}"]</b>`)

			for superclass, classProperties in objectProperties do
				if #classProperties == 0 then
					continue
				end

				IMGui:Label("")
				IMGui:Label(`<b><i>Superclass</i> [{superclass}]</b>`)

				for _, propertyName in classProperties do
					IMGui:PropertyLabel(object, propertyName)
				end
			end
		end

		IMGui:End()
		IMGui:End()
	end)
end)

return Properties.interface
