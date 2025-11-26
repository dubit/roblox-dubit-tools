# API

The 'EventTracker' tool will allow developers to easily integrate "live" events into Roblox experiences.

EventTracker is based around an OOP paradigm, instantiating events and then using that generated object to interact with the Live event. Here are a few features that this module offers:

- Event Objects
	- Event Objects allow developers to easily generate events that'll occur at a specific point in the future.
- UTC Time-Based
	- UTC (Coordinated Universal Time) is the primary time standard that is used to regulate things like clocks, we've inherited this behaviour into the Event Tracker as well!

## EventTracker

### Types

#### TimeZone
```luau { .fn_type }
type TimeZone = {
	CentralAfricaTime: number,
	EastAfricaTime: number,
	WestAfricaTime: number,
	SouthAfricaStandardTime: number,
	MoroccoStandardTime: number,
	IndiaStandardTime: number,
	ChinaStandardTime: number,
	JapanStandardTime: number,
	KoreaStandardTime: number,
	CentralEuropeanTime: number,
	EasternEuropeanTime: number,
	BritishSummerTime: number,
	GreenwichMeanTime: number,
	EasternStandardTime: number,
	CentralStandardTime: number,
	MountainStandardTime: number,
	PacificStandardTime: number,
	AlaskaStandardTime: number,
	HawaiiAleutianStandardTime: number,
	AustralianEasternStandardTime: number,
	AustralianCentralStandardTime: number,
	AustralianWesternStandardTime: number,
	LordHoweStandardTime: number
}
```

### Properties

#### Event
```luau { .fn_type }
EventTracker.Event: Event
```

---

#### EventActivated
```luau { .fn_type }
EventTracker.EventActivated: Signal
```

---

#### EventDeactivated
```luau { .fn_type }
EventTracker.EventDeactivated: Signal
```

---

#### Timer
```luau { .fn_type }
EventTracker.Timer: Timer
```

---

#### TimersUpdated
```luau { .fn_type }
EventTracker.TimersUpdated: Signal
```

---

#### TimeZone
```luau { .fn_type }
EventTracker.TimeZone: TimeZone
```

---

#### UTC
```luau { .fn_type }
EventTracker.UTC: UTC
```

### Functions

#### :GetActiveEvents
```luau { .fn_type }
EventTracker:GetActiveEvents(): { Event }
```

This function will retrieve an array of active events happening at the moment

---

#### :GetEvent
```luau { .fn_type }
EventTracker:GetEvent(eventLabel: string): Event
```

This function will retrieve an event from it's label.

---

#### :GetNextEvent
```luau { .fn_type }
EventTracker:GetNextEvent(): Event?
```

This function will retrieve the next tracked event

---

#### :GetUpcomingEvents
```luau { .fn_type }
EventTracker:GetUpcomingEvents(): { Event }
```

This function will retrieve an sorted array of upcoming events, the array is sorted so closest events are first.

---

#### :SetTimerFrequency
```luau { .fn_type }
EventTracker:SetTimerFrequency(value: number): Event
```

??? example "Example Usage"
	```luau
	EventTracker:SetTimerFrequency(0.5)

	local t = tick()
	EventTracker.TimersUpdated:Wait()
	print(tick() - t) -- > around 0.5
	```

---

#### :Start
```luau { .fn_type }
EventTracker:Start(): ()
```

This function will start the background process for updating all event timers. It is important this function is called during runtime.

!!! warning
	This function is required to be called during your games init process, if this function is not called then events will not be started/ended

## Event

The 'Event' class is the primary class developers will interact with, it's job is to manipulate the logic for a live event.

### Properties

#### Activated
```luau { .fn_type }
Event.Activated: Signal
```

---

#### Deactivated
```luau { .fn_type }
Event.Deactivated: Signal
```

---

#### EndTimer
```luau { .fn_type }
Event.EndTimer: Timer?
```

---

#### StartTimer
```luau { .fn_type }
Event.StartTimer: Timer?
```

---

#### UTCEndTime
```luau { .fn_type }
Event.UTCEndTime: UTC?
```

---

#### UTCStartTime
```luau { .fn_type }
Event.UTCStartTime: UTC?
```

---

#### Label
```luau { .fn_type }
Event.Label: string
```

### Functions

#### .new
```luau { .fn_type }
Event.new(name: string, data: { UTCStartTime: UTC?, UTCEndTime: UTC? }): Event
```

