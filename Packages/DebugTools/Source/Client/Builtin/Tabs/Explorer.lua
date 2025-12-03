local ReflectionService = game:GetService("ReflectionService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local IMGui = require(DebugToolRootPath.IMGui)
local Widget = require(DebugToolRootPath.Widget)

local EXPLORER_CAPABILITIES = SecurityCapabilities.new(
	Enum.SecurityCapability.Players,
	Enum.SecurityCapability.UI,
	Enum.SecurityCapability.Basic,
	Enum.SecurityCapability.Animation,
	Enum.SecurityCapability.Audio,
	Enum.SecurityCapability.Avatar,
	Enum.SecurityCapability.Environment,
	Enum.SecurityCapability.LegacySound,
	Enum.SecurityCapability.Network,
	Enum.SecurityCapability.WritePlayer
)

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

	if IMGui:TreeNode(Explorer.internal.SelectedInstance == instance).activated() then
		Explorer.internal.SelectedInstance = instance
	end

	IMGui:BeginGroup(UDim2.fromOffset(5 * depth, 0))
	IMGui:End()

	if IMGui:ImageButton(UDim2.fromOffset(16, 16), arrowIcon).activated() then
		Explorer.internal.ExpandedInstances[instance] = not Explorer.internal.ExpandedInstances[instance]
	end

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

local function drawExplorer()
	IMGui:Label(`<b>Explorer</b>`)

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
end

local function drawProperties()
	IMGui:Label(`<b>Properties</b>`)
	IMGui:ScrollingFrameY(UDim2.fromScale(1, 1))

	local selectedObject = Explorer.interface.getSelectedObject()
	if selectedObject then
		IMGui:Label(`<b>{selectedObject.Name}</b>`)
		IMGui:Label(selectedObject.ClassName)

		local classProperties =
			ReflectionService:GetPropertiesOfClass(selectedObject.ClassName, { Security = EXPLORER_CAPABILITIES })

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
				local newValue = IMGui:PropertyInspector(propertyName, selectedObject[propertyName]).changed()

				if newValue ~= nil then
					selectedObject[propertyName] = newValue
				end
			end
		end

		IMGui:Label("")
		IMGui:Label(`<b>Tags</b>`)
		for _, tag in selectedObject:GetTags() do
			if IMGui:Button(`{tag}`).activated() then
				selectedObject:RemoveTag(tag)
			end
		end

		IMGui:Label("")
		IMGui:Label(`<b>Attributes</b>`)
		for name, value in selectedObject:GetAttributes() do
			local newValue = IMGui:PropertyInspector(name, value).changed()

			if newValue ~= nil then
				selectedObject:SetAttribute(name, newValue)
			end
		end
	end

	IMGui:End()
end

Tab.new("Explorer", function(parent: Frame)
	return IMGui:Connect(parent, function()
		IMGui:BeginHorizontal()

		IMGui:BeginGroup(UDim2.fromScale(1, 1))
		IMGui:BeginVertical()

		drawExplorer()

		IMGui:End()
		IMGui:End()

		--

		IMGui:BeginGroup(UDim2.fromScale(2, 1))
		IMGui:BeginVertical()

		drawProperties()

		IMGui:End()
		IMGui:End()

		IMGui:End()
	end)
end)

Widget.new("Explorer", function(parent: ScreenGui)
	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.AnchorPoint = Vector2.new(0.50, 0.50)
	contentFrame.Position = UDim2.new(0.50, 8, 0.50, -8)
	contentFrame.Size = UDim2.fromScale(1.00, 0.50)
	contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	contentFrame.BackgroundTransparency = 0.50

	contentFrame.Parent = parent

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.Parent = contentFrame

	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.AspectRatio = 0.50
	uiAspectRatioConstraint.Parent = contentFrame

	local imguiConnection = IMGui:Connect(contentFrame, drawExplorer)

	return function()
		imguiConnection()

		contentFrame:Destroy()
	end
end)

Widget.new("Properties", function(parent: ScreenGui)
	local contentFrame: Frame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.AnchorPoint = Vector2.new(0.50, 0.50)
	contentFrame.Position = UDim2.new(0.50, 8, 0.50, -8)
	contentFrame.Size = UDim2.fromScale(1.00, 0.50)
	contentFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	contentFrame.BackgroundTransparency = 0.50

	contentFrame.Parent = parent

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(0.00, 8)
	uiPadding.PaddingLeft = UDim.new(0.00, 8)
	uiPadding.PaddingRight = UDim.new(0.00, 8)
	uiPadding.PaddingTop = UDim.new(0.00, 8)
	uiPadding.Parent = contentFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.Parent = contentFrame

	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.AspectRatio = 0.50
	uiAspectRatioConstraint.Parent = contentFrame

	local imguiConnection = IMGui:Connect(contentFrame, drawProperties)

	return function()
		imguiConnection()

		contentFrame:Destroy()
	end
end)

Widget:Hide("Explorer")
Widget:Hide("Properties")

return Explorer.interface
