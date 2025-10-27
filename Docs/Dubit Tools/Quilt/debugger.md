---
sidebar_position: 4
---

# Debugger
![image](/quilt/debugger_preview.png)
🏷️ *Debbuger displaying interfaces within Nascar Speed Hub* 

Debugger is a window displaying ***all*** interfaces that are ***currently instanced***, this means that all of the interfaces are listed no matter if they are visible, overlapped or hidden away. The purpose of this tool is to help you debug **Quilt's** behaviour, which could mean checking out which interfaces overlap, or what is the current state of given interface. The window itself can be dragged around the whole screen so it doesn't overlap the interface you are currently debugging.

To preview an interface select one from the list using LMB (*Left Mouse Button*) and the bounding box of that interface should appear on the screen, it's colour depends on the state of the interface.

- :::tip green
The interface is visible and not overlapped by any interface.
:::
- :::caution Yellow
The interface is requested to be visible but it's hidden because it got overlapped by some interface.
:::
- :::warning Red
The interface is not visible at all.
:::

:::info
It's possible to select multiple interfaces by holding down CTRL (Windows) or Command symbol (macOS)
:::
## Importing debugger

To import the debugger you need to add an additional dependency to your `wally.toml` file:
```lua
QuiltDebugger = "dubit/quilt-debugger@0.1.0"
```

The debugger will initialise itself upon requiring QuiltDebugger from the Package directory. You can switch it's visibility by using one of it's three methods:
```lua
QuiltDebugger:HideDebugger()

QuiltDebugger:ShowDebugger()

QuiltDebugger:SwitchDebugger() -- if the interface is open it will close and vice versa
```
:::caution
Debugger window is visible by default when imported to the project. You need to call `QuiltDebugger:HideDebugger()` to hide it.
:::