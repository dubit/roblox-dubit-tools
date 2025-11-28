local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bolt = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Bolt"))

Bolt.ReliableEvent("Hello").OnServerEvent:Connect(function(player, message)
	warn(`>{message}< #{#message}`)
end)
