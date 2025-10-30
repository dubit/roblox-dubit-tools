# Dubit Store
The ‘Roblox Data Handler’ is a third-party LuaU module designed to be pulled into any Project.

## Research & Development
The following document describes the objective for this module, as well as serveral technical aspects about what this module is supposed to offer developers.

https://dubitlimited.atlassian.net/wiki/spaces/~6239bb6ab75ca8007055b382/pages/3879239740/Roblox+Data+Handler

## Technical Information
An overview regarding the technical ability of for the DubitStore module residing under RDT *(Roblox-Dubit-Tools)*

### Project Tooling
There are several tools you'll need to build & get the DubitStore working, they are as follows;

- Aftman: https://github.com/LPGhatguy/aftman

Through aftman, you'll need to install:

- Wally: https://github.com/UpliftGames/wally
- Rojo: https://github.com/rojo-rbx/rojo
- Selene: https://github.com/Kampfkarren/selene

Additionally - this project favours the Visual Studio Code IDE for it's build tasks:

### development.project.json
This is the 'Development' build of DubitStore, in the Development build you'll find we include both the `/DevPackages` and `/Tests` folder.

With the addition of these two directories, we will have the ability to run the Unit tests written for DubitStore. 

### default.project.json
This is the 'Production' build of DubitStore, the Default build excludes both `/DevPackages` and `/Tests` as it aims to only compile a binary that we can drag & drop into a Roblox place.

When being pulled in through another project, *Wally* is set up to also exclude these files, only bundling in the files required to build the project.

### project packages
The DubitStore at the moment only contains three packages;

- Promise: https://github.com/evaera/roblox-lua-promise
- Sift: https://github.com/csqrl/sift
- Signal: https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal

The DubitStore development branch however contains an additional package;

- TestEz: https://github.com/Roblox/testez

### project unit tests
Unit tests under the DubitStore are handled through the TestEz testing framework, this Testing framework will run through the destinations given to find specific test files to execute.

The DubitStore uses `*.spec.lua` files to denotate it's unit test files, files which use the spec format should ONLY be for testing.

Additionally, it's common that each component in DubitStore has it's own retrospective unit tests, this is done to ensure that the internal components are functioning as well as the methods exposed through this module.

## Programming Examples
There are more in-depth examples you can take a look at inside of the `/Examples` directory, however to overview - the below is an example of how we could take advantage of Dubit Store.

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local DubitStore = require(ServerScriptService.Packages.DubitStore)

local DataStoreName = "DataStore"
local Key = "Key"

local DataSchemaName = "DataSchema"

DubitStore:CreateDataSchema(DataSchemaName, {
	["SchemaKey"] = DubitStore.Container.new("SchemaValue")
})

DubitStore:GetDataAsync(DataStoreName, Key):andThen(function(data)
	data = DubitStore:ReconcileData(data, DataSchemaName)

	print(`Latest Schema Key: {data.SchemaKey}`)
end)
```

## To-do's

- MoonWave Documentation
- String Compression Algorithm
- Support for MemoryStore
- Serialise all Roblox DataTypes
- Budget Request Handling
- API for rolling back player data
- API for interacting with metadata