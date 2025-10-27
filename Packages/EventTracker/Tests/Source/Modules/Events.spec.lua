local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
	local EventTracker = require(ReplicatedStorage.Packages.EventTracker)

	it("Should be able to return a sorted list of events", function()
		local currentUTCTime = os.date("!*t")

		EventTracker.Event.new("Ordered_Event_1", {
			UTCStartTime = EventTracker.UTC.new({
				Year = currentUTCTime.year,
				Month = currentUTCTime.month,
				Day = currentUTCTime.day,
				Hour = currentUTCTime.hour,
				Minute = currentUTCTime.min + 1,
				Second = currentUTCTime.sec,
			}),

			UTCEndTime = EventTracker.UTC.new({
				Year = currentUTCTime.year,
				Month = currentUTCTime.month,
				Day = currentUTCTime.day,
				Hour = currentUTCTime.hour,
				Minute = currentUTCTime.min + 10,
				Second = currentUTCTime.sec,
			}),
		})

		EventTracker.Event.new("Ordered_Event_2", {
			UTCStartTime = EventTracker.UTC.new({
				Year = currentUTCTime.year,
				Month = currentUTCTime.month,
				Day = currentUTCTime.day,
				Hour = currentUTCTime.hour,
				Minute = currentUTCTime.min + 15,
				Second = currentUTCTime.sec,
			}),

			UTCEndTime = EventTracker.UTC.new({
				Year = currentUTCTime.year,
				Month = currentUTCTime.month,
				Day = currentUTCTime.day,
				Hour = currentUTCTime.hour,
				Minute = currentUTCTime.min + 25,
				Second = currentUTCTime.sec,
			}),
		})

		expect(EventTracker:GetNextEvent().Label).to.equal("Ordered_Event_1")
	end)
end
