# Widgets

## Introduction

![image](/debug_tools/widgets.png)

Widgets are on screen elements that can be any size and anywhere on the screen as well as hidden completely. The primary purpose of widgets is to swiftly convey information without requiring the opening of a separate interface and their sole function is to display non-interactive data.

**Widgets shouldn't disrupt or interfere with gameplay elements.**

## Repositioning widgets

- Press F6 to open the Widgets tab.
- Locate your desired widget within the square representing your screen.
- Click and hold the left mouse button on the widget.
- Drag the widget within the square area that represents your screen.
- Release the left mouse button to set the widget's new position.


## Enabling or disabling widgets

- Open the Widgets tab by pressing F6.
- In the Widgets tab, you'll find a list of available widgets on the right side.
- To enable a widget, locate it in the list. A green entry signifies that the widget is already enabled.
- To disable a widget, find it in the list. A red entry indicates that the widget is currently disabled.

## Defining a new widget

Every widget has a constructor function that needs to return a destructor function, the constructor function gets executed whenever the widget gets shown whereas the destructor is executed whenever the widget gets hidden. Here is an example implementation of a Widget:

```lua
DebugTools.Widget.new("Cool Widget", function(parent: ScreenGui) -- this is a constructor function
	local widgetFrame: Frame = Instance.new("Frame")
	widgetFrame.Parent = widgetFrame

	-- ... some widget logic

	return function() -- this is a destructor function
		widgetFrame:Destroy()
	end
end)
```