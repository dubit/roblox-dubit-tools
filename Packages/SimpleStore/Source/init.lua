--[[
	SimpleStore:
		A light-weight, simple version of DubitStore
]]
--

local Store = require(script.Store)

local SimpleStore = {}

function SimpleStore:GetPlayerStore(key: Player, datastoreName: string?)
	return Store.new(datastoreName or "DEFAULT_DATASTORE_NAME", key)
end

return SimpleStore
