# Getting Started

Dubit Chassis is a robust automobile physics system that utilizes raycasting to simulate realistic vehicle suspension. It provides a performant and realistic vehicle suspension that is easy to use for developers and designers.

## Adding Dubit Chassis to a Project

To add the `DubitChassis` package to your project, add the following to your `wally.toml` file:

```toml
[dependencies]
DubitChassis = "dubit/dubit-chassis@0.1.0" -- Replace with the actual version
```

## Principles

Dubit Chassis is built upon the following principles:

*   **Raycast Suspension:** Uses raycasting to simulate realistic suspension, offering performance and accurate collision detection.
*   **Attribute-Based Design:** Allows dynamic configuration of chassis constants in real-time without code modifications.
*   **Component Inheritance:** Enables the creation of new component classes that inherit lifecycle methods and prototype functions.
*   **Network Ownership:** Distributes physics computations between clients and server for reduced latency and optimized performance.

For more information on the physics and principles behind this chassis, please refer to the confluence page:
https://dubitlimited.atlassian.net/wiki/spaces/PROD/pages/3878584362/Roblox+Vehicle+Physics+System

## Usage

To use Dubit Chassis, you'll typically interact with its components and interface functions. Here's a basic example of how to create a chassis component on both the client-side and server-side:

#### Client Component

```lua

--Source/Client/Components/ClientChassis.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

-- Create a new chassis component
local ClientChassis = DubitChassis.Component.new({
    Tag = "Chassis"
})

-- Initialize the server-side physics step (Server-side)
DubitChassis:StartPhysicsStep()

function ClientChassis:Construct()
   -- Dev code
end

function ClientChassis:Start()
   -- Listens to event to call StartDrivingVehicle() method
    self._trove:Add(self.VehicleSeat.ProximityPrompt.Triggered:Connect(function(player: Player)
        self:StartDrivingVehicle(player.Character)
    end))
end

function ClientChassis:Stop()
   -- Dev code
end

-- Lifecycle method invoked when the VehicleSeat Occupant is changed 
function ClientChassis:OnVehicleSeatOccupantChanged()
   -- We switch the NetworkOwnership of this component everytime the occupant is changed
    self:SetNetworkOwnership(self.VehicleSeat.Occupant)
end

return ClientChassis
```

#### Server Component

```lua

--Source/Server/Components/ClientChassis.lua

local RunService = game:GetService("RunService")
local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

local ServerChassis = DubitChassis.Component.new({
    Tag = "Chassis"
})

DubitChassis:StartPhysicsStep()

function ServerChassis:Construct()
   -- Dev code
end
function ServerChassis:Start()
    -- Dev code
end
function ServerChassis:Stop()
    -- Dev code
end

-- Lifecycle method invoked when the Local Player enters the chassis
function ServerChassis:OnLocalPlayerSeated()
    self.RaycastConnection = RunService.RenderStepped:Connect(function(deltaTime)
        self:StepPhysics(deltaTime)
    end)
end
-- Lifecycle method invoked when the Local Player exits the chassis
function ServerChassis:OnLocalPlayerExited()
   self.RaycastConnection:Disconnect()
end

-- Lifecycle method invoked when instance is streamed in
function ServerChassis:StreamedIn()
    -- Dev code
end

-- Lifecycle method invoked when instance is streamed out
function ServerChassis:StreamedOut()
    -- Dev code
end
return ServerChassis
```

## Examples

### Setting Global Chassis Attributes (Server-Side)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

-- Example of setting global chassis attributes
DubitChassis:SetGlobalChassisAttributes({ MaxSpeed = 250 })
```

### Getting a Player-Owned Vehicle (Server-Side)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)
local Players = game:GetService("Players")

-- Example of checking if a player owns a vehicle
local function playerOwnsVehicle(player: Player): boolean
    if DubitChassis:GetPlayerOwnedChassis(player) then
       return true
    end
    return false
end
```