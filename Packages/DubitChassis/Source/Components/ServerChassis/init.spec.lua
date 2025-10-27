return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local generatePrototype = require(ReplicatedStorage.Assets.HelperFunctions.Server.generatePrototype)

	local prototype

	if RunService:IsClient() then
		return
	end

	afterEach(function()
		if not prototype then
			return
		end

		prototype:Stop()
		prototype = nil
	end)

	it(":OnVehicleSeatOccupantChanged() will not error.", function()
		prototype = generatePrototype()

		expect(function()
			prototype:OnVehicleSeatOccupantChanged()
		end).never.to.throw()
	end)

	it(":StartDrivingVehicle() will error when given no parameters.", function()
		prototype = generatePrototype()

		expect(function()
			prototype:StartDrivingVehicle()
		end).to.throw()
	end)

	it(":SetTireInstances() will instance 4 tires for the chassis.", function()
		prototype = generatePrototype()

		expect(function()
			prototype:SetTireInstances()
		end).never.to.throw()

		expect(prototype.Chassis:FindFirstChild("TiresFolder")).to.be.ok()
		expect(#prototype.Chassis.TiresFolder:GetChildren()).to.equal(4)
	end)

	it(":ListenToAttributeChangedEvents() will update the components internal table", function()
		prototype = generatePrototype()

		expect(function()
			prototype:ListenToAttributeChangedEvents()
		end).never.to.throw()

		prototype.Chassis:SetAttribute("Stiffness", 55)

		expect(prototype._chassisProperties.Stiffness).to.equal(55)
	end)

	it(":ResetChassisForces() will reset components mover constraint forces", function()
		prototype = generatePrototype()

		expect(function()
			prototype:ResetChassisForces()
		end).never.to.throw()

		expect(prototype.Chassis.PrimaryPart.AlignOrientation.Enabled).to.equal(false)
	end)
end
