---
sidebar_position: 1
---

# What is Quilt?

Quilt is an interface overlap prevention library that provides tools for developers to help implement interfaces quicker and without worrying about all the interface overlap scenarios.

Each interface ***should have*** defined position, size and priority based on which Quilt decides if the interface can be currently visible. Quilt does all the overlap calculations automatically after which it notifies the developer when the status of given interface changes so the developer can reflect these change on their interface appropriately.

This library can be used to manage standard Roblox interfaces made without any external libraries or with popular interface libraries like [Roact](https://github.com/Roblox/roact), currently it's the only external library that is supported.

Quilt also comes with a state management module, called **Store** - it's a combination of [Silo](https://sleitnick.github.io/RbxUtil/api/Silo/) and [Rodux](https://github.com/Roblox/rodux), it's meant to be simple yet powerful.

With all of the things combined a developer should be able to implement all sorts of interfaces without importing any additional packages into the project.

All of the Quilt's behavior can be debugged using [Debugger](/docs/Quilt/debugger), it's a tool that can be implemented easily into any project with just one [Wally](https://wally.run) dependency.

:::caution
Quilt is only meant to be used for interfaces that are on screen not in the world space!
:::