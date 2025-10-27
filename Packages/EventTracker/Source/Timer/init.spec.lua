return function()
	local Timer = require(script.Parent)
	local UTC = require(script.Parent.Parent.UTC)

	local payload = {
		Year = 2023,
		Month = 5,
		Day = 26,
		Hour = 9,
		Minute = 34,
		Second = 50,
	}

	describe("new", function()
		it("should be able to generate an Timer object", function()
			local object = Timer.new(UTC.new(payload))

			expect(object).to.be.ok()
		end)

		it("should be marked as expired if the date is behind the current time", function()
			local object = Timer.new(UTC.new({
				Year = payload.Year - 1,
				Month = payload.Month,
				Day = payload.Day,
				Hour = payload.Hour,
				Minute = payload.Minute,
				Second = payload.Second,
			}))

			expect(object:IsExpired()).to.equal(true)
		end)
	end)

	describe("is", function()
		it("should have timer objects type match", function()
			local object = Timer.new(UTC.new(payload))

			expect(Timer.is(object)).to.equal(true)
		end)
	end)
end
