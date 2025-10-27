local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventTracker = require(ReplicatedStorage.Packages.EventTracker)

local Event = EventTracker.Event.new("SuperCoolEventName", {
	SubEvents = {
		EventTracker.Event.new("SubEventName", { Data = 123 }),
	},

	UTCStartTime = EventTracker.UTC
		.new({
			Year = 2023,
			Month = 5,
			Day = 26,
			Hour = 11,
			Minute = 50,
			Second = 0,
		})
		:SetUTCOffset(EventTracker.TimeZone.BritishSummerTime),

	UTCEndTime = EventTracker.UTC
		.new({
			Year = 2023,
			Month = 5,
			Day = 26,
			Hour = 11,
			Minute = 59,
			Second = 0,
		})
		:SetUTCOffset(EventTracker.TimeZone.BritishSummerTime),
})

function Event:OnActivated()
	self._eventThread = task.defer(function()
		for _, eventObject in self.SubEvents do
			eventObject:SetState(true)

			task.wait(2)

			eventObject:SetState(false)
		end
	end)
end

function Event:OnDeactivated()
	task.cancel(self._eventThread)
end

warn(Event, "Created!")

EventTracker.EventActivated:Connect(function(...)
	warn("Event Active:", ...)
end)

EventTracker.EventDeactivated:Connect(function(...)
	warn("Event Deactive:", ...)
end)

return Event
