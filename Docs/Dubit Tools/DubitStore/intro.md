# Getting Started
You can add the DubitStore package to your project by adding the following into your `wally.toml` file.

```lua
[place]
shared-packages = "game.ReplicatedStorage.Packages"

[server-dependencies]
DubitStore = "dubit/dubit-store@^1"
```

## DubitStore Principles
DubitStore is based on cache, setting data will NOT save that data, it will only set that data in cache, allowing developers to quickly write and read. To push changes made in the cache, use the `:PushAsync` method.

:::note
It is important that cache is cleared for player data once a player leaves.
:::

## DubitStore Examples
Loading Data Example:
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:CreateDataSchema("Schema", {
	["Gold"] = DubitStore.Container.new(5)
})

DubitStore:GetDataAsync("DataStore", "Example"):andThen(function(data)
	data = DubitStore:ReconcileData(data, "Schema")

	print(data)
end)
```

Setting Data Example:
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:SetDataAsync("DataStore", "Example", {
	Data = "Hello, World!"
}):andThen(function()
	DubitStore:PushAsync("DataStore", "Example"):andThen(function()
		DubitStore:ClearCache("DataStore", "Example")
		-- if this is player data, we want to remove cache so when that player rejoins this server,
		-- we have an updated version of that players data.

		print("Data has been saved!")
	end)
end)
```

## Advanced DubitStore Examples

Loading Data with Session Locking
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:CreateDataSchema("Schema", {
	["Gold"] = DubitStore.Container.new(5)
})

DubitStore:YieldUntilDataUnlocked("DataStore", "Example")
DubitStore:GetDataAsync("DataStore", "Example"):andThen(function(data)
	data = DubitStore:ReconcileData(data, "Schema")

	warn("Got:", data)
end):andThen(function()
	DubitStore:SetDataSessionLocked("DataStore", "Example", true)
	DubitStore:PushAsync("DataStore", "Example", { player }):andThen(function()
		print("Locked Player Data!")
	end)
end)
```

Saving Data with Session Locking
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:SetDataSessionLocked("DataStore", "Example", false)
DubitStore:PushAsync("DataStore", "Example", { player }):andThen(function()
	DubitStore:ClearCache("DataStore", "Example")
	-- if this is player data, we want to remove cache so when that player rejoins this server,
	-- we have an updated version of that players data.

	warn("Saved Player Data!")
end)
```

---

> *you can find the latest working examples under the RIT repository: https://bitbucket.org/dubitplatform/rit/src/main/modules/DubitStore/Examples/*