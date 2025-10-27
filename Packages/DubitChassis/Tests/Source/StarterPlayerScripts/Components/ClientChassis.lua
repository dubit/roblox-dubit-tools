local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

local TestChassis = DubitChassis.Component.new({
	Tag = "Chassis",
})

DubitChassis:StartPhysicsStep()

function TestChassis:Construct()
	print(self.Instance.Name .. " constructed!")
end

function TestChassis:Start()
	print(self.Instance.Name .. " started!")
end

function TestChassis:Stop()
	print(self.Instance.Name .. " stopped!")
end

function TestChassis:OnLocalPlayerSeated()
	self.RaycastConnection = RunService.RenderStepped:Connect(function(deltaTime)
		self:StepPhysics(deltaTime)
	end)
end

function TestChassis:OnLocalPlayerExited()
	self.RaycastConnection:Disconnect()
end

function TestChassis:StreamedIn()
	print(self.Instance.Name .. " has been streamed in!")
end

function TestChassis:StreamedOut()
	print(self.Instance.Name .. " has been streamed out!")
end

return TestChassis
