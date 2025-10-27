---
sidebar_position: 1
---

# Getting Started with Wally

:::note
This document assumes that you already have the Wally package manager installed on your system.
:::

## Generating the Wally Configuration file

To get started with a *Wally* project, please execute the `wally init` command through a terminal under your projects directory;

```bash
C:\..\project-name> wally init
```

This command should generate a base `wally.toml` file that we can use to add dependencies into our project.

## Adding dependencies

### Private Wally dependencies

:::note
Please note that in order to search for internal tools, you'll need to follow the steps seen in ["*Wally Authentication*"](/docs/Wally%20Config/authentication)
:::

You can find private Wally packages by executing the following command inside of a Terminal;

```bash
C:\..\project-name> wally search "dubit/"
```

A list of internal wally packages should now present themselves, they should resemble the following snippet of code;

```lua
packageName = "author/packageName@version"
	packageDescription
```

To add these into your project, please head on over to the [Installing Guide](/docs/Dubit%20Tools/intro)