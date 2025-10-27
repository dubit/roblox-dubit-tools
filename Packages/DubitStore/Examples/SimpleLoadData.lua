local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:GetDataAsync("DataStore", "Example"):andThen(function(data)
	print(data)
end)
