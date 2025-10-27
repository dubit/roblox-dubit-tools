return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local package = script.Parent.Parent.Parent

	local ClientChassis = require(package.Components.ClientChassis)

	local generatePrototype = require(ReplicatedStorage.Assets.HelperFunctions.Client.generatePrototype)
	local removePrototype = require(ReplicatedStorage.Assets.HelperFunctions.Client.removePrototype)

	local prototype
	local currentChassis

	if RunService:IsServer() then
		return
	end

	afterEach(function()
		if not prototype or not currentChassis then
			return warn("prototype or currentchassis is equal to nil!")
		end

		removePrototype(currentChassis)
	end)

	it(":OnLocalPlayerSeated() will not error.", function()
		prototype, currentChassis = generatePrototype()

		expect(function()
			prototype:OnLocalPlayerSeated()
		end).never.to.throw()
	end)

	it(":OnLocalPlayerExited() will not error.", function()
		prototype, currentChassis = generatePrototype()

		expect(function()
			prototype:OnLocalPlayerExited()
		end).never.to.throw()
	end)

	it(":StreamedIn() will not error.", function()
		prototype, currentChassis = generatePrototype()

		expect(function()
			prototype:StreamedIn()
		end).never.to.throw()
	end)

	it(":StreamedOut() will not error.", function()
		prototype, currentChassis = generatePrototype()

		expect(function()
			prototype:StreamedOut()
		end).never.to.throw()
	end)

	it(":StepPhysics() will run server-side physics on all chassis instances for a single frame.", function()
		prototype, currentChassis = generatePrototype()

		local flag = false

		ClientChassis.OnStepPhysicsSuccessful:Once(function()
			flag = true
		end)

		expect(flag).to.equal(false)

		expect(function()
			prototype:StepPhysics(1 / 60)
		end).never.to.throw()

		expect(flag).to.equal(true)
	end)

	it(":ListenToAttributeChangedEvents() will update the components internal table", function()
		prototype, currentChassis = generatePrototype()

		expect(function()
			prototype:ListenToAttributeChangedEvents()
		end).never.to.throw()

		prototype.Chassis:SetAttribute("Stiffness", 65)

		expect(prototype._chassisProperties.Stiffness).to.equal(65)
	end)

	it(":ResetChassisForces() will reset components mover constraint forces", function()
		prototype, currentChassis = generatePrototype()

		expect(function()
			prototype:ResetChassisForces()
		end).never.to.throw()

		expect(prototype._downForceTrackingData.ApplyDownForce).to.equal(false)
		expect(prototype._downForceTrackingData.TrackingTorque).to.equal(0)
		expect(prototype._downForceTrackingData.CurrentDownForce).to.equal(0)

		expect(prototype.Chassis.PrimaryPart.AlignOrientation.Enabled).to.equal(false)
	end)
end
