return function()
	local Event = require(script.Parent)
	local UTC = require(script.Parent.Parent.UTC)

	local startPayload, endPayload =
		{
			Year = 2023,
			Month = 5,
			Day = 26,
			Hour = 9,
			Minute = 34,
			Second = 50,
		}, {
			Year = 2023,
			Month = 5,
			Day = 26,
			Hour = 9,
			Minute = 36,
			Second = 50,
		}

	describe("new", function()
		it("should be able to generate an Event object", function()
			local object = Event.new("Test_Event_1", {})

			expect(object).to.be.ok()
			expect(object.Label).to.equal("Test_Event_1")
		end)

		it("should be able to generate an Event object with UTCStartTime & UTCEndTime", function()
			local object = Event.new("Test_Event_2", {
				UTCStartTime = UTC.new(startPayload),
				UTCEndTime = UTC.new(endPayload),
			})

			expect(object).to.be.ok()
			expect(object.EndTimer).to.be.ok()
			expect(object.StartTimer).to.be.ok()
		end)

		it("shouldn't be able to generate an event with only a non-unique name", function()
			expect(function()
				Event.new("Test_Event_2", {})
			end).to.throw()
		end)

		it("shouldn't be able to generate an event with only UTCStartTime", function()
			expect(function()
				Event.new("Test_Event_3", {
					UTCStartTime = UTC.new(startPayload),
				})
			end).to.throw()
		end)

		it("event should be active if UTC time start before initialisation", function()
			local currentUTCTime = os.date("!*t")
			local currentEvent = Event.new("Test_Event_4", {
				UTCStartTime = UTC.new({
					Year = currentUTCTime.year,
					Month = currentUTCTime.month,
					Day = currentUTCTime.day,
					Hour = currentUTCTime.hour,
					Minute = currentUTCTime.min - 5,
					Second = currentUTCTime.sec,
				}),

				UTCEndTime = UTC.new({
					Year = currentUTCTime.year,
					Month = currentUTCTime.month,
					Day = currentUTCTime.day,
					Hour = currentUTCTime.hour,
					Minute = currentUTCTime.min + 5,
					Second = currentUTCTime.sec,
				}),
			})

			currentEvent:UpdateTimers()

			expect(currentEvent:GetState()).to.equal(true)
		end)

		it("event shouldn't be active before the event has started", function()
			local currentUTCTime = os.date("!*t")
			local currentEvent = Event.new("Test_Event_5", {
				UTCStartTime = UTC.new({
					Year = currentUTCTime.year,
					Month = currentUTCTime.month,
					Day = currentUTCTime.day,
					Hour = currentUTCTime.hour,
					Minute = currentUTCTime.min + 5,
					Second = currentUTCTime.sec,
				}),

				UTCEndTime = UTC.new({
					Year = currentUTCTime.year,
					Month = currentUTCTime.month,
					Day = currentUTCTime.day,
					Hour = currentUTCTime.hour,
					Minute = currentUTCTime.min + 10,
					Second = currentUTCTime.sec,
				}),
			})

			currentEvent:UpdateTimers()

			expect(currentEvent:GetState()).to.equal(false)
		end)

		it("event shouldn't be active after the event has ended", function()
			local currentUTCTime = os.date("!*t")
			local currentEvent = Event.new("Test_Event_6", {
				UTCStartTime = UTC.new({
					Year = currentUTCTime.year,
					Month = currentUTCTime.month,
					Day = currentUTCTime.day,
					Hour = currentUTCTime.hour,
					Minute = currentUTCTime.min - 10,
					Second = currentUTCTime.sec,
				}),

				UTCEndTime = UTC.new({
					Year = currentUTCTime.year,
					Month = currentUTCTime.month,
					Day = currentUTCTime.day,
					Hour = currentUTCTime.hour,
					Minute = currentUTCTime.min - 5,
					Second = currentUTCTime.sec,
				}),
			})

			currentEvent:UpdateTimers()

			expect(currentEvent:GetState()).to.equal(false)
		end)
	end)

	describe("is", function()
		it("should have event objects type match", function()
			local object = Event.new("Test_Event_0", {})

			expect(Event.is(object)).to.equal(true)
		end)
	end)
end
