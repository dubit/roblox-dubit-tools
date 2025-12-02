local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Authorization = require(script.Authorization)
local DebugInterface = require(script.Interface)

type TouchPointData = {
	Position: Vector2,
	HoldTime: number,
	InputChangedConnection: RBXScriptConnection?,
}

if not Authorization:IsLocalPlayerAuthorized() then
	return { Authorized = false }
end

local DebugTools = {}

DebugTools.internal = {
	SwitchKey = Enum.KeyCode.F6,
}

DebugTools.interface = {
	Tab = require(script.Tab),
	Widget = require(script.Widget),
	Action = require(script.Parent.Shared.Action),
	Networking = require(script.Networking),
	IMGui = require(script.IMGui),

	Authorized = true,

	BuiltinTabs = {
		Console = require(script.Builtin.Tabs.Console),
		Tags = require(script.Builtin.Tabs.Tags),
		Widgets = require(script.Builtin.Tabs.Widgets),
		Actions = require(script.Builtin.Tabs.Actions),
		Explorer = require(script.Builtin.Tabs.Explorer),
	},

	BuiltinWidgets = {
		PlaceStats = require(script.Builtin.Widgets.PlaceStats),
		Coordinates = require(script.Builtin.Widgets.Coordinates),
		KeyboardInput = require(script.Builtin.Widgets.KeyboardInput),
		CodeWarnings = require(script.Builtin.Widgets.CodeWarnings),
		PerformanceStats = require(script.Builtin.Widgets.PerformanceStats),
	},

	BuiltinActions = {
		ShowCollisions = require(script.Builtin.Actions.ShowCollisions),
		SetWalkspeed = require(script.Builtin.Actions.SetWalkspeed),
		SetNoclip = require(script.Builtin.Actions.SetNoclip),
		SetFPS = require(script.Builtin.Actions.SetFPS),
	},

	Style = require(script.Style),

	Accessible = true,
}

function DebugTools.internal.observeKeyBinds()
	UserInputService.InputBegan:Connect(function(inputObject: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end

		if inputObject.KeyCode ~= DebugTools.internal.SwitchKey then
			return
		end

		DebugInterface.switchVisibility()
	end)
end

function DebugTools.internal.observeMobileGesture()
	local touchPoints: { InputObject } = {}

	local function removeTouchPoint(inputObject: InputObject)
		for objectIndex: number, otherInputObject: InputObject in touchPoints do
			if otherInputObject == inputObject then
				table.remove(touchPoints, objectIndex)
				return
			end
		end
	end

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local viewportSize: Vector2 = workspace.CurrentCamera.ViewportSize

		local pointXMiddlePercentage: number =
			math.abs((viewportSize.X / 2.00 - inputObject.Position.X) / viewportSize.X)
		local pointYPercentage: number = inputObject.Position.Y / viewportSize.Y
		if pointYPercentage > 0.00 or pointXMiddlePercentage >= 0.10 then
			return
		end

		table.insert(touchPoints, inputObject)

		if #touchPoints >= 3 then
			for _, otherInputObject: InputObject in touchPoints do
				removeTouchPoint(otherInputObject)
			end

			DebugInterface.switchVisibility()
		end

		task.delay(0.75, function()
			removeTouchPoint(inputObject)
		end)
	end)
end

function DebugTools.internal.observeConsoleKeyBinds()
	local consoleActivationButtons = {
		[Enum.KeyCode.ButtonL1] = true,
		[Enum.KeyCode.ButtonR1] = true,
		[Enum.KeyCode.ButtonY] = true,
	}

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if consoleActivationButtons[inputObject.KeyCode] then
			for buttonKey in consoleActivationButtons do
				if not UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, buttonKey) then
					return
				end
			end

			DebugInterface.switchVisibility()

			GuiService.SelectedObject = DebugInterface.getTabsFrame():FindFirstChildWhichIsA("TextButton")
		end
	end)
end

function DebugTools.internal.observeConsoleKeyBindsForDevConsole()
	local consoleActivationButtons = {
		[Enum.KeyCode.ButtonL1] = true,
		[Enum.KeyCode.ButtonR1] = true,
		[Enum.KeyCode.ButtonX] = true,
	}

	UserInputService.InputBegan:Connect(function(inputObject: InputObject)
		if consoleActivationButtons[inputObject.KeyCode] then
			for buttonKey in consoleActivationButtons do
				if not UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, buttonKey) then
					return
				end
			end

			StarterGui:SetCore("DevConsoleVisible", not StarterGui:GetCore("DevConsoleVisible"))
		end
	end)
end

DebugInterface.init()

DebugTools.internal.observeKeyBinds()
DebugTools.internal.observeMobileGesture()
DebugTools.internal.observeConsoleKeyBinds()
DebugTools.internal.observeConsoleKeyBindsForDevConsole()

for _, childInstance in script.Builtin.IMGuiWidgets:GetChildren() do
	if not childInstance:IsA("ModuleScript") then
		continue
	end

	task.spawn(require, childInstance)
end

return DebugTools.interface
