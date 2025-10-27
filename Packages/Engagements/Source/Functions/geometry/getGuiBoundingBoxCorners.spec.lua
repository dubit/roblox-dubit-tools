return function()
	local getGuiBoundingBoxCorners = require(script.Parent.getGuiBoundingBoxCorners)

	it("should return four Vector2 corner points", function()
		local mockGui = {
			AbsolutePosition = Vector2.new(100, 100),
			AbsoluteSize = Vector2.new(200, 150),
		}

		local corners = getGuiBoundingBoxCorners(mockGui :: any)

		expect(#corners).to.equal(4)
		expect(corners[1]).to.equal(Vector2.new(100, 100))
		expect(corners[2]).to.equal(Vector2.new(300, 100))
		expect(corners[3]).to.equal(Vector2.new(100, 250))
		expect(corners[4]).to.equal(Vector2.new(300, 250))
	end)

	it("should handle zero size GUI objects", function()
		local mockGui = {
			AbsolutePosition = Vector2.new(50, 50),
			AbsoluteSize = Vector2.new(0, 0),
		}

		local corners = getGuiBoundingBoxCorners(mockGui :: any)

		expect(#corners).to.equal(4)
		expect(corners[1]).to.equal(Vector2.new(50, 50))
		expect(corners[2]).to.equal(Vector2.new(50, 50))
		expect(corners[3]).to.equal(Vector2.new(50, 50))
		expect(corners[4]).to.equal(Vector2.new(50, 50))
	end)

	it("should handle negative position values", function()
		local mockGui = {
			AbsolutePosition = Vector2.new(-100, -100),
			AbsoluteSize = Vector2.new(50, 50),
		}

		local corners = getGuiBoundingBoxCorners(mockGui :: any)

		expect(#corners).to.equal(4)
		expect(corners[1]).to.equal(Vector2.new(-100, -100))
		expect(corners[2]).to.equal(Vector2.new(-50, -100))
		expect(corners[3]).to.equal(Vector2.new(-100, -50))
		expect(corners[4]).to.equal(Vector2.new(-50, -50))
	end)
end
