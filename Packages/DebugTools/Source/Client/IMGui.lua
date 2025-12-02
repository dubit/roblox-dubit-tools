--!strict

--[[
	A module offering ease of implementation & management of IMGui (known as "Immediate Mode GUI") in Roblox.
	It should be noted that this is performed through UI instances, NOT through a UI library such as Roact.

	Immediate Mode GUI is a GUI design pattern which instances & draws GUIs immediately in a single frame, thus GUIs are
	re-rendered on each frame. This is in opposition to the usual retained-mode pattern, in which GUIs are
	only re-rendered when necessary.
	IMGui is primarily beneficial for functional, non-user facing GUIs, such as debug displays.

	For more information on Immediate Mode GUI see: https://docs.unity3d.com/Manual/GUIScriptingGuide.html
]]

local RunService = game:GetService("RunService")

type WidgetEventTypes = "activated" | "hovered"

export type WidgetDefinition = {
	Construct: (self: any, parent: GuiObject, ...any) -> (GuiObject, GuiObject?),
	Deconstruct: ((self: any) -> nil)?,
	Update: (self: any, ...any) -> nil,
	Return: ((self: any) -> any)?,

	Events: {
		[WidgetEventTypes]: (self: any) -> Instance,
	}?,
}

export type WidgetInstance = {
	ID: string,
	Definition: string,

	Hovering: boolean?,

	TopInstance: GuiObject,

	ChildrenInstance: GuiObject?,

	LastUpdateTick: number,

	Args: { any },

	[string]: any,
}

type IMGuiFrame = {
	Stack: { WidgetInstance },
	WidgetIDs: { [string]: number },
	CurrentWidget: WidgetInstance?,
	PreviousWidget: WidgetInstance?,
	WidgetIndex: number,
}

type IMGuiInstance = {
	Parent: GuiBase,

	Tick: number,

	FrameData: IMGuiFrame,

	Widgets: { [string]: WidgetInstance },

	TickLoop: () -> nil,
}

local IMGui = {}
IMGui.private = {
	WidgetDefinitions = {} :: { [string]: WidgetDefinition },

	Instances = {} :: { [number]: IMGuiInstance },

	ProcessedInstance = nil :: IMGuiInstance?,

	CurrentConfig = table.freeze({
		Font = Font.new("rbxassetid://16658221428", Enum.FontWeight.Medium),

		Transparency = {
			Window = 0.15,
		},

		Sizes = {
			TextSize = 14,

			FrameCornerRadius = 2,

			ItemPadding = Vector2.new(4, 4),

			FramePadding = Vector2.new(5, 3),
		},

		Colors = {
			WindowBackground = Color3.fromRGB(26, 26, 33),

			Text = Color3.new(1.00, 1.00, 1.00),
			TextDisabled = Color3.new(0.50, 0.50, 0.50),

			Button = Color3.fromRGB(12, 38, 177),
			ButtonHovered = Color3.fromRGB(9, 26, 124),
			ButtonActive = Color3.fromRGB(17, 47, 220),
			ButtonDisabled = Color3.fromRGB(20, 20, 20),
		},
	}),
}
IMGui.public = {}

function areValuesEqual<A, B>(source: A, other: B)
	if typeof(source) ~= "table" or typeof(other) ~= "table" then
		return source == other
	end

	-- If either or both tables are an array then it will be the quickest method to determine if they are different
	if #source ~= #other then
		return false
	end

	for key, value in source do
		if not areValuesEqual(value, other[key]) then
			return false
		end
	end

	for key, value in other do
		if not areValuesEqual(value, source[key]) then
			return false
		end
	end

	return true
end

