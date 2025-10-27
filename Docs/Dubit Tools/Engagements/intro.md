# Getting Started with Engagements

The Engagements package is designed to help developers easily track and handle player engagements with various elements within a Roblox experience. It provides tools for tracking interactions with zones, objects, videos, and GUIs, allowing for detailed analysis of player behavior.

## Adding Engagements to a Project

To add the `Engagements` package to your project, add the following to your `wally.toml` file:

```toml
[dependencies]
Engagements = "dubit/engagements@0.x.x" -- Replace with the actual version
```

## Principles

The Engagements package is built upon the following principles:

-   **Ease of Use:** Provides a simple and straightforward API for tracking player engagements.
-   **Versatility:** Supports tracking engagements with zones, objects, videos, and GUIs.
-   **Client-Server Communication:** Uses client-server communication to accurately track and record engagements.
-   **IAB Compliance:** Adheres to IAB (Interactive Advertising Bureau) guidelines for viewability and engagement metrics.

## Usage

To use the Engagements package, you'll typically follow these steps:

1.  **Require the Module:** Require the `Engagements` module in your script.
2.  **Initialize the Package:** Call the `Engagements:Initialize()` function to set up the necessary event listeners and tracking systems.
3.  **Track Elements:** Use the `TrackZone()`, `TrackObject()`, `TrackVideo()`, and `TrackGui()` functions to start tracking engagements with specific elements in your game.
4.  **Listen for Events:** Connect functions to the `ZoneEntered`, `ZoneLeft`, `WatchedVideo`, `ViewedGui`, and `InteractedWithGui` signals to be notified when specific engagement events occur.

Here's a basic example of how to use the Engagements package:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

-- Initialize the Engagements package
Engagements:Initialize()

-- Track a zone
local zone = workspace.MyZone
Engagements:TrackZone(zone, "MyZoneIdentifier")

-- Listen for zone entered event
Engagements.ZoneEntered:Connect(function(player, identifier)
    print(player.Name .. " entered zone: " .. identifier)
end)
```

## Examples

### Tracking a Zone

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

-- Assuming you have a zone named "MyZone" in the workspace
local zone = workspace.MyZone
Engagements:TrackZone(zone, "MyZoneIdentifier")
```

### Tracking an Object

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

-- Assuming you have an object named "MyObject" in the workspace
local object = workspace.MyObject
Engagements:TrackObject(object, "MyObjectIdentifier")
```

### Tracking a Video

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

-- Assuming you have a VideoFrame named "MyVideo" in the part
local video = workspace.VideoPart.MyVideo
Engagements:TrackVideo(video, "MyVideoIdentifier")
```

### Tracking a GUI

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

-- Assuming you have a ScreenGui named "MyGui" in PlayerGui
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("MyGui")
Engagements:TrackGui(gui, "MyGuiIdentifier")
```

### Listening for a Watched Video Event

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

Engagements.WatchedVideo:Connect(function(player, identifier)
    print(player.Name .. " watched video: " .. identifier)
end)
```

### Listening for a GUI Interaction Event

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Engagements = require(ReplicatedStorage.Packages.Engagements)

Engagements.InteractedWithGui:Connect(function(player, identifier)
    print(player.Name .. " interacted with GUI: " .. identifier)
end)
```
