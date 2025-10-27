return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local DubitChassis = require(ReplicatedStorage.Packages.DubitChassis)
	local generatePrototype = require(ReplicatedStorage.Assets.HelperFunctions.Server.generatePrototype)

	local prototype

	afterEach(function()
		if not prototype then
			return
		end

		prototype:Stop()

		prototype = nil
	end)

	it(":GetChassisCount() will have a chassis count of 1.", function()
		expect(DubitChassis:GetChassisCount()).to.equal(0)

		prototype = generatePrototype()

		expect(DubitChassis:GetChassisCount()).to.equal(1)
	end)

	it(":GetAllChassisInstances() will have an index of the chassis instance.", function()
		expect(DubitChassis:GetAllChassisInstances()[1]).never.to.be.ok()

		prototype = generatePrototype()

		expect(DubitChassis:GetAllChassisInstances()[1]).to.be.ok()
	end)

	it(":GetPlayerOwnedChassis() will error when given no parameters.", function()
		expect(function()
			DubitChassis:GetPlayerOwnedChassis()
		end).to.throw()
	end)

	it(":SetGlobalChassisAttributes() will set the attribute properties of the chassis instance.", function()
		prototype = generatePrototype()

		expect(function()
			DubitChassis:SetGlobalChassisAttributes({ ["ErrorAttribute"] = 99, ["MaxSpeed"] = "ErrorValue" })
		end).to.throw()

		expect(function()
			DubitChassis:SetGlobalChassisAttributes({ ["Stiffness"] = 99, ["MaxSpeed"] = 149 })
		end).never.to.throw()

		expect(DubitChassis:GetAllChassisInstances()[1]:GetAttribute("Stiffness")).to.equal(99)
		expect(DubitChassis:GetAllChassisInstances()[1]:GetAttribute("MaxSpeed")).to.equal(149)
	end)

	it(":StartPhysicsStep() will run server-side physics on all chassis instances for a single frame.", function()
		prototype = generatePrototype()

		local flag = false

		DubitChassis.OnStepPhysicsSuccessful:Once(function()
			flag = true
		end)

		expect(flag).to.equal(false)

		expect(function()
			DubitChassis:StepPhysics(1 / 60, "ServerStepPhysics")
		end).never.to.throw()

		expect(flag).to.equal(true)
	end)

	it(":StartPhysicsStep() will enable server-side physics on all chassis instances.", function()
		prototype = generatePrototype()

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
		prototype = generatePrototype()

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

	it(":RemoveAllChassis() will remove all active chassis instances.", function()
		prototype = generatePrototype()

		expect(DubitChassis:GetChassisCount()).to.equal(1)

		expect(function()
			DubitChassis:RemoveAllChassis()
		end).never.to.throw()

		prototype = nil

		expect(DubitChassis:GetChassisCount()).to.equal(0)
	end)
end
