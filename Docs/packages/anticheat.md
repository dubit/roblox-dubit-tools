# Overview

The AntiCheat package is designed to help developers implement a quick, standard anti-cheat system into their Roblox experiences. It provides tools to detect common exploits and allows developers to track and respond to instances of cheating.

## Adding AntiCheat to a Project

To add the `AntiCheat` package to your project, add the following to your `wally.toml` file:

```toml
[dependencies]
AntiCheat = "dubit/anticheat@0.x.x" -- Replace with the actual version
```

## Principles

The AntiCheat package is built upon the following principles:

-   **Ease of Use:** Provides a simple and straightforward API for implementing anti-cheat measures.
-   **Configurability:** Allows developers to enable or disable different anti-cheat components without significantly affecting the player's experience.
-   **Extensibility:** Offers a way for developers to track and respond to instances of cheating.
-   **Performance:** Designed to minimize performance impact on the game.

## Usage

To use the AntiCheat package, you'll typically follow these steps:

1.  **Require the Module:** Require the `AntiCheat` module in your script.
2.  **Listen for Cheaters:** Connect a function to the `CheaterFound` signal to be notified when a player is detected as a cheater.
3.  **Listen for Violations:** (Optional) Connect a function to the `ViolationTriggered` signal to be notified when a player triggers a rule violation.
4.  **Configure Nodes:** (Optional) Disable or enable specific anti-cheat nodes using the `DisableNode` and `EnableNode` methods.
5.  **Set Flags:** (Optional) Configure specific flags for the anti-cheat nodes using the `SetFlag` method.

Here's a basic example of how to use the AntiCheat package:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AntiCheat = require(ReplicatedStorage.Packages.AntiCheat)

-- Listen for cheaters
AntiCheat.CheaterFound:Connect(function(player)
    print(`{player.Name} was detected as a cheater!`)
end)

-- Listen for violations
AntiCheat.ViolationTriggered:Connect(function(player, node, message)
    print(`{player.Name} violated {node}: {message}`)
end)
```

## Examples

### Disabling a Node

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AntiCheat = require(ReplicatedStorage.Packages.AntiCheat)

-- Disable the AntiFly node
AntiCheat:DisableNode(AntiCheat.Nodes.AntiFly)
```

### Enabling a Node

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AntiCheat = require(ReplicatedStorage.Packages.AntiCheat)

-- Enable the AntiFly node
AntiCheat:EnableNode(AntiCheat.Nodes.AntiFly)
```

### Setting a Flag

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AntiCheat = require(ReplicatedStorage.Packages.AntiCheat)

-- Set the RaycastDistance flag for the AntiFly node
AntiCheat:SetFlag(AntiCheat.Nodes.AntiFly.RaycastDistance, 1.5)
```

### Whitelisting a Player

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AntiCheat = require(ReplicatedStorage.Packages.AntiCheat)

Players.PlayerAdded:Connect(function(player: Player)
	if player.UserId == 123456 then
		-- Add a player to the whitelist
		AntiCheat:AddToWhitelist(player)
	end
end)
```

### Checking if a Player is Flagged as a Cheater

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AntiCheat = require(ReplicatedStorage.Packages.AntiCheat)

Players.PlayerAdded:Connect(function(player: Player)
	-- Check if a player is flagged as a cheater
	local isCheater = AntiCheat:IsFlaggedAsCheater(player)

	if isCheater then
		print(`{player.Name} is flagged as a cheater!`)
	end
end)


```
