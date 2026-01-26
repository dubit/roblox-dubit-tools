local function requireInstanceIfModuleScript(instance: Instance)
	if not instance:IsA("ModuleScript") then
		return
	end

	task.spawn(require, instance)
end

require(script:WaitForChild("Interface"))

local builtinFolder = script:WaitForChild("Builtin")
local widgetsFolder = builtinFolder:WaitForChild("Widgets")
local tabsFolder = builtinFolder:WaitForChild("Tabs")

widgetsFolder.ChildAdded:Connect(requireInstanceIfModuleScript)
for _, childInstance in widgetsFolder:GetChildren() do
	requireInstanceIfModuleScript(childInstance)
end

tabsFolder.ChildAdded:Connect(requireInstanceIfModuleScript)
for _, childInstance in tabsFolder:GetChildren() do
	requireInstanceIfModuleScript(childInstance)
end

local DebugTools = {}

DebugTools.interface = {
	-- Client specific
	Tab = require(script:WaitForChild("Tab")),
	IMGui = require(script:WaitForChild("IMGui")),
	Widget = require(script:WaitForChild("Widget")),
	Console = require(script:WaitForChild("Console")),

	-- Shared API with server
	Networking = require(script.Networking),
	Authorization = require(script.Authorization),
	Action = require(script.Parent.Shared.Action),
}

DebugTools.interface.Client = DebugTools.interface

return DebugTools.interface
