# AntiCheat
The Roblox AntiCheat tool is designed to allow developers to implement a quick, standard anticheat into experiences.

## Research & Development
- https://dubitlimited.atlassian.net/wiki/spaces/PROD/pages/4692934695/Roblox+AntiCheat+Tool

## Project Documentation
- https://docs-q7w3flktnq-uc.a.run.app/api/AntiCheat

## Examples
### Basic Setup
```lua
local AntiCheat = require(ReplicatedStorage.Packages.Anticheat)

-- Listen for cheaters
AntiCheat.CheaterFound:Connect(function(player)
    print(`{player.Name} was detected as a cheater!`)
end)

-- Listen for violations
AntiCheat.ViolationTriggered:Connect(function(player, node, message)
    print(`{player.Name} violated {node}: {message}`)
end)
```

### Node Management
```lua
-- Disable specific nodes
AntiCheat:DisableNode(AntiCheat.Nodes.AntiFly)
AntiCheat:DisableNode("AntiFly")

-- Enable specific nodes
AntiCheat:EnableNode(AntiCheat.Nodes.AntiFly)

-- Configure node flags
AntiCheat:SetFlag(AntiCheat.Nodes.AntiFly.RaycastDistance, 1.5)
```

### Player Management
```lua
-- Whitelist players
AntiCheat:AddToWhitelist(player)
AntiCheat:RemoveFromWhitelist(player)

-- Check player status
local isCheater = AntiCheat:IsFlaggedAsCheater(player)

-- Query player violations
local violations = AntiCheat:QueryViolations(player)
local scores = AntiCheat:QueryScores(player)
```

### Debug Mode
```lua
-- Enable verbose logging
AntiCheat:SetVerbose(true)
```
