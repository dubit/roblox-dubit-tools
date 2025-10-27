return function()
	local calculatePartFaceCFrame = require(script.Parent.calculatePartFaceCFrame)

	local part

	beforeEach(function()
		part = Instance.new("Part")
		part.CFrame = CFrame.new()
	end)

	afterEach(function()
		part:Destroy()
	end)

	it("should return correct rotation for Front face", function()
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Front)
		expect(result).to.be.a("userdata")
		expect(result).to.equal(CFrame.new().Rotation * CFrame.Angles(0, 0, 0))
	end)

	it("should return correct rotation for Back face", function()
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Back)
		expect(result).to.equal(CFrame.new().Rotation * CFrame.Angles(0, math.pi, 0))
	end)

	it("should return correct rotation for Right face", function()
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Right)
		expect(result).to.equal(CFrame.new().Rotation * CFrame.Angles(0, -math.pi / 2, 0))
	end)

	it("should return correct rotation for Left face", function()
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Left)
		expect(result).to.equal(CFrame.new().Rotation * CFrame.Angles(0, math.pi / 2, 0))
	end)

	it("should return correct rotation for Top face", function()
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Top)
		expect(result).to.equal(CFrame.new().Rotation * CFrame.Angles(-math.pi / 2, 0, 0))
	end)

	it("should return correct rotation for Bottom face", function()
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Bottom)
		expect(result).to.equal(CFrame.new().Rotation * CFrame.Angles(math.pi / 2, 0, 0))
	end)

	it("should respect part's existing rotation", function()
		local rotation = CFrame.Angles(math.pi / 4, math.pi / 4, math.pi / 4)
		part.CFrame = rotation
		local result = calculatePartFaceCFrame(part, Enum.NormalId.Front)
		expect(result).to.equal(rotation.Rotation * CFrame.Angles(0, 0, 0))
	end)
end