-- TODO: Optimize this thing, this is the worst performing thing over here
function IMGui.private.GetLineUniqueID()
	local activeInstance: IMGuiInstance? = IMGui.private.ProcessedInstance
	if not activeInstance then
		error("Tried to get line unique id but instance is not running!")
	end

	local i: number = 4
	local ID: { number } = {}
	local levelInfo: number = debug.info(i, "l")

	while levelInfo ~= -1 and levelInfo ~= nil do
		table.insert(ID, levelInfo)
		i += 1
		levelInfo = debug.info(i, "l")
	end

	local idString: string = table.concat(ID)

	if not activeInstance.FrameData.WidgetIDs[idString] then
		activeInstance.FrameData.WidgetIDs[idString] = 1
	else
		activeInstance.FrameData.WidgetIDs[idString] += 1
	end

	return idString .. `/` .. activeInstance.FrameData.WidgetIDs[idString]
end

function IMGui.private.GetStackParent(): GuiObject?
	if not IMGui.private.ProcessedInstance then
		error("Tried to get stack parent but no instance is active")
	end

	local stackSize: number = #IMGui.private.ProcessedInstance.FrameData.Stack

	if stackSize == 0 then
		return IMGui.private.ProcessedInstance.Parent
	else
		return IMGui.private.ProcessedInstance.FrameData.Stack[stackSize].TopInstance
	end
end

function IMGui.private.ProcessFrame()
	for _, imGuiInstance: IMGuiInstance in IMGui.private.Instances do
		IMGui.private.ProcessedInstance = imGuiInstance

		imGuiInstance.Tick += 1

		imGuiInstance.FrameData.CurrentWidget = nil
		imGuiInstance.FrameData.PreviousWidget = nil
		imGuiInstance.FrameData.WidgetIndex = 0
		imGuiInstance.FrameData.Stack = {}
		imGuiInstance.FrameData.WidgetIDs = {}

		IMGui.public:BeginVertical()
		imGuiInstance.TickLoop()
		IMGui.public:End()

		for _, widget in imGuiInstance.Widgets do
			if widget.LastUpdateTick < imGuiInstance.Tick then
				IMGui.private.DestroyWidget(widget)

				imGuiInstance.Widgets[widget.ID] = nil
			end
		end
	end

	IMGui.private.ProcessedInstance = nil
end

function IMGui.private.DestroyIMGuiInstance(imGuiInstance: IMGuiInstance)
	table.remove(IMGui.private.Instances, table.find(IMGui.private.Instances, imGuiInstance))

	for _, widget in imGuiInstance.Widgets do
		IMGui.private.DestroyWidget(widget)
	end

	imGuiInstance.Widgets = nil
end

function IMGui.private.DestroyWidget(widgetInstance: WidgetInstance)
	local widgetDefinition: WidgetDefinition = IMGui.private.WidgetDefinitions[widgetInstance.Definition]

	if widgetDefinition.Deconstruct then
		widgetDefinition.Deconstruct(widgetInstance)
	end

	widgetInstance.TopInstance:Destroy()

	if widgetInstance.ChildrenInstance then
		widgetInstance.ChildrenInstance:Destroy()
	end
end

function IMGui.private.CreateWidgetFromDefinition(identifier: string, ...)
	local activeInstance: IMGuiInstance? = IMGui.private.ProcessedInstance
	if not activeInstance then
		error("Tried to create widget but no instance is active")
	end

	activeInstance.FrameData.WidgetIndex += 1

	local widgetDefinition: WidgetDefinition = IMGui.private.WidgetDefinitions[identifier]
	local uniqueID: string = IMGui.private.GetLineUniqueID()

	local widgetInstance: WidgetInstance? = activeInstance.Widgets[uniqueID]
	if not widgetInstance then
		local stackParent = IMGui.private.GetStackParent()
		if not stackParent then
			error("No stack parent")
		end

		local widgetWarmup = {
			ID = uniqueID,

			Definition = identifier,

			LastUpdateTick = activeInstance.Tick,

			Args = { ... },
		}

		local topInstance: GuiObject, childrenInstance: GuiObject? =
			widgetDefinition.Construct(widgetWarmup, stackParent, ...)
		widgetWarmup.TopInstance = topInstance

		if childrenInstance then
			widgetWarmup.ChildrenInstance = childrenInstance
		end

		if widgetDefinition.Events then
			for eventName, eventDefinition in widgetDefinition.Events do
				if eventDefinition["Setup"] then
					eventDefinition["Setup"](widgetWarmup)
				end

				widgetWarmup[eventName] = function()
					return eventDefinition["Evaluate"](widgetWarmup)
				end
			end
		end

		widgetInstance = widgetWarmup

		activeInstance.Widgets[uniqueID] = widgetInstance
	else
		local currArgs = { ... }

		for i, value in widgetInstance.Args do
			if not areValuesEqual(currArgs[i], value) then
				widgetInstance.Args = currArgs
				widgetDefinition.Update(widgetInstance, ...)
				break
			end
		end
	end

	if widgetInstance and widgetInstance.ChildrenInstance then
		table.insert(activeInstance.FrameData.Stack, widgetInstance)
	end

	if IMGui.private.ProcessedInstance and widgetInstance then
		widgetInstance.LastUpdateTick = IMGui.private.ProcessedInstance.Tick

		if widgetInstance.TopInstance:IsA("GuiObject") then
			widgetInstance.TopInstance.LayoutOrder = activeInstance.FrameData.WidgetIndex
		end
	end

	return widgetInstance
