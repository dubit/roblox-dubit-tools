require(script.Interface)

local function requireInstanceIfModuleScript(instance: Instance)
	if not instance:IsA("ModuleScript") then
		return
	end

	task.spawn(require, instance)
end

local builtinFolder = script:WaitForChild("Builtin")
local widgetsFolder = builtinFolder:WaitForChild("Widgets")
local actionsFolder = builtinFolder:WaitForChild("Actions")

widgetsFolder.ChildAdded:Connect(requireInstanceIfModuleScript)
for _, childInstance in widgetsFolder:GetChildren() do
	requireInstanceIfModuleScript(childInstance)
end

actionsFolder.ChildAdded:Connect(requireInstanceIfModuleScript)
for _, childInstance in actionsFolder:GetChildren() do
	requireInstanceIfModuleScript(childInstance)
end

local DebugTools = {}

DebugTools.interface = {
	Tab = require(script.Tab),
	Widget = require(script.Widget),
	Action = require(script.Parent.Shared.Action),
	Networking = require(script.Networking),
	IMGui = require(script.IMGui),
	Console = require(script.Console),

	BuiltinTabs = {
		Tags = require(script.Builtin.Tabs.Tags),
		Widgets = require(script.Builtin.Tabs.Widgets),
		Actions = require(script.Builtin.Tabs.Actions),
		Explorer = require(script.Builtin.Tabs.Explorer),
	},
}

return DebugTools.interface
