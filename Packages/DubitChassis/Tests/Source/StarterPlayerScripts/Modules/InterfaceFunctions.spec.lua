return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)

	local generatePrototype = require(ReplicatedStorage.Assets.HelperFunctions.Client.generatePrototype)
	local removePrototype = require(ReplicatedStorage.Assets.HelperFunctions.Client.removePrototype)

	local prototype
	local currentChassis

	afterEach(function()
		if not prototype or not currentChassis then
			return warn("prototype or currentchassis is equal to nil!")
		end

		removePrototype(currentChassis)

		prototype = nil
		currentChassis = nil
	end)

	it(":StartPhysicsStep() will run client-side physics on all chassis instances for a single frame.", function()
		prototype, currentChassis = generatePrototype()

		local flag = false

		DubitChassis.OnStepPhysicsSuccessful:Once(function()
			flag = true
		end)

		expect(flag).to.equal(false)

		expect(function()
			DubitChassis:StepPhysics(1 / 60, "ClientStepPhysics")
		end).never.to.throw()

		expect(flag).to.equal(true)
	end)

	it(":StartPhysicsStep() will enable client-side physics on all chassis instances.", function()
		prototype, currentChassis = generatePrototype()

		local flag = false

		DubitChassis.OnStartPhysicsStep:Once(function()
			flag = true
		end)

		expect(flag).to.equal(false)

		expect(function()
			DubitChassis:StartPhysicsStep()
		end).never.to.throw()

		expect(flag).to.equal(true)
	end)

	it(":StopPhysicsStep() will not error if PhysicsStep connection exists.", function()
		prototype, currentChassis = generatePrototype()

		local flag = false

		DubitChassis.OnStopPhysicsStep:Once(function()
			flag = true
		end)

		expect(flag).to.equal(false)

		expect(function()
			DubitChassis:StopPhysicsStep()
		end).never.to.throw()

		expect(flag).to.equal(true)
	end)
end
