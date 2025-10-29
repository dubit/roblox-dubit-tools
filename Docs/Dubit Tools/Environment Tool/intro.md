# Getting Started

The EnvironmentTool package allows you to determine the current environment your Roblox game is running in. This is useful for configuring different settings or behaviors for different environments such as development, testing, and production.

## Adding EnvironmentTool to a Project

To add the `EnvironmentTool` package to your project, add the following to your `wally.toml` file:

```lua
[dependencies]
EnvironmentTool = "dubit/environment-tool@~0.1"
```

## Usage

The EnvironmentTool package provides several methods to check the current environment:

- ```EnvironmentTool:IsProduction()```: Returns true if the current environment is production.
- ```EnvironmentTool:IsStable()```: Returns true if the current environment is stable.
- ```EnvironmentTool:IsEdge()```: Returns true if the current environment is edge.
- ```EnvironmentTool:IsLocal()```: Returns true if the current environment is local.
- ```EnvironmentTool:GetEnvironment()```: Returns an environment string which can be "Edge", "Stable", "Production" or "Local".

### Examples

Here's an example of how to use the EnvironmentTool package:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnvironmentTool = require(ReplicatedStorage.Packages.EnvironmentTool)

if EnvironmentTool:IsProduction() then
    print("Running in production environment")
elseif EnvironmentTool:IsStable() then
    print("Running in stable environment")
elseif EnvironmentTool:IsEdge() then
    print("Running in edge environment")
else
    print("Running in local environment")
end

local environment = EnvironmentTool:GetEnvironment()
print("Current environment: " .. environment)
```

## Setting the Branch Attribute

In order for this tool to work correctly in non-local environments, the Branch attribute of the Workspace must be set during your pipeline deployment. This can be achieved using a Lune deploy script containing the following:

```lua
print(`[Deploy-To]: Set workspace attribute 'Branch' to: '{process.env.BITBUCKET_BRANCH}'`)
game.Workspace:SetAttribute("Branch", process.env.BITBUCKET_BRANCH)
```

This ensures that the correct branch name is associated with your Roblox place when it's deployed.