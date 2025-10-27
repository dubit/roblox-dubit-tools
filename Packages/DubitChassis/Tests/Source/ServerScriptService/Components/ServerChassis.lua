local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

local TestChassis = DubitChassis.Component.new({
	Tag = "Chassis",
})

DubitChassis:StartPhysicsStep()

function TestChassis:Construct()
	print(self.Instance.Name .. " constructed!")

	self._proximityPrompt = self.VehicleSeat:FindFirstChild("ProximityPrompt")
end

function TestChassis:Start()
	print(self.Instance.Name .. " started!")

	self._trove:Add(self._proximityPrompt.Triggered:Connect(function(player: Player)
		self:StartDrivingVehicle(player.Character)
	end))
end

function TestChassis:Stop()
	print(self.Instance.Name .. " stopped!")
end

function TestChassis:OnVehicleSeatOccupantChanged()
	self:SetNetworkOwnership(self.VehicleSeat.Occupant)
end

return TestChassis
