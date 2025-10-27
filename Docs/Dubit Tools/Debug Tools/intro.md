# Getting Started

The confluence page for Debug Tools can be found [here](https://dubitlimited.atlassian.net/wiki/spaces/PROD/pages/4175331332/Debug+Tools)

## Adding Debug Tools to a Project

To add `Debug Tools` package to your project add the following into your `wally.toml` file.

:::info
The package doesn't need to be required within another script to be initialized, the package does it by itself.
:::

```lua
[dependencies]
DebugTools = "dubit/debug-tools@~0.2"
```

:::caution
DebugTools package may not work as expected if required from within an Actor

This is because the module self-initialises from a default non-actor context
:::