local DebugToolRootPath = script.Parent.Parent
local SharedRootPath = DebugToolRootPath.Shared

local Signal = require(SharedRootPath.Signal)

local Interface = require(script.Parent.Interface)

type WidgetData = {
	Widget: Widget,

	Mounted: boolean,

	ScreenGui: ScreenGui?,

	DestroyFunction: (() -> nil)?,
}

type Widget = {
	Name: string,

	CreateFunction: (parent: ScreenGui) -> () -> nil,
}

local Widget = {}
Widget.internal = {
	WidgetData = {} :: { [string]: WidgetData },
}
Widget.interface = {
	WidgetAdded = Signal.new(),

	WidgetMounted = Signal.new(),
	WidgetUnmounted = Signal.new(),
}

function Widget.internal.addWidget(widget: Widget)
	local widgetData: WidgetData = {
		Widget = widget,

		Mounted = false,
	}
	Widget.internal.WidgetData[widget.Name] = widgetData

	Widget.interface.WidgetAdded:Fire(widget.Name)

	Widget.internal.mountWidget(widget)
end

function Widget.internal.removeWidget(widgetName: string)
	local widgetData: WidgetData = Widget.internal.WidgetData[widgetName]

	if not widgetData then
		return
	end

	if widgetData.ScreenGui then
		widgetData.ScreenGui:Destroy()
		widgetData.ScreenGui = nil
	end

	Widget.internal.WidgetData[widgetName] = nil
end

function Widget.internal.mountWidget(widget: Widget)
	local widgetParent: ScreenGui? = Interface:GetDebugScreenGUI()
	assert(widgetParent, `Widget parent doesn't exist for '{widget.Name}'`)

	local widgetData: WidgetData = Widget.internal.WidgetData[widget.Name]

	widgetData.DestroyFunction = widget.CreateFunction(widgetParent)

	if typeof(widgetData.DestroyFunction) ~= "function" then
		Widget.internal.removeWidget(widget.Name)

		warn(
			`Widget '{widget.Name}' needs to return a destructor of a type 'function' got '{typeof(
				widgetData.DestroyFunction
			)}'`
		)
		return
	end

	if #widgetParent:GetChildren() == 0 then
		Widget.internal.removeWidget(widget.Name)

		warn(`Widget '{widget.Name}' didn't create any interface elements.`)
		return
	end

	widgetData.Mounted = true

	Widget.interface.WidgetMounted:Fire(widget.Name, widgetParent)
end

function Widget.internal.unmountWidget(widget: Widget)
	local widgetData: WidgetData = Widget.internal.WidgetData[widget.Name]
	if not widgetData or not widgetData.Mounted then
		return
	end

	if widgetData.DestroyFunction then
		widgetData.DestroyFunction()
	end

	widgetData.Mounted = false

	Widget.interface.WidgetUnmounted:Fire(widget.Name)
end

function Widget.internal.getWidgetData(widgetName: string): WidgetData?
	return Widget.internal.WidgetData[widgetName]
end

function Widget.interface.new(widgetName: string, widgetCreateFunction: (parent: ScreenGui) -> () -> nil)
	assert(type(widgetName) == "string", `Expected parameter #1 'widgetName' to be a string, got {type(widgetName)}`)
	assert(
		type(widgetCreateFunction) == "function",
		`Expected parameter #2 'widgetCreateFunction' to be a function, got {type(widgetCreateFunction)}`
	)

	local widget: Widget = {
		Name = widgetName,

		CreateFunction = widgetCreateFunction,
	}

	Widget.internal.addWidget(widget)
end

function Widget.interface:GetAll()
	local widgets: { [string]: {
		Mounted: boolean,
		ScreenGui: ScreenGui?,
	} } = {}

	for widgetName: string, widgetData: WidgetData in Widget.internal.WidgetData do
		widgets[widgetName] = {
			Mounted = widgetData.Mounted,
			ScreenGui = widgetData.ScreenGui,
		}
	end

	return widgets
end

function Widget.interface:Hide(widgetName: string)
	local widgetData: WidgetData? = Widget.internal.getWidgetData(widgetName)
	if not widgetData or not widgetData.Mounted then
		return
	end

	Widget.internal.unmountWidget(widgetData.Widget)
end

function Widget.interface:Show(widgetName: string)
	local widgetData: WidgetData? = Widget.internal.getWidgetData(widgetName)
	if not widgetData or widgetData.Mounted then
		return
	end

	Widget.internal.mountWidget(widgetData.Widget)
end

function Widget.interface:IsVisible(widgetName: string)
	local widgetData: WidgetData? = Widget.internal.getWidgetData(widgetName)

	return widgetData and widgetData.Mounted or false
end

function Widget.interface:SwitchVisibility(widgetName: string)
	if Widget.interface:IsVisible(widgetName) then
		Widget.interface:Hide(widgetName)
	else
		Widget.interface:Show(widgetName)
	end
end

return Widget.interface
