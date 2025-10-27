--!strict
local Players = game:GetService("Players")

local DebugToolRootPath = script.Parent.Parent
local SharedRootPath = DebugToolRootPath.Shared

local Signal = require(SharedRootPath.Signal)
local Constants = require(SharedRootPath.Constants)

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

local DebugWidget = {}
DebugWidget.internal = {
	WidgetData = {} :: { [string]: WidgetData },
}
DebugWidget.interface = {
	WidgetAdded = Signal.new(),

	WidgetMounted = Signal.new(),
	WidgetUnmounted = Signal.new(),
}

function DebugWidget.internal.createWidgetScreenGui(widget: Widget): ScreenGui?
	local widgetData: WidgetData = DebugWidget.internal.WidgetData[widget.Name]
	if not widgetData then
		return nil
	end

	if widgetData.ScreenGui then
		return widgetData.ScreenGui
	end

	local widgetScreenGui: ScreenGui = Instance.new("ScreenGui")
	widgetScreenGui.Name = `[DEBUG] {widget.Name}`
	widgetScreenGui.DisplayOrder = Constants.WIDGET_DISPLAY_ORDER
	widgetScreenGui.IgnoreGuiInset = true
	widgetScreenGui.ResetOnSpawn = false
	widgetScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	widgetScreenGui.Parent = Players.LocalPlayer.PlayerGui

	widgetData.ScreenGui = widgetScreenGui

	return widgetScreenGui
end

function DebugWidget.internal.addWidget(widget: Widget)
	local widgetData: WidgetData = {
		Widget = widget,

		Mounted = false,
	}
	DebugWidget.internal.WidgetData[widget.Name] = widgetData

	DebugWidget.interface.WidgetAdded:Fire(widget.Name)

	DebugWidget.internal.mountWidget(widget)
end

function DebugWidget.internal.removeWidget(widgetName: string)
	local widgetData: WidgetData = DebugWidget.internal.WidgetData[widgetName]

	if not widgetData then
		return
	end

	if widgetData.ScreenGui then
		widgetData.ScreenGui:Destroy()
		widgetData.ScreenGui = nil
	end

	DebugWidget.internal.WidgetData[widgetName] = nil
end

function DebugWidget.internal.mountWidget(widget: Widget)
	local widgetParent: ScreenGui? = DebugWidget.internal.createWidgetScreenGui(widget)
	assert(widgetParent, `Widget parent doesn't exist for '{widget.Name}'`)

	local widgetData: WidgetData = DebugWidget.internal.WidgetData[widget.Name]

	widgetData.DestroyFunction = widget.CreateFunction(widgetParent)

	if typeof(widgetData.DestroyFunction) ~= "function" then
		DebugWidget.internal.removeWidget(widget.Name)

		warn(
			`Widget '{widget.Name}' needs to return a destructor of a type 'function' got '{typeof(
				widgetData.DestroyFunction
			)}'`
		)
		return
	end

	if #widgetParent:GetChildren() == 0 then
		DebugWidget.internal.removeWidget(widget.Name)

		warn(`Widget '{widget.Name}' didn't create any interface elements.`)
		return
	end

	widgetData.Mounted = true

	DebugWidget.interface.WidgetMounted:Fire(widget.Name, widgetParent)
end

function DebugWidget.internal.unmountWidget(widget: Widget)
	local widgetData: WidgetData = DebugWidget.internal.WidgetData[widget.Name]
	if not widgetData or not widgetData.Mounted then
		return
	end

	if widgetData.DestroyFunction then
		widgetData.DestroyFunction()
	end

	if widgetData.ScreenGui then
		local screenGuiChildren: { Instance } = widgetData.ScreenGui:GetChildren()

		if #screenGuiChildren > 0 then
			warn(`Widget '{widget.Name}' didn't cleanup unmounted interface properly, there are leftover elements:`)

			for _, childInstance: Instance in screenGuiChildren do
				warn(`  ╠ {childInstance.Name}({childInstance.ClassName})`)
			end
		end

		widgetData.ScreenGui:Destroy()
		widgetData.ScreenGui = nil
	end

	widgetData.Mounted = false

	DebugWidget.interface.WidgetUnmounted:Fire(widget.Name)
end

function DebugWidget.internal.getWidgetData(widgetName: string): WidgetData?
	return DebugWidget.internal.WidgetData[widgetName]
end

function DebugWidget.interface.new(widgetName: string, widgetCreateFunction: (parent: ScreenGui) -> () -> nil)
	assert(type(widgetName) == "string", `Expected parameter #1 'widgetName' to be a string, got {type(widgetName)}`)
	assert(
		type(widgetCreateFunction) == "function",
		`Expected parameter #2 'widgetCreateFunction' to be a function, got {type(widgetCreateFunction)}`
	)

	local widget: Widget = {
		Name = widgetName,

		CreateFunction = widgetCreateFunction,
	}

	DebugWidget.internal.addWidget(widget)
end

function DebugWidget.interface:GetAll()
	local widgets: { [string]: {
		Mounted: boolean,
		ScreenGui: ScreenGui?,
	} } = {}

	for widgetName: string, widgetData: WidgetData in DebugWidget.internal.WidgetData do
		widgets[widgetName] = {
			Mounted = widgetData.Mounted,
			ScreenGui = widgetData.ScreenGui,
		}
	end

	return widgets
end

function DebugWidget.interface:Hide(widgetName: string)
	local widgetData: WidgetData? = DebugWidget.internal.getWidgetData(widgetName)
	if not widgetData or not widgetData.Mounted then
		return
	end

	DebugWidget.internal.unmountWidget(widgetData.Widget)
end

function DebugWidget.interface:Show(widgetName: string)
	local widgetData: WidgetData? = DebugWidget.internal.getWidgetData(widgetName)
	if not widgetData or widgetData.Mounted then
		return
	end

	DebugWidget.internal.mountWidget(widgetData.Widget)
end

function DebugWidget.interface:IsVisible(widgetName: string)
	local widgetData: WidgetData? = DebugWidget.internal.getWidgetData(widgetName)

	return widgetData and widgetData.Mounted or false
end

function DebugWidget.interface:SwitchVisibility(widgetName: string)
	if DebugWidget.interface:IsVisible(widgetName) then
		DebugWidget.interface:Hide(widgetName)
	else
		DebugWidget.interface:Show(widgetName)
	end
end

return DebugWidget.interface
