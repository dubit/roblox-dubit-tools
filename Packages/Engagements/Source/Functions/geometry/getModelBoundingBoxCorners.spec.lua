return function()
	local getModelBoundingBoxCorners = require(script.Parent.getModelBoundingBoxCorners)

	it("should return 8 corner points for a model's bounding box", function()
		local model = Instance.new("Model")
		local part = Instance.new("Part")
		part.Size = Vector3.new(2, 2, 2)
		part.CFrame = CFrame.new(0, 0, 0)
		part.Parent = model

		local corners = getModelBoundingBoxCorners(model)

		expect(#corners).to.equal(8)
		for _, corner in corners do
			expect(typeof(corner)).to.equal("Vector3")
		end
	end)

	it("should return correct corner positions relative to model position", function()
		local model = Instance.new("Model")
		local part = Instance.new("Part")
		part.Size = Vector3.new(2, 2, 2)
		part.CFrame = CFrame.new(5, 5, 5)
		part.Parent = model

		local corners = getModelBoundingBoxCorners(model)

		local expectedCorners = {
			Vector3.new(6, 6, 6),
			Vector3.new(6, 6, 4),
			Vector3.new(6, 4, 6),
			Vector3.new(6, 4, 4),
			Vector3.new(4, 6, 6),
			Vector3.new(4, 6, 4),
			Vector3.new(4, 4, 6),
			Vector3.new(4, 4, 4),
		}

		for i, corner in corners do
			expect(corner.X).to.equal(expectedCorners[i].X)
			expect(corner.Y).to.equal(expectedCorners[i].Y)
			expect(corner.Z).to.equal(expectedCorners[i].Z)
		end
	end)

	it("should handle rotated models", function()
		local model = Instance.new("Model")
		local part = Instance.new("Part")
		part.Size = Vector3.new(2, 2, 2)
		part.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(45), 0)
		part.Parent = model

		local corners = getModelBoundingBoxCorners(model)

		expect(#corners).to.equal(8)
		for _, corner in corners do
			expect(typeof(corner)).to.equal("Vector3")
			expect(corner.Magnitude).to.be.near(math.sqrt(2), 1)
		end
	end)
end
