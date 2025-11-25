# roblox-dubit-tools
This roblox-dubit-tools is a mono-repository that houses a multitude of tools that can be used across all projects on the Roblox platform.

## Context

### Important links

- Documentation / API Link:
	- TODO: add link

### Developer Prerequisites

---

For developers designing tooling under RDT, you will need the following tooling set up on your machine;

- [Roblox Studio](https://www.roblox.com/create) - Studio Environment
- [Aftman](https://github.com/LPGhatguy/aftman) - Toolchain Manager
	- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Code Formatter
	- [Selene](https://github.com/Kampfkarren/selene) - Linter
	- [Rojo](https://rojo.space/) - IDE integration tool for Roblox Studio
	- [Wally](https://wally.run/) - Package Manager

### Project Build Structure

---
TODO: edit this section to list out project structure appropriately.

- `/Packages/**`
	- The `Packages` folder contains all packages developed under the RDT repository.
- `/Boilerplates/**`
	- The `Boilerplates` folder contains boilerplate RDT projects that you can clone into `/Packages` folder when creating a new tool.
- `/Docs/**.md`
	- The `Docs` folder contains a range of `*.md` files to help document tools under RDT.

### RDT Branch Structure

---
TODO: Add Docs branch

- `main`
	- Contains the latest version of all packages under RDT, the code under the `main` may have experimental or not yet released features.

- `feature/BFL-<jira-id>`
	- Feature branches should be merged into `main` branch when ready
- `bugfix/BFL-<jira-id>`
	- Bugfix branches should be merged into `main` branch when ready

### RDT CI/CD

TODO: implement CI/CD for docs/api page updates

## Getting Started

### Build Tasks

---

The RDT repository houses a few Visual Studio build commands, these commands will help you do a range of things for tools under RDT;

- Linting
- Formatting
- Building tool packages
- Building tool binaries
- Hosting tool rojo servers
- Hosting the documentation site
	- In order to host the documentation site, please ensure you have `moonwave` installed through npm!

### Creating a new RDT tool

---

TODO: create a .md file explaining these steps.. and or convert internal confluence page to external page for our api docs section 

### Workspaces

---

RDT was designed with the Visual Studio Code IDE in mind, this said, it is suggested that you use the multi-root workspace feature VSCode offers when working on a project in RDT.

> If this feature is not used, you may come across several errors as the tooling we use won't be able to map the project you're working on.

As a quick example, please watch the below video to get yourself onboard with how multi-root workspaces work;
https://www.youtube.com/watch?v=2yOQUtP_GcY

### Tool Versioning

---

Tool versioning should aim to follow the [Semantic Versioning](https://semver.org/) convention
