local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:SetDataAsync("DataStore", "Example", {
	Data = "Hello, World!",
}):andThen(function()
	DubitStore:PushAsync("DataStore", "Example"):andThen(function()
		print("Data has been saved!")
	end)
end)
