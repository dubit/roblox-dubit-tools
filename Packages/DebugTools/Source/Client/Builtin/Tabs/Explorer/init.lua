local ReflectionService = game:GetService("ReflectionService")
local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)

require(script.ClassIcon)
require(script.BeginExplorerHorizontal)
require(script.PropertyLabel)

local Explorer = {}

Explorer.interface = {}
Explorer.internal = {
	ExpandedInstances = {},
	SelectedInstance = nil,
}

function Explorer.internal.processChildren(instances: { Instance }, depth: number?)
	for _, object in instances do
		Explorer.internal.processInstance(object, (depth or -1) + 1)
	end
end

function Explorer.internal.processInstance(instance: Instance, depth: number)
	local children = instance:GetChildren()
	local arrowIcon = #children == 0 and ""
		or Explorer.internal.ExpandedInstances[instance] and "http://www.roblox.com/asset/?id=17115119309"
		or "http://www.roblox.com/asset/?id=17115120806"

	if IMGui:BeginExplorerHorizontal(Explorer.internal.SelectedInstance == instance).activated() then
		Explorer.internal.SelectedInstance = instance
	end

	IMGui:BeginGroup(UDim2.fromOffset(10 * depth, 0))
	IMGui:End()

	if IMGui:ImageButton(UDim2.fromOffset(16, 16), arrowIcon).activated() then
		Explorer.internal.ExpandedInstances[instance] = not Explorer.internal.ExpandedInstances[instance]
	end

	IMGui:ExplorerClassIcon(UDim2.fromOffset(16, 16), instance)

	IMGui:BeginGroup(UDim2.fromOffset(5, 0))
	IMGui:End()

	IMGui:Label(instance.Name)

	IMGui:End()

	if Explorer.internal.ExpandedInstances[instance] then
		Explorer.internal.processChildren(children, depth + 1)
	end
end

function Explorer.interface.getSelectedObject()
	return Explorer.internal.SelectedInstance
end

function Explorer.interface.setSelectedObject(instance: Instance)
	Explorer.internal.SelectedInstance = instance

	local object = instance

	while true do
		Explorer.internal.ExpandedInstances[object] = true

		object = object.Parent

		if object == game or object == nil then
			return
		end
	end
end

local explorerCapabilities =
	SecurityCapabilities.new(Enum.SecurityCapability.Players, Enum.SecurityCapability.WritePlayer)

Tab.new("Explorer", function(parent: Frame)
	return IMGui:Connect(parent, function()
		IMGui:BeginHorizontal()

		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))

		Explorer.internal.processChildren({
			game:GetService("Workspace"),
			game:GetService("Players"),
			game:GetService("Lighting"),
			game:GetService("MaterialService"),
			game:GetService("ReplicatedFirst"),
			game:GetService("ReplicatedStorage"),
			game:GetService("ServerScriptService"),
			game:GetService("ServerStorage"),
			game:GetService("StarterGui"),
			game:GetService("StarterPack"),
			game:GetService("StarterPlayer"),
			game:GetService("Teams"),
			game:GetService("SoundService"),
			game:GetService("Chat"),
			game:GetService("TextChatService"),
			game:GetService("VoiceChatService"),
			game:GetService("LocalizationService"),
		})

		IMGui:End()

		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))
		IMGui:UISizeConstraint(Vector2.new(300, 0))

		local selectedObject = Explorer.interface.getSelectedObject()
		if selectedObject then
			IMGui:Label(`<b>{selectedObject.Name}</b>`)
			IMGui:Label(selectedObject.ClassName)

			local classProperties =
				ReflectionService:GetPropertiesOfClass(selectedObject.ClassName, { Security = explorerCapabilities })

			local categories = {}

			if classProperties then
				for _, property in classProperties do
					if not property.Permits or not property.Permits.Read or not property.Permits.Write then
						continue
					end

					if property.Display.DeprecationMessage then
						continue
					end

					if not categories[property.Display.Category] then
						categories[property.Display.Category] = {}
					end

					table.insert(categories[property.Display.Category], property.Name)
				end
			end

			for category, properties in categories do
				IMGui:Label("")
				IMGui:Label(`<b>{category}</b>`)
				for _, propertyName in properties do
					IMGui:PropertyLabel(selectedObject, propertyName)
				end
			end

			IMGui:Label("")
			IMGui:Label(`<b>Tags</b>`)
			for _, tag in selectedObject:GetTags() do
				IMGui:Label(`  {tag}`)
			end

			IMGui:Label("")
			IMGui:Label(`<b>Attributes</b>`)
			for name in selectedObject:GetAttributes() do
				IMGui:PropertyLabel(selectedObject, name, true)
			end
		end

		IMGui:End()
	end)
end)

return Explorer.interface
