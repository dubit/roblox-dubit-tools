--[[
	TaskQueueObject - internal queue objects used throughout the DubitStore library, this queue processes jobs - functions.
]]
--

local Console = require(script.Parent.Parent.Console)

local DEFAULT_QUEUE_FREQUENCY = 1

local TaskQueueObject = {}

TaskQueueObject.prototype = {}
TaskQueueObject.interface = {}

--[[
	Generates a new worker thread, this thread will call :Cycle on the TaskQueueObject each "frequency" interval.
]]
--
function TaskQueueObject.prototype:SpawnWorker()
	local workerId = #self._workers + 1

	table.insert(
		self._workers,
		task.spawn(function()
			self._reporter:Debug(`Worker {workerId}: Started`)

			while true do
				if #self._stack > 0 then
					self._reporter:Debug(`Worker {workerId}: Processing`)

					if #self._stack > 1 and #self._workers == #self._processing + 1 then
						self._reporter:Debug(`All DubitStore Workers active - requests throttled!`)
					end

					self:Cycle()
					self._reporter:Debug(`Worker {workerId}: Completed, now yielding..`)
				end

				task.wait(self._frequency)
			end
		end)
	)
end

--[[
	Will halt & stop one of the worker threads.
]]
--
function TaskQueueObject.prototype:StopWorker()
	if #self._workers == 0 then
		return
	end

	local thread = table.remove(self._workers, 1)

	self._reporter:Debug(`Worker {#self._workers - 1}: Killed`)

	task.cancel(thread)
end

--[[
	Sets the frequency for each worker thread, defines how fast these threads process jobs.
]]
--
function TaskQueueObject.prototype:SetFrequency(frequency)
	self._frequency = frequency
end

--[[
	Processes & calls a job, this function will yield.
]]
--
function TaskQueueObject.prototype:Cycle()
	local item = table.remove(self._stack, 1)

	if not item then
		return
	end

	-- _processing is a table containing a list of true's, thes true's indicate the workers that are currently yielding.
	table.insert(self._processing, true)

	pcall(item)

	table.remove(self._processing, 1)
end

--[[
	Grabs the size of jobs left to do.
]]
--
function TaskQueueObject.prototype:Size()
	return #self._stack
end

--[[
	Are there still jobs waiting in a queue, and are there also any workers currently processing jobs.
]]
--
function TaskQueueObject.prototype:IsActive()
	return #self._processing > 0 or self:Size() > 0
end

--[[
	Sets a limit for how many jobs can build up into a queue.
]]
--
function TaskQueueObject.prototype:SetLimit(limit)
	self._limit = limit
end

--[[
	Removes a task from our workers queue
]]
--
function TaskQueueObject.prototype:RemoveTask(object)
	local taskIndex = table.find(self._stack, object)

	if taskIndex then
		table.remove(self._stack, taskIndex)
	end
end

--[[
	Adds a task into our workers queue, this task will be executed by one of the workers when ready.
]]
--
function TaskQueueObject.prototype:AddTask(object)
	if self._limit and self:Size() > self._limit then
		return
	end

	table.insert(self._stack, object)
end

--[[
	Adds a task into our workers queue, however will yield the current thread if there's not enough space in our queue to insert our new job.
]]
--
function TaskQueueObject.prototype:AddTaskAsync(object)
	while self._limit and self:Size() > self._limit do
		task.wait()
	end

	table.insert(self._stack, object)
end

--[[
	Constructor used to generate a new TaskQueueObject.
]]
--
function TaskQueueObject.interface.new(threadCount)
	local self = setmetatable({
		_stack = {},
		_processing = {},
		_workers = {},
		_limit = nil,
		_frequency = DEFAULT_QUEUE_FREQUENCY,

		_reporter = Console:CreateReporter("DubitStore-Queue"),
	}, { __index = TaskQueueObject.prototype })

	for _ = 1, threadCount or 0 do
		self:SpawnWorker()
	end

	return self
end

return TaskQueueObject.interface :: typeof(TaskQueueObject.interface)
