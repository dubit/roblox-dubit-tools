---
sidebar_position: 1
---

# Installing Guide

## Dependency Example

The below is an modified `wally.toml` pulled from the [*NASCAR*](https://bitbucket.org/dubitplatform/nascar-speed-hub/src/main/) project

```yml
[package]
name = "dubit/nascar-hub"
version = "0.0.1"
realm = "shared"

#[place]
#shared-packages = "game.ReplicatedStorage.Packages"

#[server-dependencies]
#packageName = "author/packageName@version"

#[dev-dependencies]
#packageName = "author/packageName@version"

[dependencies]
Roact = "roblox/roact@1.4.4"
Console = "4x8matrix/console@1.2.1"
DubitStore = "dubit/dubit-store@0.1.27"

# Truncated dependencies since there are quite a bit..
...
```

## Dependency Snippets

:::note
`Wally` can generate up to three types of folders in the top-level of your repository

- "/Packages"
- "/DevPackages"
- "/ServerPackages"

Please ensure that your `Rojo` project map has support for the folders your project will be using.
:::

### Shared Dependencies

Shared dependencies represent the common dependencies we'll be using in our project, it's unlikely that we're going to need either Server or Dev dependencies when programming a Roblox experience.

```lua
[dependencies]
packageName = "author/packageName@version"
```

In the above examples, the `packageName`, `author` and `version` would be replace for the desired package, for example;

```yml
# packageName    author/packageName@version
  Roact        =    "roblox/roact@1.4.4"
```

### Server Dependencies

In the case we need to add Server Dependencies, we can do so by following the below snippet of code

```lua
[place]
shared-packages = "game.ReplicatedStorage.Packages"

[server-dependencies]
packageName = "author/packageName@version"
```

In the above snippet of code, we're defining a `[place]` block and then later defining where our "Packages" are being stored.

By default packages will be stored into `"game.ReplicatedStorage.Packages"` so the above `[place]` block should only be modified if packages are being installed elsewhere.

### Dev Dependencies

And lastly, we can add developer dependencies into our project by the following;

```lua
[dev-dependencies]
packageName = "author/packageName@version"
```