end

function IMGui.public.End(_)
	local activeInstance: IMGuiInstance? = IMGui.private.ProcessedInstance
	if not activeInstance then
		error("No active instance")
	end

	local stackSize: number = #activeInstance.FrameData.Stack
	if stackSize <= 1 then
		return
	end

	table.remove(activeInstance.FrameData.Stack, stackSize)
end

function IMGui.public.Connect(_, parent: GuiBase, tickLoop: () -> nil)
	local newIMGuiInstance: IMGuiInstance = {
		Parent = parent,

		Tick = 0,

		FrameData = {
			Stack = {},
			WidgetIDs = {},
			WidgetIndex = 0,
		},

		Widgets = {},

		TickLoop = tickLoop,
	}

	table.insert(IMGui.private.Instances, newIMGuiInstance)

	return function()
		IMGui.private.DestroyIMGuiInstance(newIMGuiInstance)
	end
end

function IMGui.public.NewWidgetDefinition(_, identifier: string, definition: WidgetDefinition)
	if IMGui.public[identifier] then
		error("Couldn't use identifier as already something else is using it")
	end

	IMGui.private.WidgetDefinitions[identifier] = definition

	IMGui.public[identifier] = function(_, ...)
		return IMGui.private.CreateWidgetFromDefinition(identifier, ...) :: WidgetInstance
	end
end

function IMGui.public.GetTick()
	return IMGui.private.ProcessedInstance and IMGui.private.ProcessedInstance.Tick or 0
end

function IMGui.public.GetConfig(_): typeof(IMGui.private.CurrentConfig)
	return IMGui.private.CurrentConfig
end

function IMGui.public.applyFrameStyle(instance: Frame | TextButton)
	local config = IMGui.private.CurrentConfig

	if config.Sizes.FramePadding.X > 0 or config.Sizes.FramePadding.Y > 0 then
		local uiPadding: UIPadding = Instance.new("UIPadding")
		uiPadding.PaddingLeft = UDim.new(0.00, config.Sizes.FramePadding.X)
		uiPadding.PaddingRight = UDim.new(0.00, config.Sizes.FramePadding.X)
		uiPadding.PaddingTop = UDim.new(0.00, config.Sizes.FramePadding.Y)
		uiPadding.PaddingBottom = UDim.new(0.00, config.Sizes.FramePadding.Y)
		uiPadding.Parent = instance
	end

	if config.Sizes.FrameCornerRadius > 0 then
		local uiCorner: UICorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, config.Sizes.FrameCornerRadius)
		uiCorner.Parent = instance
	end
end

function IMGui.public.applyTextStyle(instance: TextLabel | TextButton)
	instance.FontFace = IMGui.private.CurrentConfig.Font

	instance.TextSize = IMGui.private.CurrentConfig.Sizes.TextSize

	instance.TextColor3 = IMGui.private.CurrentConfig.Colors.Text

	instance.AutoLocalize = false
end

export type IMGui = typeof(IMGui.public)

RunService.Heartbeat:Connect(IMGui.private.ProcessFrame)

return IMGui.public
