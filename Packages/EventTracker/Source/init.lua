--[[
	EventTracker:
		This library should provide an easy way to implement events into our Roblox experiences

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have been made to provide insight.
]]
--

local Signal = require(script.Parent.Signal)

local Types = require(script.Types)

--[=[
	@class EventTracker

	The 'EventTracker' tool will allow developers to easily integrate "live" events into Roblox experiences.

	---

	EventTracker is based around an OOP paradigm, instantiating events and then using that generated object to interact with the Live event.
	Here are a few features that this module offers:

	- *Event Objects*
		- Event Objects allow developers to easily generate events that'll occur at a specific point in the future.

	- *UTC Time-Based*
		- UTC *(Coordinated Universal Time)* is the primary time standard that is used to regulate things like clocks, we've inherited this behaviour into the Event Tracker as well!
]=]
local EventTracker = {}

EventTracker.interface = {}
EventTracker.internal = {}

EventTracker.frequency = 1

--[=[
	@prop UTC UTC
	@within EventTracker
]=]
--
EventTracker.interface.UTC = require(script.UTC)

--[=[
	@prop Event Event
	@within EventTracker
]=]
--
EventTracker.interface.Event = require(script.Event)

--[=[
	@prop TimeZone TimeZone
	@within EventTracker
]=]
--
EventTracker.interface.TimeZone = require(script.TimeZone)

--[=[
	@prop Timer Timer
	@within EventTracker
]=]
--
EventTracker.interface.Timer = require(script.Timer)

--[=[
	@prop TimersUpdated Signal
	@within EventTracker
]=]
--
EventTracker.interface.TimersUpdated = Signal.new()

--[=[
	@prop EventActivated Signal
	@within EventTracker
]=]
--
EventTracker.interface.EventActivated = EventTracker.interface.Event.EventActivated

--[=[
	@prop EventDeactivated Signal
	@within EventTracker
]=]
--
EventTracker.interface.EventDeactivated = EventTracker.interface.Event.EventDeactivated

--[=[
	This function will retrieve an event from it's label.

	```lua
	local EventTracker = require(path.to.module)
	local EventEnum = require(path.to.enum)

	local xpEvent = EventTracker:GetEvent(EventEnum.DoubleWeekendExp)

	xpEvent.Activated:Connect(function()
		doSomething()
	end)

	xpEvent.Deactivated:Connect(function()
		doSomething()
	end)
	```

	@method GetEvent
	@within EventTracker

	@param eventLabel string

	@return Event
]=]
--
function EventTracker.interface:GetEvent(eventLabel: string): ()
	return EventTracker.interface.Event.get(eventLabel)
end

--[=[
	This function will retrieve an array of active events happening at the moment

	```lua
	local EventTracker = require(path.to.module)

	local activeEvents = EventTracker:GetActiveEvents()
	```

	@method GetActiveEvents
	@within EventTracker

	@return { Event }
]=]
--
function EventTracker.interface:GetActiveEvents(): { Types.Event }
	local activeEvents = {}

	for _, eventObject in EventTracker.interface.Event.getAll() do
		if not eventObject:GetState() then
			continue
		end

		table.insert(activeEvents, eventObject)
	end

	return activeEvents
end

--[=[
	This function will retrieve an sorted array of upcoming events, the array is sorted so closest events are first.

	```lua
	local EventTracker = require(path.to.module)

	local upcomingEvents = EventTracker:GetUpcomingEvents()
	```

	@method GetUpcomingEvents
	@within EventTracker

	@return { Event }
]=]
--
function EventTracker.interface:GetUpcomingEvents(): { Types.Event }
	local eventsArray = {}

	for _, eventObject in EventTracker.interface.Event.getAll() do
		if not eventObject:IsTracked() then
			continue
		end

		if eventObject:GetState() then
			continue
		end

		if eventObject:GetTimeUntilEnd() <= 0 then
			continue
		end

		table.insert(eventsArray, eventObject)
	end

	table.sort(eventsArray, function(event0, event1)
		return event0:GetTimeUntilEnd() < event1:GetTimeUntilEnd()
	end)

	return eventsArray
end

--[=[
	This function will retrieve the next tracked event

	```lua
	local EventTracker = require(path.to.module)

	local nextEvent = EventTracker:GetNextEvent()
	```

	@method GetNextEvent
	@within EventTracker

	@return Event?
]=]
--
function EventTracker.interface:GetNextEvent(): Types.Event?
	return self:GetUpcomingEvents()[1]
end

--[=[
	This function will return the size of a key in Bytes, this can be used to find how large you can scale your systems.

	```lua
	local EventTracker = require(path.to.module)
	local EventEnum = require(path.to.enum)

	EventTracker:SetTimerFrequency(0.5)

	local t = tick()
	EventTracker.TimersUpdated:Wait()
	print(tick() - t) -- > around 0.5
	```

	@method SetTimerFrequency
	@within EventTracker

	@param value number

	@return Event
]=]
--
function EventTracker.interface:SetTimerFrequency(value: number): ()
	EventTracker.frequency = value
end

--[=[
	This function will start the background process for updating all event timers. It is important this function is called during runtime.

	:::caution
		This function is required to be called during your games init process, if this function is not called
			then events will not be started/ended
	:::

	```lua
	Knit:Start():andThen(function()
		EventTracker:Start()

		print("FrameworkStarted:", ...)
	end)
	```

	@method Start
	@within EventTracker

	@return Event
]=]
--
function EventTracker.interface:Start(): ()
	task.defer(function()
		while true do
			task.wait(EventTracker.frequency)

			for _, eventObject in EventTracker.interface.Event.getAll() do
				eventObject:UpdateTimers()
			end

			EventTracker.interface.TimersUpdated:Fire()
		end
	end)
end

return EventTracker.interface :: Types.EventTracker & {
	TimersUpdated: RBXScriptSignal,
	EventActivated: RBXScriptSignal,
	EventDeactivated: RBXScriptSignal,

	UTC: Types.UTCModule,
	Event: Types.EventModule,
	Timer: Types.Timer,

	TimeZone: Types.TimeZone,
}
