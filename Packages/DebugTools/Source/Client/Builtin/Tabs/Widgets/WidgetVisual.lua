--!strict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local insetSize: Vector2 = GuiService:GetGuiInset()

local DebugToolRootPath = script.Parent.Parent.Parent.Parent
local SharedRootPath = DebugToolRootPath.Parent.Shared

local Signal = require(SharedRootPath.Signal)

local WidgetVisual = {}
WidgetVisual.internal = {}
WidgetVisual.prototype = {}
WidgetVisual.interface = {}

function WidgetVisual.internal.createWidgetRepresentation(widgetVisual, representationParent: Frame)
	local screenBoundingInstance: GuiBase = widgetVisual.WidgetScreenGui:GetChildren()[1]

	local screenRepresentation: TextButton = Instance.new("TextButton")
	screenRepresentation.Name = widgetVisual.WidgetName
	screenRepresentation.AutoLocalize = false
	screenRepresentation.Size = UDim2.fromOffset(60, 30)
	screenRepresentation.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	screenRepresentation.BackgroundTransparency = 0.5
	screenRepresentation.BorderSizePixel = 0
	screenRepresentation.Text = ""

	local uiCorner: UICorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(0.00, 4)
	uiCorner.Parent = screenRepresentation

	widgetVisual.FrameRepresentation = screenRepresentation
	widgetVisual.BoundingInstance = screenBoundingInstance

	screenRepresentation.Parent = representationParent
end

function WidgetVisual.internal.observeWidgetChanges(widgetVisual)
	local screenRepresentation: TextButton = widgetVisual.FrameRepresentation

	widgetVisual.InteractionConnection = screenRepresentation.InputBegan:Connect(function(beganInputObject: InputObject)
		if
			beganInputObject.UserInputType ~= Enum.UserInputType.MouseButton1
			and beganInputObject.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local widgetRepresentationAbsolutePosition: Vector2 = screenRepresentation.AbsolutePosition + insetSize

		local offset: Vector2 = UserInputService:GetMouseLocation() - widgetRepresentationAbsolutePosition
		offset = Vector2.new(math.floor(offset.X), math.floor(offset.Y))

		widgetVisual.Activated:Fire(offset)
	end)

	widgetVisual.AbsolutePositionChangedConnection = widgetVisual.BoundingInstance
		:GetPropertyChangedSignal("AbsolutePosition")
		:Connect(function()
			widgetVisual:UpdateRepresentation()
		end)

	widgetVisual.AbsoluteSizeChangedConnection = widgetVisual.BoundingInstance
		:GetPropertyChangedSignal("AbsoluteSize")
		:Connect(function()
			widgetVisual:UpdateRepresentation()
		end)

	widgetVisual:UpdateRepresentation()
end

function WidgetVisual.prototype:UpdateRepresentation()
	local parentSize: Vector2 = self.FrameRepresentation.Parent.AbsoluteSize

	local realScreenSize: Vector2 = workspace.CurrentCamera.ViewportSize
	local realWidgetPosition: Vector2 = self.BoundingInstance.AbsolutePosition + insetSize
	local realWidgetSize: Vector2 = self.BoundingInstance.AbsoluteSize
	local realPositionScaled: Vector2 = realWidgetPosition / realScreenSize
	local realSizeScaled: Vector2 = realWidgetSize / realScreenSize

	local widgetRepresentationPosition: Vector2 = parentSize * realPositionScaled
	local widgetRepresentationSize: Vector2 = parentSize * realSizeScaled

	self.FrameRepresentation.Position = UDim2.fromOffset(widgetRepresentationPosition.X, widgetRepresentationPosition.Y)
	self.FrameRepresentation.Size = UDim2.fromOffset(widgetRepresentationSize.X, widgetRepresentationSize.Y)
end

function WidgetVisual.prototype:Destroy()
	self.InteractionConnection:Disconnect()
	self.AbsolutePositionChangedConnection:Disconnect()
	self.AbsoluteSizeChangedConnection:Disconnect()

	self.FrameRepresentation:Destroy()
	self.Activated:Destroy()
end

function WidgetVisual.interface.new(widgetName: string, widgetScreenGui: ScreenGui, representationFrame: Frame)
	assert(type(widgetName) == "string", `Expected parameter #1 'widgetName' to be a string, got {type(widgetName)}`)

	local self = setmetatable({
		WidgetName = widgetName,
		WidgetScreenGui = widgetScreenGui,

		Activated = Signal.new(),
	}, {
		__index = WidgetVisual.prototype,
	})

	WidgetVisual.internal.createWidgetRepresentation(self, representationFrame)
	WidgetVisual.internal.observeWidgetChanges(self)

	return self
end

return WidgetVisual.interface
