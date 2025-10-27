--[[
	SimpleStore:
		A light-weight, simple version of DubitStore

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have been made to provide insight.
]]
--

local Store = require(script.Store)

local DEFAULT_DATASTORE_NAME = "SimpleStore-DataStore"

--[=[
	@class SimpleStore

	An alternative DataStore library that focuses on simplicity over features. 

	This DataStore library internally relies on the latest version of DubitStore, so your data will inherit all of the constraints and benefits DubitStore provides.
]=]
local SimpleStore = {}

SimpleStore.interface = {}
SimpleStore.internal = {}

--[=[
	Will get a PlaterDataStore instance based off of the parameter 'key' (key represents the Player!), optionally, if you would like to seperate player data from being in the same datastore, a second parameter is provided so you can define your own datastore.

	This will create a new PlayerDataStore if the player has not been allocated a PlayerDataStore already.

	```lua
	local playerStore = SimpleStore:GetPlayerStore(player)
	
	playerStore:Set({
		progression = {
			exp = 0,
			level = 10
		}
	})

	playerStore:SetKey("progression.level", 1)
	```

	@method Get
	@within SimpleStore

	@param key Player
	@param datastoreName string? -- optional, enables the developer to save player data under a unique datastore.

	@return PlayerDataStore
]=]
--
function SimpleStore.interface:GetPlayerStore(key: Player, datastoreName: string?)
	return Store.new(datastoreName or DEFAULT_DATASTORE_NAME, key)
end

return SimpleStore.interface
