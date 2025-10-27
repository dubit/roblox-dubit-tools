--[[
	Returns true if studio is currently offline, offline studio can't access information such as DataStores.
]]
return function()
	return game.GameId == 0
end
