# Actions

## Introduction

The concept of "Actions" aims to replace traditional chat commands with a more user-friendly and efficient alternative. An action can have optional arguments, there are two types of actions; Serverside and Clientside both marked within the Debug Tools interface under `Actions` tab, the only difference between both of these is in which environment the execution happens.

## Defining an Action

There are two ways of defining an action, one to define the logic on the server side and inject it to the client and the second one is to figure out of the DebugTools module is present and try to register the action refering to that module.

### Defining logic on the serverside
For each injected script, it's important to wrap it within a function. This function should take DebugTools as its first parameter. This way, you won't have to go hunting for a reference on your own when the script is injected into the client.

Example:
```lua
return function(DebugTools)
	DebugTools.Action.new("Show Popup", "Show some popup", function()
		-- ... logic for triggering the popup
	end)
end
```

### Defining logic on the client side
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

## Gotchas

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