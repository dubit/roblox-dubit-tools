--!strict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local DebugToolRootPath = script.Parent.Parent.Parent

local Tab = require(DebugToolRootPath.Tab)
local Widget = require(DebugToolRootPath.Widget)

local WidgetVisual = require(script.WidgetVisual)
local WidgetsList = require(script.WidgetsList)

type FakeScreen = {
	ScreenFrame: Frame,
	ScreenFrameAspectRatio: UIAspectRatioConstraint,

	AbsoluteSizeChangedConnection: RBXScriptConnection?,
}

type WidgetVisualData = {
	WidgetVisual: any,
	ActivatedConnection: any,
}

local WidgetsModule = {}
WidgetsModule.internal = {
	WidgetVisuals = {} :: { WidgetVisualData },
	DraggedWidgetVisual = false,

	ActiveInputEndedConnection = nil :: RBXScriptConnection?,
	ActiveInputChangedConnection = nil :: RBXScriptConnection?,

	CurrentCameraChangedConnection = nil :: RBXScriptConnection?,
	CurrentViewportSizeChangedConnection = nil :: RBXScriptConnection?,

	FakeScreen = {} :: FakeScreen,
}

function WidgetsModule.internal.createWidgetRepresentation(widgetName: string, widgetScreenGui: ScreenGui)
	local widgetVisual = WidgetVisual.new(widgetName, widgetScreenGui, WidgetsModule.internal.FakeScreen.ScreenFrame)

	table.insert(WidgetsModule.internal.WidgetVisuals, {
		WidgetVisual = widgetVisual,
	})

	WidgetsModule.internal.listenToWidgetVisualEvents(widgetVisual)
end

function WidgetsModule.internal.getRegistryWidgetRecord(widgetVisual): WidgetVisualData?
	for _, widgetVisualData: WidgetVisualData in WidgetsModule.internal.WidgetVisuals do
		if widgetVisualData.WidgetVisual == widgetVisual then
			return widgetVisualData
		end
	end

	return nil
end

function WidgetsModule.internal.listenToWidgetVisualEvents(widgetVisual)
	local widgetVisualData: WidgetVisualData = WidgetsModule.internal.getRegistryWidgetRecord(widgetVisual)
	if not widgetVisualData then
		return
	end

	widgetVisualData.ActivatedConnection = widgetVisual.Activated:Connect(function(mouseOffset: Vector2)
		if WidgetsModule.internal.DraggedWidgetVisual then
			return
		end

		WidgetsModule.internal.DraggedWidgetVisual = widgetVisual

		WidgetsModule.internal.ActiveInputChangedConnection = UserInputService.InputChanged:Connect(
			function(inputObject: InputObject)
				if
					inputObject.UserInputType ~= Enum.UserInputType.MouseMovement
					and inputObject.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				local fakeScreenAbsoluteSize: Vector2 = WidgetsModule.internal.FakeScreen.ScreenFrame.AbsoluteSize
				local fakeScreenAbsolutePosition: Vector2 =
					WidgetsModule.internal.FakeScreen.ScreenFrame.AbsolutePosition

				local widgetAnchorOffset: Vector2 = -(
					widgetVisual.FrameRepresentation.AbsoluteSize * -widgetVisual.BoundingInstance.AnchorPoint
				)

				local fakeScreenMousePosition: Vector2 = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
					- fakeScreenAbsolutePosition
					- mouseOffset
					+ widgetAnchorOffset

				local realScreenCoordinates: Vector2 = fakeScreenMousePosition / fakeScreenAbsoluteSize

				widgetVisual.BoundingInstance.Position =
					UDim2.fromScale(realScreenCoordinates.X, realScreenCoordinates.Y)
			end
		)

		WidgetsModule.internal.ActiveInputEndedConnection = UserInputService.InputEnded:Connect(
			function(inputObject: InputObject)
				if
					inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
					and inputObject.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				WidgetsModule.internal.ActiveInputChangedConnection:Disconnect()
				WidgetsModule.internal.ActiveInputChangedConnection = nil

				WidgetsModule.internal.ActiveInputEndedConnection:Disconnect()
				WidgetsModule.internal.ActiveInputEndedConnection = nil

				WidgetsModule.internal.DraggedWidgetVisual = nil
			end
		)
	end)
end

function WidgetsModule.internal.listenToCurrentCameraViewportChanges()
	if WidgetsModule.internal.CurrentViewportSizeChangedConnection then
		WidgetsModule.internal.CurrentViewportSizeChangedConnection:Disconnect()
	end

	WidgetsModule.internal.CurrentViewportSizeChangedConnection = workspace.CurrentCamera
		:GetPropertyChangedSignal("ViewportSize")
		:Connect(function()
			local newViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize

			if not WidgetsModule.internal.FakeScreen then
				return
			end

			WidgetsModule.internal.FakeScreen.ScreenFrameAspectRatio.AspectRatio = newViewportSize.X / newViewportSize.Y
		end)
