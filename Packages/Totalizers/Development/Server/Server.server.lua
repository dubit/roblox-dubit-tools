local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Totalizers = require(ReplicatedStorage.Packages.Totalizers)

Totalizers.TotalizerUpdated:Connect(function(name, value)
	print("TotalizerUpdated", name, value)
end)

print("ResetAsync", Totalizers:ResetAsync("Hello"))
print("GetAsync", Totalizers:GetAsync("Hello"))
print("IncrementAsync", Totalizers:IncrementAsync("Hello"))

Totalizers:SetUpdateRate(30)
