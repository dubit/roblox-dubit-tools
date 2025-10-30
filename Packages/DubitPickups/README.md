# Tool Name

A simple to use Pickup System that we can deploy in our games.

## Research & Development

Technical Documentation for this tool has been written on Confluence; 

https://dubitlimited.atlassian.net/wiki/spaces/PROD/pages/3878715445/Roblox+Pickup+System

## Technical Information
An overview regarding the technical ability of for the DubitPickups module residing under RDT *(Roblox-Dubit-Tools)*

### Project Tooling

There are several tools you'll need to build & get the package working, they are as follows;

- Aftman: https://github.com/LPGhatguy/aftman

Through aftman, you'll need to install:

- Wally: https://github.com/UpliftGames/wally
- Rojo: https://github.com/rojo-rbx/rojo
- Selene: https://github.com/Kampfkarren/selene

### development.project.json

This is the 'Development' build of DubitPickups, in the Development build you'll find we include the `/Tests` folder.

With the addition of this directory, we will have the ability to test the Pickup system.

### default.project.json

This is the 'Production' build of DubitPickups, the Default build excludes the `/Tests` folder as it aims to only compile a binary that we can drag & drop into a Roblox place.

When being pulled in through another project, *Wally* is set up to also exclude these files, only bundling in the files required to build the project.


### project unit tests

This package does not support TestEz.

## Programming Examples

Defer to the documentation page.