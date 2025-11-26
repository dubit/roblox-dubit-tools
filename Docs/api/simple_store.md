# API

## SimpleStore

An alternative DataStore library that focuses on simplicity over features.

This DataStore library internally relies on the latest version of DubitStore, so your data will inherit all of the constraints and benefits DubitStore provides.

### Functions

#### Get
```luau { .fn_type }
SimpleStore:Get(key: Player, datastoreName: string?): PlayerDataStore
```

Will get a PlaterDataStore instance based off of the parameter 'key' (key represents the Player!), optionally, if you would like to seperate player data from being in the same datastore, a second parameter is provided so you can define your own datastore.

This will create a new PlayerDataStore if the player has not been allocated a PlayerDataStore already.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Set({
		progression = {
			exp = 0,
			level = 1
		}
	})
	playerStore:SetKey("progression.level", 2)
	```

## PlayerDataStore

A simple wrapper for Player orientated datastores, this is the primary datastore object that developers will be interacting with, it's goal is to make the interaction between loading, saving and manipulating player datastores easier for developers.

PlayerDataStore's also rely on Session Locking, after 60 seconds, the Session Lock will be overwritten so that the players data isn't stuck forever. A players data is only released when **[Destroy](#destroy)** has been called from the active server.

### Properties

#### Changed
```luau { .fn_type }
PlayerDataStore.Changed: Signal
```

---

#### IsNewPlayer
```luau { .fn_type }
PlayerDataStore.IsNewPlayer: boolean
```

### Functions

#### :Get
```luau { .fn_type }
PlayerDataStore:Get(fallback: any): (any, boolean)
```

!!! danger
	This function yields.

Get's the players data from datastore, provides a fallback so if no data is found, the fallback is returned instead.

??? example "Example Usage"
	```lua
	local defaultPlayerData = {
		progression = {
			experience = 0,
			level = 0
		}
	}

	local playerStore = SimpleStore:GetPlayerStore(player)

	local playerData = playerStore:Get(defaultPlayerData)
	```

!!! warning
	There is no reconciliation happening in the background, meaning if a players data changes over time, there's no guarantee that the new data exists for older users.

	One of the ways of getting reconciliation is to use **DubitUtils** package and use **DubitUtils.Table.mergeDeep** to update old data with new data values!

---

#### :GetKey
```luau { .fn_type }
PlayerDataStore:GetKey(path: string, fallback: any): any
```

!!! danger
	This function yields.

If the players data represents a table, you can use this function to get specific parts of that players data.

??? example "Example Usage"
	```lua
	local defaultPlayerData = {
		progression = {
			experience = 0,
			level = 0
		}
	}

	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Set(defaultPlayerData)

	local experience = playerStore:GetKey("progression.experience", 0)
	local level = playerStore:GetKey("progression.level", 1)
	```

---

#### :Set
```luau { .fn_type }
PlayerDataStore:Set(data: any): ()
```

!!! danger
	This function yields.

Overwrite the current players data with a new set of data.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Set({ text = "Hello, World!" })

	print(playerStore:GetKey("text")) --> Hello, World!

	playerStore:Set({ text = "Hello, Something else!" })

	print(playerStore:GetKey("text")) --> Hello, Something else!
	```

---

#### :SetKey
```luau { .fn_type }
PlayerDataStore:SetKey(path: string, data: any): ()
```

!!! danger
	This function yields.

If the players data represents a table, you can use this function to overwrite specific parts of that players data.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Set({
		pets = {
			currentAnimal = {
				animalName = "Fluffy"
			}
		}
	})

	print(playerStire:GetKey("pets.currentAnimal.animalName")) --> Fluffy
	playerStore:SetKey("pets.currentAnimal.animalName", "Joey")
	print(playerStire:GetKey("pets.currentAnimal.animalName")) --> Joey
	```

---

#### :Merge
```luau { .fn_type }
PlayerDataStore:Merge(tableToBeMerged: {[any]: any}): ()
```

!!! danger
	This function yields.

Merge the current player data with an input table, the input table takes priority so it'll overwrite keys in the current player data.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Set({
		text = "Hello, World!",
		boolean = true
	})

	print(playerStire:GetKey("text")) --> Hello, World!
	print(playerStire:GetKey("boolean")) --> true

	playerStore:Merge({
		text = "Hello, Something else!"
	})

	print(playerStire:GetKey("text")) --> Hello, Something else!
	print(playerStire:GetKey("boolean")) --> true
	```

---

#### :MergeKey
```luau { .fn_type }
PlayerDataStore:MergeKey(path: string): ()
```

!!! danger
	This function yields.

If the players data represents a table, you can use this function to merge tables under the player data together, the input table takes priority so it'll overwrite keys in the current player data.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Set({
		pets = {
			currentAnimal = {
				animalName = "Fluffy",
				animalLevel = 0,
				animalExperience = 0,
			}
		}
	})

	print(playerStore:GetKey("pets.currentAnimal.animalLevel")) --> 0
	print(playerStore:GetKey("pets.currentAnimal.animalName")) --> Fluffy

	playerStore:MergeKey("pets.currentAnimal", {
		animalLevel = 1
	})

	print(playerStore:GetKey("pets.currentAnimal.animalLevel")) --> 1
	print(playerStore:GetKey("pets.currentAnimal.animalName")) --> Fluffy
	```

---

#### :Update
```luau { .fn_type }
PlayerDataStore:Update(transformFunction: ((serverData: any) -> any)) → ()
```

!!! danger
	This function yields.

Given a transform function, this function will call the transform function with the most up-to-date player data, and will save the return of the transform function.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)

	playerStore:Update(function(latestPlayerData)
		latestPlayerData.SomethingHasChnaged = true

		return latestPlayerData
	end)
	```

---

#### :UpdateKey
```luau { .fn_type }
PlayerDataStore:UpdateKey(path: string, transformFunction: ((serverData: any) -> any)) → ()
```

!!! danger
	This function yields.

Given a transform function, this function will call the transform function with the most up-to-date player data, and will save the return of the transform function.

??? example "Example Usage"
	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	--[[
		{
			pets = {
				currentAnimal = {
					animalName = "Fluffy",
					animalLevel = 0,
					animalExperience = 0,
				}
			}
		}
	]]

	playerStore:UpdateKey("pets.currentAnimal", function(currentAnimalData)
		currentAnimalData.animalName = "Joey"

		return currentAnimalData
	end)
	```