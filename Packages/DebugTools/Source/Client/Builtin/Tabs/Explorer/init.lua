local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)

require(script.ClassIcon)
require(script.BeginExplorerHorizontal)

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

	IMGui:Label(`<i>{instance.ClassName}</i> ["{instance.Name}"]`)

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

Tab.new("Explorer", function(parent: Frame)
	return IMGui:Connect(parent, function()
		IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))
		IMGui:BeginVertical()

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
		IMGui:End()
	end)
end)

return Explorer.interface