This function constructs a new 'Event' class

---

#### .is
```luau { .fn_type }
Event.is(object?: Event?): boolean
```

This function compares the first parameter to the 'Event' class

---

#### :Destroy
```luau { .fn_type }
Event:Destroy(): ()
```

This function will cleanup any connections the Event has made in it's lifetime.

---

#### :DisableTimerUpdates
```luau { .fn_type }
Event:DisableTimerUpdates(): ()
```

This function will disable the logic for updating timers, developers may want to do this in the case they want to manually start or stop an event without timers taking precedence over event state.

---

#### :EnableTimerUpdates
```luau { .fn_type }
Event:EnableTimerUpdates(): ()
```

This function will enable the logic for updating timers.

---

#### :GetState
```luau { .fn_type }
Event:GetState(): boolean
```

This function will return the state of an event, if this state is 'true' then the event is active.

---

#### :GetTimeUntilEnd
```luau { .fn_type }
Event:GetTimeUntilEnd(): number
```

This function will return the amount of seconds before the end of an event.

---

#### :GetTimeUntilStart
```luau { .fn_type }
Event:GetTimeUntilStart(): number
```

This function will return the amount of seconds before the start of an event.

---

#### :IsTracked
```luau { .fn_type }
Event:IsTracked(): boolean
```

This function will return a boolean depending if this event has time constraints.

---

#### :OnActivated
```luau { .fn_type }
Event:OnActivated(): ()
```

This lifecycle function is called when the event is first activated.

!!! warning
	Aim to perform synchronous operations inside of lifecycle methods

---

#### :OnDeactivated
```luau { .fn_type }
Event:OnDeactivated(): ()
```

This lifecycle function is called when the event has expired.

!!! warning
	Aim to perform synchronous operations inside of lifecycle methods

---

#### :SetState
```luau { .fn_type }
Event:SetState(state: boolean): ()
```

This function will set the state of an event, this is typically handled internally but is exposed for developer debugging.

---

#### :ToString
```luau { .fn_type }
Event:ToString(): string
```

This function generates a string that shows the following; Event Type, Event Label.

---

#### :UpdateTimers
```luau { .fn_type }
Event:UpdateTimers(): ()
```

This function will update the Timers generated by this event.

## Timer

The 'Timer' class is an internal class that helps to track the time left before the start or end of an event occurs.

### Functions

#### .new
```luau { .fn_type }
Timer.new(expirationUTC: UTC): Timer
```

This function constructs a new 'Timer' class.

---

#### .is
```luau { .fn_type }
Timer.is(object: Timer?): boolean
```

This function compares the first parameter to the 'Timer' class.

---

#### :GetDeltaTime
```luau { .fn_type }
Timer:GetDeltaTime(): number
```

This function will return the time required to hit the UTC target.

---

#### :IsActive
```luau { .fn_type }
Timer:IsActive(): boolean
```

This function will return the current state of the Timer, weather or ot it is active.

---

#### :IsExpired
```luau { .fn_type }
Timer:IsExpired(): boolean
```

This function will let developers know if we've passed the UTC target, then causing the Timer to expire.

---

#### :ToString
```luau { .fn_type }
Timer:ToString(): string
```

This function generates a string that shows the following; Timer Type, UTC

## UTC

### Functions

#### .from
```luau { .fn_type }
UTC.from(epoch: number): UTC
```

This function constructs a new 'UTC' class from an unix timestamp.

---

#### .is
```luau { .fn_type }
UTC.is(object?: UTC?): boolean
```

This function compares the first parameter to the 'Event' class.

---

#### .new
```luau { .fn_type }
UTC.new(dateTable: { Year: number, Month: number, Day: number, Hour: number, Minute: number, Second: number }): UTC
```

This function constructs a new 'UTC' class.

---

#### .now
```luau { .fn_type }
UTC.now(): UTC
```

This function returns the current UTC time.

---

#### :GetEpochTime
```luau { .fn_type }
UTC:GetEpochTime(): number
```

This function will return the epoch time with an UTC offset applied.

---

#### :SetUTCOffset
```luau { .fn_type }
UTC:SetUTCOffset(offset: number): UTC
```

This function will apply a UTC offset to the epoch.

---

#### :ToString
```luau { .fn_type }
UTC:ToString(): string
```

This function generates a string that shows the following; UTC Type, Epoch