end

function WidgetsModule.internal.createWidgetInterface(parent: Frame)
	local viewportSize: Vector2 = workspace.CurrentCamera.ViewportSize

	local screenRepresentationFrame: Frame = Instance.new("Frame")
	screenRepresentationFrame.Name = "Fake Screen"
	screenRepresentationFrame.Position = UDim2.fromScale(0.00, 0.50)
	screenRepresentationFrame.Size = UDim2.fromScale(0.75, 1.00)
	screenRepresentationFrame.AnchorPoint = Vector2.new(0.00, 0.50)
	screenRepresentationFrame.BackgroundColor3 = Color3.fromRGB(79, 88, 105)
	screenRepresentationFrame.BorderSizePixel = 0

	local screenUIAspectRatioConstraint: UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	screenUIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	screenUIAspectRatioConstraint.AspectRatio = viewportSize.X / viewportSize.Y
	screenUIAspectRatioConstraint.Parent = screenRepresentationFrame

	screenRepresentationFrame.Parent = parent

	WidgetsModule.internal.FakeScreen = {
		ScreenFrame = screenRepresentationFrame,
		ScreenFrameAspectRatio = screenUIAspectRatioConstraint,

		AbsoluteSizeChangedConnection = screenRepresentationFrame
			:GetPropertyChangedSignal("AbsoluteSize")
			:Connect(function()
				for _, widgetVisual in WidgetsModule.internal.WidgetVisuals do
					widgetVisual.WidgetVisual:UpdateRepresentation()
				end
			end),
	}
end

function WidgetsModule.internal:MountInterface(parent: Frame)
	WidgetsModule.internal.createWidgetInterface(parent)

	WidgetsModule.internal.WidgetsListDestructor = WidgetsList(parent)

	for widgetName: string, widgetData in Widget:GetAll() do
		if widgetData.Mounted then
			WidgetsModule.internal.createWidgetRepresentation(widgetName, widgetData.ScreenGui)
		end
	end

	WidgetsModule.internal.WidgetMountedConnection = Widget.WidgetMounted:Connect(
		function(widgetName: string, widgetScreenGui: ScreenGui)
			WidgetsModule.internal.createWidgetRepresentation(widgetName, widgetScreenGui)
		end
	)

	WidgetsModule.internal.WidgetUnmountedConnection = Widget.WidgetUnmounted:Connect(function(widgetName: string)
		for visualIndex: number, widgetVisual in WidgetsModule.internal.WidgetVisuals do
			if widgetVisual.WidgetVisual.WidgetName == widgetName then
				widgetVisual.WidgetVisual:Destroy()
				widgetVisual.ActivatedConnection:Disconnect()
				widgetVisual.ActivatedConnection = nil
				table.remove(WidgetsModule.internal.WidgetVisuals, visualIndex)
			end
		end
	end)

	WidgetsModule.internal.CurrentCameraChangedConnection = workspace
		:GetPropertyChangedSignal("CurrentCamera")
		:Connect(function()
			WidgetsModule.internal.listenToCurrentCameraViewportChanges()
		end)

	WidgetsModule.internal.listenToCurrentCameraViewportChanges()
end

function WidgetsModule.internal:UnmountInterface()
	WidgetsModule.internal.WidgetMountedConnection:Disconnect()
	WidgetsModule.internal.WidgetMountedConnection = nil

	WidgetsModule.internal.WidgetUnmountedConnection:Disconnect()
	WidgetsModule.internal.WidgetUnmountedConnection = nil

	WidgetsModule.internal.CurrentCameraChangedConnection:Disconnect()
	WidgetsModule.internal.CurrentCameraChangedConnection = nil

	WidgetsModule.internal.CurrentViewportSizeChangedConnection:Disconnect()
	WidgetsModule.internal.CurrentViewportSizeChangedConnection = nil

	WidgetsModule.internal.FakeScreen.AbsoluteSizeChangedConnection:Disconnect()
	WidgetsModule.internal.FakeScreen.AbsoluteSizeChangedConnection = nil

	WidgetsModule.internal.FakeScreen.ScreenFrame:Destroy()
	WidgetsModule.internal.FakeScreen = {}

	WidgetsModule.internal.WidgetsListDestructor()
	WidgetsModule.internal.WidgetsListDestructor = nil

	for _, widgetVisual: WidgetVisualData in WidgetsModule.internal.WidgetVisuals do
		widgetVisual.WidgetVisual:Destroy()
	end

	WidgetsModule.internal.WidgetVisuals = {}
end

Tab.new("Widgets", function(parent: Frame)
	WidgetsModule.internal:MountInterface(parent)

	return function()
		WidgetsModule.internal:UnmountInterface()
	end
end)

return nil
