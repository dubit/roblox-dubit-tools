# Tabs

## Introduction

![image](/debug_tools/tabs.png)

Tabs are sections within the interface of Debug Tools, while Widgets primarily serve the purpose of data presentation, Tabs are specifically designed to facilitate interaction. The interface features a selection of predefined tabs, each serving distinct functions but developers can also add their own tabs if they want to.

## Defining a Tab

```lua
DebugTools.Tab.new("My Tab", function(parent: Frame) -- this is a constructor function
	local widgetFrame: Frame = Instance.new("Frame")
	widgetFrame.Parent = widgetFrame

	-- ... some widget logic

	return function() -- this is a destructor function
		widgetFrame:Destroy()
	end
end)
```