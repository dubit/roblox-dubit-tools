return function()
	local check3dScreenAngle = require(script.Parent.check3dScreenAngle)

	it("should return true when angle is within threshold", function()
		local testCFrame = CFrame.new()
		local targetDirection = Vector3.new(0, 0, 1)

		expect(check3dScreenAngle(testCFrame, targetDirection)).to.equal(true)
	end)

	it("should return true when angle is at max threshold", function()
		local testCFrame = CFrame.fromEulerAnglesXYZ(0, math.rad(55), 0)
		local targetDirection = Vector3.new(0, 0, 1)

		expect(check3dScreenAngle(testCFrame, targetDirection)).to.equal(true)
	end)

	it("should return false when angle exceeds threshold", function()
		local testCFrame = CFrame.fromEulerAnglesXYZ(0, math.rad(56), 0)
		local targetDirection = Vector3.new(0, 0, 1)

		expect(check3dScreenAngle(testCFrame, targetDirection)).to.equal(false)
	end)

	it("should handle non-normalized target direction", function()
		local testCFrame = CFrame.new()
		local targetDirection = Vector3.new(0, 0, 5)

		expect(check3dScreenAngle(testCFrame, targetDirection)).to.equal(true)
	end)

	it("should handle different orientations", function()
		local testCFrame = CFrame.fromEulerAnglesXYZ(math.rad(30), math.rad(30), 0)
		local targetDirection = Vector3.new(0, 0, 1)

		expect(check3dScreenAngle(testCFrame, targetDirection)).to.equal(true)
	end)
end
