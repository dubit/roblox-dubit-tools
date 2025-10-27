# Weaver
Weaver is a module framework designed to slowly replace our usage of Knit, Weaver is built on the idea of upholding LuaU principles & bringing in the Game Designers so they have more input on what is really happening in-game.

## Research & Development
The following document describes the objective for this module, as well as several technical aspects about what this module is supposed to offer developers.

https://dubitlimited.atlassian.net/wiki/spaces/~6239bb6ab75ca8007055b382/pages/3900538881/Weaver

## Technical Information
An overview regarding the technical ability of for the Weaver module residing under RIT *(Roblox-Internal-Tools)*

### Project Tooling
There are several tools you'll need to build & get Weaver working, they are as follows;

- Aftman: https://github.com/LPGhatguy/aftman

Through aftman, you'll need to install:

- Wally: https://github.com/UpliftGames/wally
- Rojo: https://github.com/rojo-rbx/rojo
- Selene: https://github.com/Kampfkarren/selene

Additionally - this project favours the Visual Studio Code IDE for it's build tasks:

### development.project.json
This is the 'Development' build of Weaver, in the Development build you'll find we include both the `/DevPackages` and `/Tests` folder.

With the addition of these two directories, we will have the ability to run the Unit tests written for Weaver. 

### default.project.json
This is the 'Production' build for Weaver, the Default build excludes both `/DevPackages` and `/Tests` as it aims to only compile a binary that we can drag & drop into a Roblox place.

When being pulled in through another project, *Wally* is set up to also exclude these files, only bundling in the files required to build the project.

### project packages
The Weaver at the moment only contains three packages;

- Promise: https://github.com/evaera/roblox-lua-promise
- Sift: https://github.com/csqrl/sift
- Signal: https://github.com/Sleitnick/RbxUtil/tree/main/modules/signal

The Weaver development branch however contains an additional package;

- TestEz: https://github.com/Roblox/testez

### project unit tests
Unit tests under Weaver are handled through the TestEz testing framework, this Testing framework will run through the destinations given to find specific test files to execute.

Weaver uses `*.spec.lua` files to denotate it's unit test files, files which use the spec format should ONLY be for testing.

Additionally, it's common that each component in Weaver has it's own retrospective unit tests, this is done to ensure that the internal components are functioning as well as the methods exposed through this module.