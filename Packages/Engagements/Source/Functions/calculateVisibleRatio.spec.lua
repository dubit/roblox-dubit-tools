return function()
	local calculateVisibleRatio = require(script.Parent.calculateVisibleRatio)

	it("should return 1 when visible area equals projected area", function()
		local ratio = calculateVisibleRatio(0, 0, 10, 10, 0, 0, 10, 10)
		expect(ratio).to.equal(1)
	end)

	it("should return 0 when visible area is 0", function()
		local ratio = calculateVisibleRatio(0, 0, 0, 0, 0, 0, 10, 10)
		expect(ratio).to.equal(0)
	end)

	it("should return 0 when projected area is 0", function()
		local ratio = calculateVisibleRatio(0, 0, 10, 10, 0, 0, 0, 0)
		expect(ratio).to.equal(0)
	end)

	it("should return 0.25 when visible area is quarter of projected area", function()
		local ratio = calculateVisibleRatio(0, 0, 5, 5, 0, 0, 10, 10)
		expect(ratio).to.equal(0.25)
	end)

	it("should handle negative coordinates correctly", function()
		local ratio = calculateVisibleRatio(-5, -5, 5, 5, -10, -10, 10, 10)
		expect(ratio).to.equal(0.25)
	end)

	it("should return 0 when visible area is outside projected area", function()
		local ratio = calculateVisibleRatio(20, 20, 30, 30, 0, 0, 10, 10)

		expect(ratio).to.equal(0)
	end)
end
