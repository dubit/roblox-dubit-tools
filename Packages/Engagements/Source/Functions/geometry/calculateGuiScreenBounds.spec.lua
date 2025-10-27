return function()
	local calculateGuiScreenBounds = require(script.Parent.calculateGuiScreenBounds)

	it("should return nil when no corners are provided", function()
		local result = calculateGuiScreenBounds({}, Vector2.new(100, 100))
		expect(result).to.equal(nil)
	end)

	it("should return nil when element is completely outside viewport", function()
		local corners = {
			Vector2.new(-10, -10),
			Vector2.new(-5, -5),
		}
		local result = calculateGuiScreenBounds(corners, Vector2.new(100, 100))
		expect(result).to.equal(nil)
	end)

	it("should calculate visible bounds for fully visible element", function()
		local corners = {
			Vector2.new(10, 10),
			Vector2.new(20, 20),
		}
		local minX, minY, maxX, maxY = calculateGuiScreenBounds(corners, Vector2.new(100, 100))
		expect(minX).to.equal(10)
		expect(minY).to.equal(10)
		expect(maxX).to.equal(20)
		expect(maxY).to.equal(20)
	end)

	it("should clamp bounds for partially visible element", function()
		local corners = {
			Vector2.new(-10, -10),
			Vector2.new(50, 50),
		}
		local minX, minY, maxX, maxY = calculateGuiScreenBounds(corners, Vector2.new(100, 100))
		expect(minX).to.equal(0)
		expect(minY).to.equal(0)
		expect(maxX).to.equal(50)
		expect(maxY).to.equal(50)
	end)

	it("should handle element at viewport boundaries", function()
		local corners = {
			Vector2.new(0, 0),
			Vector2.new(100, 100),
		}
		local minX, minY, maxX, maxY = calculateGuiScreenBounds(corners, Vector2.new(100, 100))
		expect(minX).to.equal(0)
		expect(minY).to.equal(0)
		expect(maxX).to.equal(100)
		expect(maxY).to.equal(100)
	end)
end
