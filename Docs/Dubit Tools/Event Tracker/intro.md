# Getting Started

You can add the Event Tracker package to your project by adding the following into your `wally.toml` file.

```lua
[place]
shared-packages = "game.ReplicatedStorage.Packages"

[server-dependencies]
EventTracker = "dubit/event-tracker@^1"
```

## What is the Event Tracker package?

The goal for this package is to provide developers with an easy way to create synced global events, some base features this library provides;

- Times for events are based off of the UTC time standard.
	* *For example, if we want to offset time for an US Central event, we’d set the UTC offset to -05:00*
- Allowing developers to get status updates on events.

:::caution
The event tracker will **NOT** work in the background, developers must call the `:Start` method in order to get the library to process times for events.
:::

### Examples

The example seen below creates an "EventName" event, developers can implement functionality for these events by using the `OnActivated` and `OnDeactivated` lifecycle methods.

```lua
-- Server/.../Events/EventName.lua

local Event = EventTracker.Event.new("EventName", {
	UTCStartTime = EventTracker.UTC.new({
		Year = 2023,
		Month = 5,
		Day = 26,
		Hour = 11,
		Minute = 50,
		Second = 0,
	}):SetUTCOffset(EventTracker.TimeZone.BritishSummerTime),

	UTCEndTime = EventTracker.UTC.new({
		Year = 2023,
		Month = 5,
		Day = 26,
		Hour = 11,
		Minute = 59,
		Second = 0,
	}):SetUTCOffset(EventTracker.TimeZone.BritishSummerTime),

	EventBadge = "0000000"
})

function Event:OnActivated()
	awardPlayersEventBadge(self.EventBadge)
end

function Event:OnDeactivated()
	doSomething()
end

return Event
```

The below example details how developers can connect to changes to event state from outside of the events lifecycle methods:

```lua
EventTracker.EventActivated:Connect(function(eventObject)
	
end)

EventTracker.EventDeactivated:Connect(function(eventObject)
	
end)
```