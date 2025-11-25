# Overview

DubitUtils is a collection of utility functions and modules designed to simplify common tasks in Roblox development. It provides a range of tools for various purposes, such as camera manipulation, character management, data buffering, and more.

## Adding DubitUtils to a Project

To add the `DubitUtils` package to your project, add the following to your `wally.toml` file:

```toml
[dependencies]
DubitUtils = "dubit/dubit-utils@0.x" -- Replace with the actual version
```

# Principles
DubitUtils is built upon the following principles:

- **Modularity**: Provides a set of independent modules that can be used individually.
- **Reusability**: Offers functions and modules that can be easily reused across different projects.
- **Efficiency**: Aims to provide optimized and performant utility functions.
- **Simplicity**: Focuses on providing simple and easy-to-use tools.

## Usage
To use DubitUtils, you can require the main module and then access its sub-modules or functions. Here's a basic example:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DubitUtils = require(ReplicatedStorage.Packages.DubitUtils)

-- Example usage of a sub-module (e.g., Camera)
local CameraUtils = DubitUtils.Camera

-- Example usage of a function from the Camera module
local currentCamera = workspace.CurrentCamera
local cameraPosition = CameraUtils.zoomToExtents(currentCamera, workspace.Model)
print("Camera Position:", cameraPosition)
```

## Examples

Character Utilities

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DubitUtils = require(ReplicatedStorage.Packages.DubitUtils)

-- Sets the local player's character to frozen
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

DubitUtils.Character.setCharacterFrozen(Players.LocalPlayer.Character, true)
```

Buffer Reader/Writer

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DubitUtils = require(ReplicatedStorage.Packages.DubitUtils)

local BufferWriter = DubitUtils.BufferWriter
local BufferReader = DubitUtils.BufferReader

-- Create a new buffer writer
local writer = BufferWriter.new()

-- Write some data to the buffer
writer.Writei16(123)
writer.WriteString("Hello, World!")

-- Get the buffer as a string
local buffer = writer:GetBuffer()

-- Create a new buffer reader
local reader = BufferReader.new(buffer)

-- Read the data from the buffer
local intValue = reader.Readi16()
local stringValue = reader.ReadString()

print("Int Value:", intValue)
print("String Value:", stringValue)
```