local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Package = require(ReplicatedStorage.Packages.PickupSystem)

Package.Client.InteractedWith:Connect(function(_: string, model: Model)
	local modelClone = model:Clone()

	for _, object in modelClone:GetChildren() do
		object.CanCollide = false
	end

	local basePivot = model:GetPivot()
	local rotationSign = math.random() > 0.5
	local index = 0

	modelClone.Parent = workspace

	local connection
	do
		connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			index += deltaTime

			modelClone:PivotTo(
				basePivot * CFrame.new(0, index, 0) * CFrame.Angles(0, rotationSign and -index or index, 0)
			)

			for _, object in modelClone:GetChildren() do
				object.Transparency += deltaTime
			end

			if index > 5 then
				connection:Disconnect()
			end
		end)
	end
end)
