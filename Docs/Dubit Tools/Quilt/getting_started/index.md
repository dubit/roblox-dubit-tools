---
sidebar_position: 3
---

# Getting Started

Depending on the project you might need some additional packages in the projects for **Quilt** as it supports multiple of ways of handling interfaces, but there is always at least one package needed which is the **Quilt** package, to import it into your project, go into your `wally.toml` file and add additional dependency:

```lua
Quilt = "dubit/quilt@0.7.5"

# Optional
QuiltDebugger = "dubit/quilt-debugger@0.1.0"
```

:::info
The debugger is optional as it's only required for debugging **Quilt's** behaviour.
:::

Now depending on the project there are multiple ways of handling the interfaces:
- [Default Roblox UI without libraries](/docs/Quilt/getting_started/roblox_ui)
- [Roact Library](/docs/Quilt/getting_started/roact)