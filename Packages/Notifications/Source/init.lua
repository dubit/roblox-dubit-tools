--[[
	Notifications:
		The Notifications tool is intended to let you easily queue up and manage notifications for your game. It manages a
		queue of notification requests and signals when various notification states are ready.

	Documentation has been written in a Moonwave styled format, for documentation outside of moonwave - comments have been made to provide insight.

	@extern Signal https://sleitnick.github.io/RbxUtil/api/Signal/
]]
--

local Signal = require(script.Parent.Signal)

local Types = require(script.Types)

local notificationQueue = {} :: { Types.QueueEntry }
local queueIndex = 1
local queueDelay = 0
local queuePaused = false

local currentThread = nil :: thread?

--[=[
	@class Notifications

	The Notifications tool is intended to let you easily queue up and manage notifications for your game. It manages a
	queue of notification requests and signals when various notification states are ready. It provides methods for showing and
	managing

	It will not provide a UI or associated display functionality - this is intended to be a style-agnostic queueing tool that can be
	used to handle all the queueing easily, allowing developers to implement styling and animation at game level, whilst hooking
	into signals for all notification events.
]=]
local Notifications = {}

Notifications.interface = {
	--[=[
	@prop OnShowNotification Signal
	@within Notifications

	Invoked when the queue is ready to show the next notification. Invoked with args:
		- id: The string id of the notification to show
		- metadata: The data associated with this id, can be of any type
	]=]
	Shown = Signal.new() :: Types.Signal<string, any>,

	--[=[
	@prop OnHideNotification Signal
	@within Notifications

	Invoked when the queue is ready to hide the next notification. Invoked with args:
		- id: The string id of the notification to hide
		- metadata: The data associated with this id, can be of any type
	]=]
	Hidden = Signal.new() :: Types.Signal<string, any>,
} :: Types.Notifications

Notifications.internal = {}

--[=[
	@method SetDelay
	@within Notifications
	@param delay number -- The delay betweet the last OnHide and the next onShow being signalled
	@client

	Adds a delay between queue events. If set, the next notification in the queue won't fire until the
	delay has passed. This is useful if you want to have a cooldown between notifications for animation
	or gameplay reasons.

	@return ()
]=]
function Notifications.interface.SetDelay(_: NotificationsInterface, delay: number)
	queueDelay = math.max(0, delay)
end

--[=[
	@method Show
	@within Notifications
	@param id string -- The unique id used to identify this notification
	@param config Types.NotificationConfigOptions
	@param metadata any? -- Any data to be passed to the Signals and callbacks, if needed
	@param onShowCallback (id: string, metadata: any) -> ()
	@param onHideCallback (id: string, metadata: any) -> ()
	@client

	Adds a notification to the end of the queue, with the provided config and metadata. When the queue reaches this
	notification, it will emit Signals to show the notification, and then to hide it when the provided duration has elapsed,
	sending any	metadata that was provided.

	@return ()
]=]
function Notifications.interface.Show(
	_: NotificationsInterface,
	id: string,
	config: Types.NotificationConfigOptions,
	metadata: any?,
	onShowCallback: () -> (),
	onHideCallback: () -> ()
)
	local queueEntry: Types.QueueEntry = {
		id = id,
		duration = config.duration,
		canCancel = config.canCancel ~= false,
		metadata = metadata,
		onShowCallback = onShowCallback,
		onHideCallback = onHideCallback,
	}

	table.insert(notificationQueue, queueEntry)

	Notifications.internal:EvaluateQueue()
end

--[=[
	@method ShowNext
	@within Notifications
	@param id string -- The unique id used to identify this notification
	@param config Types.NotificationConfigOptions
	@param metadata any? -- Any data to be passed to the Signals and callbacks, if needed
	@param onShowCallback (id: string, metadata: any) -> ()
	@param onHideCallback (id: string, metadata: any) -> ()
	@client

	Adds a notification to the front of the queue, with the provided config and metadata. When the current notification completes,
	or immediately if there is no current notifications, tt will emit Signals to show the notification, and then to hide it when
	the provided duration has elapsed, sending any metadata that was provided.

	@return ()
]=]
function Notifications.interface.ShowNext(
	_: NotificationsInterface,
	id: string,
	config: Types.NotificationConfigOptions,
	metadata: any?,
	onShowCallback: () -> (),
	onHideCallback: () -> ()
)
	local queueEntry: Types.QueueEntry = {
		id = id,
		duration = config.duration,
		canCancel = config.canCancel ~= false,
		metadata = metadata,
		onShowCallback = onShowCallback,
		onHideCallback = onHideCallback,
	}

	if currentThread then
		table.insert(notificationQueue, queueIndex + 1, queueEntry)
	else
		table.insert(notificationQueue, queueEntry)

		Notifications.internal:EvaluateQueue()
	end
end

--[=[
	@method Cancel
	@within Notifications
	@param id string -- The notification id to be removed
	@client

	Removes notifications with the matching id from the queue, if they exist, and returns a boolean if it was succesful.

	@return boolean
]=]
function Notifications.interface.Cancel(_: NotificationsInterface, id: string): boolean
	local foundEntries = false

	for i, entry in notificationQueue do
		if entry.id == id and entry.canCancel then
			table.remove(notificationQueue, i)

			foundEntries = true
		end
	end

	return foundEntries
end

--[=[
	@method PauseQueue
	@within Notifications
	@client

	Pauses the current queue. If a notification is currently being displayed, it will let that finish
	and send the OnHideNotification signal even while paused, but not continue.

	@return ()
]=]
function Notifications.interface.PauseQueue(_: NotificationsInterface)
	queuePaused = true
end

--[=[
	@method ResumeQueue
	@within Notifications
	@client

	Resumes the current queue.

	@return ()
]=]
function Notifications.interface.ResumeQueue(_: NotificationsInterface)
	queuePaused = false

	Notifications.internal:EvaluateQueue()
end

--[=[
	@method ClearQueue
	@within Notifications
	@client

	Clear the current queue and cancel any in-progress notifications.

	@return ()
]=]
function Notifications.interface.ClearQueue(_: NotificationsInterface)
	notificationQueue = {}
	queueIndex = 1
	queuePaused = false

	if currentThread then
		task.cancel(currentThread)
	end
end

--[[
	Recursive function that evaluates, acts on and progresses the current queue. It will call the Signals and callbacks
	for showing and hiding, and will then progress to the next queue entry, or clear the queue if at the end.
]]
--
function Notifications.internal.EvaluateQueue(self: NotificationsInternal)
	if currentThread or queuePaused then
		return
	end

	local queueEntry = notificationQueue[queueIndex]

	if queueEntry then
		if queueEntry.onShowCallback then
			queueEntry.onShowCallback(queueEntry.id, queueEntry.metadata)
		end

		Notifications.interface.Shown:Fire(queueEntry.id, queueEntry.metadata)

		currentThread = task.delay(queueEntry.duration, function()
			if queueEntry.onHideCallback then
				queueEntry.onHideCallback(queueEntry.id, queueEntry.metadata)
			end

			Notifications.interface.Hidden:Fire(queueEntry.id, queueEntry.metadata)

			task.wait(queueDelay)

			currentThread = nil

			if notificationQueue[queueIndex + 1] then
				queueIndex += 1

				self:EvaluateQueue()
			else
				notificationQueue = {}
				queueIndex = 1
			end
		end)
	end
end

type NotificationsInterface = typeof(Notifications.interface)
type NotificationsInternal = typeof(Notifications.internal)

return Notifications.interface
