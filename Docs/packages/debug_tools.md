# Overview

## Adding Debug Tools to a Project

To add `Debug Tools` package to your project add the following into your `wally.toml` file.

!!! notice
	The package doesn't need to be required within another script to be initialized, the package does it by itself.

```lua
[dependencies]
DebugTools = "dubit/debug-tools@~0.2"
```

!!! warning
	DebugTools package may not work as expected if required from within an Actor

	This is because the module self-initialises from a default non-actor context

## Actions

### Introduction

The concept of "Actions" aims to replace traditional chat commands with a more user-friendly and efficient alternative. An action can have optional arguments, there are two types of actions; Serverside and Clientside both marked within the Debug Tools interface under `Actions` tab, the only difference between both of these is in which environment the execution happens.

### Defining an Action

There are two ways of defining an action, one to define the logic on the server side and inject it to the client and the second one is to figure out of the DebugTools module is present and try to register the action refering to that module.

#### Defining logic on the serverside
For each injected script, it's important to wrap it within a function. This function should take DebugTools as its first parameter. This way, you won't have to go hunting for a reference on your own when the script is injected into the client.

Example:
```lua
return function(DebugTools)
	DebugTools.Action.new("Show Popup", "Show some popup", function()
		-- ... logic for triggering the popup
	end)
end
```

#### Defining logic on the client side
It's not guaranteed that DebugTools ModuleScript will be available when player joins the game, so a check needs to be written for it. The only players that have access to DebugTools and get the DebugTools injected into their `PlayerGui` are people that have rank higher or equal the set authorised rank under the set Roblox group (both defined in `Constants.lua`).

Example:
```lua
local Players = game:GetService("Players")

local DebugTools = Players.LocalPlayer.PlayerGui:WaitForChild("DebugTools", 5)
if DebugTools then
	DebugTools = require(DebugTools)

	DebugTools.Action.new("Show Popup", "Show some popup", function()
		-- ... logic for triggering the popup
	end)
end
```

#### Gotchas

An action can also have arguments, all of the arguments **need to** have a type specified, while the rest `Name`, `Default` are optional.

Example:

```lua
DebugTools.Action.new("Trigger Race", nil, function(track: string, laps: number, spawnCar: boolean)
	-- ... logic for triggering the race
end, {
	{
		Type = "string",
		Name = "track",
		Default = "Quick Track",
	},
	{
		Type = "number",
		Name = "laps",
		Default = 4,
	},
	{
		Type = "boolean",
		Name = "spawn car",
	}
})
```

```lua
DebugTools.Action.new("Set Money", "Sets player money to a given amount", function(player: Player, amount: number)
	-- ... logic for setting the money
end, {
	{
		Type = "Player",
		Name = "player",
	},
	{
		Type = "number",
		Name = "amount",
		Default = 1000
	}
})
```

## Tabs

### Introduction

![image](../img/tabs.png)

Tabs are sections within the interface of Debug Tools, while Widgets primarily serve the purpose of data presentation, Tabs are specifically designed to facilitate interaction. The interface features a selection of predefined tabs, each serving distinct functions but developers can also add their own tabs if they want to.

### Defining a Tab

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

## Widgets

### Introduction

![image](../img/widgets.png)

Widgets are on screen elements that can be any size and anywhere on the screen as well as hidden completely. The primary purpose of widgets is to swiftly convey information without requiring the opening of a separate interface and their sole function is to display non-interactive data.

**Widgets shouldn't disrupt or interfere with gameplay elements.**

### Repositioning widgets

- Press F6 to open the Widgets tab.
- Locate your desired widget within the square representing your screen.
- Click and hold the left mouse button on the widget.
- Drag the widget within the square area that represents your screen.
- Release the left mouse button to set the widget's new position.


### Enabling or disabling widgets

- Open the Widgets tab by pressing F6.
- In the Widgets tab, you'll find a list of available widgets on the right side.
- To enable a widget, locate it in the list. A green entry signifies that the widget is already enabled.
- To disable a widget, find it in the list. A red entry indicates that the widget is currently disabled.

### Defining a new widget

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