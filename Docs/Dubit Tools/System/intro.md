# Getting Started with System

The System package provides a structured way to manage in-game systems, both on the client and server. It supports lifecycle methods like "Init" and "Start", and allows for priority-based loading of systems.

## Adding System to a Project

To add the `System` package to your project, add the following to your `wally.toml` file:

```toml
[dependencies]
System = "dubit/system@0.0.1" -- Replace with the actual version
```

## Principles
The System package is built upon the following principles:

- **Lifecycle Management**: Provides Init and Start lifecycle methods for systems.
Priority-Based Loading: Allows systems to be loaded in a specific order based on their priority.
- **Client-Server Support**: Works on both client and server environments.
- **Error Handling**: Catches and reports errors during system initialization.

## Usage
To use the System package, you'll typically follow these steps:

1. **Add Systems Folder**: Use the System:AddSystemsFolder() method to add a folder containing your system modules.
2. **Implement System Modules**: Create modules within the added folder, each representing a system. These modules should have Init and Start functions (optional).
3. **Set System Priority**: Assign a Priority value to each system module to control the loading order.
4. **Start the System**: Call the System:Start() method to initialize and start all added systems.

Here's a basic example of a system module:

```lua
-- ExampleSystem.lua
local ExampleSystem = {}

ExampleSystem.Name = "Example System"
ExampleSystem.Priority = 10

function ExampleSystem:Init()
    print("Example System Initializing")
end

function ExampleSystem:Start()
    print("Example System Started")
end

return ExampleSystem
```

And here's how you would add and start systems:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local System = require(ReplicatedStorage.Packages.System)

-- Assuming your systems are in ReplicatedStorage.Systems
local systemsFolder = ReplicatedStorage:WaitForChild("Systems")
System:AddSystemsFolder(systemsFolder)

local errors = System:Start()

if errors then
    for methodName, errorGroup in errors do
        for _, errorData in errorGroup do
            print(string.format("System %s failed to %s: %s", errorData.system.Name, methodName, errorData.response))
        end
    end
end
```

## Examples

Adding a Systems Folder

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local System = require(ReplicatedStorage.Packages.System)

local systemsFolder = ReplicatedStorage:WaitForChild("Systems")
System:AddSystemsFolder(systemsFolder)
```

System with Icon and Priority
```lua
local MyAwesomeSystem = {}

MyAwesomeSystem.Name = "My Awesome System"
MyAwesomeSystem.Icon = "⚙️"
MyAwesomeSystem.Priority = 5

function MyAwesomeSystem:Init()
    print("MyAwesomeSystem is initializing!")
end

function MyAwesomeSystem:Start()
    print("MyAwesomeSystem has started!")
end

return MyAwesomeSystem
```