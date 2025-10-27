return function()
	local UTC = require(script.Parent)

	local osUTCTime = os.time(os.date("!*t"))
	local payload = {
		Year = 2023,
		Month = 5,
		Day = 26,
		Hour = 9,
		Minute = 34,
		Second = 50,
	}

	describe("new", function()
		it("should generate a new UTC object", function()
			expect(UTC.new(payload)).to.be.ok()
		end)

		it("should fail to generate a new UTC object with bad payload", function()
			expect(function()
				return UTC.new({
					Year = payload.Year,
					Month = payload.Month,
					Day = payload.Day,
					Hour = payload.Hour,
				})
			end).to.throw()
		end)

		it("should generate a UTC object of a given date", function()
			local object = UTC.new(payload)

			expect(object:GetEpochTime()).to.equal(1685093690)
		end)

		it("should generate a UTC object of a given date with BST offset", function()
			local object = UTC.new(payload):SetUTCOffset(1 * 60 * 60)

			expect(object:GetEpochTime()).to.equal(1685090090)
		end)
	end)

	describe("is", function()
		it("should have UTC objects type match", function()
			local object = UTC.new(payload)

			expect(UTC.is(object)).to.equal(true)
		end)
	end)

	describe("from", function()
		it("should be able to generate a UTC object from unix timestamp", function()
			local object = UTC.from(osUTCTime)

			expect(object:GetEpochTime()).to.equal(osUTCTime)
		end)
	end)

	describe("now", function()
		it("should have UTC type match", function()
			local object = UTC.now()

			expect(object:GetEpochTime()).to.near(osUTCTime)
		end)
	end)
end
