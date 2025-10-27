local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:ImplementMiddleware(DubitStore.Middleware.new(function(data, actionType)
	if actionType == DubitStore.Middleware.action.Get then
		-- edit data before we GET that data

		return data
	elseif actionType == DubitStore.Middleware.action.Set then
		-- edit dat before we SET that data

		return data
	else
		return
	end
end))
