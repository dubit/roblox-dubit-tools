local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Package = require(ReplicatedStorage.Packages.PickupSystem)

Package.Server:CreatePickup("Example", {
	pickupModel = ReplicatedStorage.Assets.CoinModel,
	pickupRange = 10,
})

local positions = {}

for index = 1, 1000 do
	local position = Vector3.new(math.random() * 100, 2, math.random() * 100)

	table.insert(positions, position)

	Package.Server:SpawnPickup("Example", position, {
		Key = `Index-{index}`,
	})
end

task.wait(5)

for index = 1, #positions do
	Package.Server:RemovePickup("Example", `Index-{index}`)
end
