local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitStore = require(ReplicatedStorage.Packages.DubitStore)

DubitStore:SetVerbosity(true)

DubitStore:SetDataAsync("PlayerData_0.0.0", "1441032575", {
	Cookies = 5,
})

print(DubitStore:PushAsync("PlayerData_0.0.0", "1441032575"):await())
