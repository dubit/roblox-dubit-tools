return function()
	local check2dScreenCoverage = require(script.Parent.check2dScreenCoverage)

	it("should return true when GUI object covers more than minimum required screen area", function()
		local mockGuiObject = {
			AbsoluteSize = Vector2.new(100, 100),
		}
		local viewportSize = Vector2.new(800, 600)

		expect(check2dScreenCoverage(mockGuiObject :: any, viewportSize)).to.equal(true)
	end)

	it("should return false when GUI object covers less than minimum required screen area", function()
		local mockGuiObject = {
			AbsoluteSize = Vector2.new(10, 10),
		}
		local viewportSize = Vector2.new(800, 600)

		expect(check2dScreenCoverage(mockGuiObject :: any, viewportSize)).to.equal(false)
	end)

	it("should return true when GUI object exactly meets minimum coverage requirement", function()
		local viewportSize = Vector2.new(800, 600)
		local minArea = viewportSize.X * viewportSize.Y * 0.015
		local sideLength = math.sqrt(minArea)

		local mockGuiObject = {
			AbsoluteSize = Vector2.new(sideLength, sideLength),
		}

		expect(check2dScreenCoverage(mockGuiObject :: any, viewportSize)).to.equal(true)
	end)
end
