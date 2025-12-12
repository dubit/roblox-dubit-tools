local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")

local Signal = require(script.Parent:WaitForChild("Signal"))
local DubitUtils = require(script.Parent:WaitForChild("DubitUtils"))

local TOTALIZER_UPDATE_TOPIC = "__TOTALIZERS_UPDATE"

local TOTALIZERS_DATASTORE = DataStoreService:GetDataStore("Dubit_Totalizers")
local isTotalizerAccessible = pcall(TOTALIZERS_DATASTORE.ListKeysAsync, TOTALIZERS_DATASTORE)

local currentUpdateRate = 60 -- seconds
local broadcastNewTotalizerValues = true

local lastTotalizerUpdate = {}
local totalizerValueCache = {}

local Totalizers = {
	TotalizerUpdated = Signal.new(),
}

local function retryIfFailed(callback, attempts)
	local success, result = pcall(callback)
	local attemptsDone = 0

	while not success do
		task.wait(1)

		if attemptsDone >= attempts then
			break
		else
			attemptsDone += 1
		end

		success, result = pcall(callback)
	end

	return success, result
end

local function updateTotalizer(name: string)
	local previousValue = totalizerValueCache[name]

	local newValue = Totalizers:GetAsync(name)

	lastTotalizerUpdate[name] = DateTime.now().UnixTimestamp
	totalizerValueCache[name] = newValue

	if newValue ~= previousValue then
		Totalizers.TotalizerUpdated:Fire(name, newValue)
	end
end

local function updateTotalizers()
	for totalizer, lastUpdate in lastTotalizerUpdate do
		if DateTime.now().UnixTimestamp - lastUpdate < currentUpdateRate then
			continue
		end

		task.spawn(updateTotalizer, totalizer)
	end
end

local function fetchAvailableTotalizers()
	local availableTotalizers = {}
	local keysList = TOTALIZERS_DATASTORE:ListKeysAsync()

	while true do
		local totalizers = keysList:GetCurrentPage()

		for _, key: DataStoreKey in totalizers do
			table.insert(availableTotalizers, key.KeyName)
		end

		if keysList.IsFinished then
			break
		else
			local success = retryIfFailed(function()
				keysList:AdvanceToNextPageAsync()
			end, 5)

			if not success then
				break
			end
		end
	end

	for _, totalizer in availableTotalizers do
		updateTotalizer(totalizer)
	end
end

function Totalizers.GetAsync(self, totalizer: string)
	assert(self == Totalizers, "Expected ':' not '.' calling member function Get")

	if RunService:IsStudio() then
		assert(isTotalizerAccessible, "Cannot access Totalizer with 'Enable Studio Access to API Services' disabled.")
	end

	local cachedValue = totalizerValueCache[totalizer]
	local lastUpdate = lastTotalizerUpdate[totalizer]
	if cachedValue and lastUpdate then
		if DateTime.now().UnixTimestamp - lastUpdate < currentUpdateRate then
			return cachedValue
		end
	end

	local success, value = retryIfFailed(function()
		return TOTALIZERS_DATASTORE:GetAsync(totalizer)
	end, 5)

	assert(success, "Failed to get current value of the totalizer.")

	local newValue = value or 0
	if cachedValue ~= newValue then
		task.defer(Totalizers.TotalizerUpdated.Fire, Totalizers.TotalizerUpdated, totalizer, newValue)
	end

	totalizerValueCache[totalizer] = newValue

	return newValue
end

function Totalizers.IncrementAsync(self, totalizer: string, incrementBy: number?)
	assert(self == Totalizers, "Expected ':' not '.' calling member function Increment")

	if RunService:IsStudio() then
		assert(isTotalizerAccessible, "Cannot access Totalizer with 'Enable Studio Access to API Services' disabled.")
	end

	local currentValue

	local success = retryIfFailed(function()
		TOTALIZERS_DATASTORE:UpdateAsync(`{totalizer}`, function(value)
			currentValue = (value or 0) + (incrementBy or 1)

			return currentValue
		end)

		lastTotalizerUpdate[totalizer] = DateTime.now().UnixTimestamp
		totalizerValueCache[totalizer] = currentValue

		task.defer(Totalizers.TotalizerUpdated.Fire, Totalizers.TotalizerUpdated, totalizer, currentValue)

		if broadcastNewTotalizerValues then
			local writer = DubitUtils.BufferWriter.new(1000)
			writer:WriteVarLenString(totalizer)
			writer:Writeu40(currentValue)
			writer:Fit()

			MessagingService:PublishAsync(TOTALIZER_UPDATE_TOPIC, writer.Buffer)
		end
	end, 5)

	return success, currentValue
end

function Totalizers.ResetAsync(self, totalizer: string)
	assert(self == Totalizers, "Expected ':' not '.' calling member function Reset")

	if RunService:IsStudio() then
		assert(isTotalizerAccessible, "Cannot access Totalizer with 'Enable Studio Access to API Services' disabled.")
	end

	local success = retryIfFailed(function()
		TOTALIZERS_DATASTORE:SetAsync(`{totalizer}`, 0)
	end, 5)

	if success then
		lastTotalizerUpdate[totalizer] = DateTime.now().UnixTimestamp
		totalizerValueCache[totalizer] = 0
		task.defer(Totalizers.TotalizerUpdated.Fire, Totalizers.TotalizerUpdated, totalizer, 0)
	end

	return success
end

function Totalizers.SetUpdateRate(self, updateRate: number)
	assert(self == Totalizers, "Expected ':' not '.' calling member function SetUpdateRate")
	assert(typeof(updateRate) == "number", "missing argument #2 to 'SetUpdateRate' (number expected)")

	currentUpdateRate = math.max(30, updateRate)
end

function Totalizers.GetUpdateRate(self)
	assert(self == Totalizers, "Expected ':' not '.' calling member function GetUpdateRate")

	return currentUpdateRate
end

function Totalizers.SetBroadcastingEnabled(self, enabled: boolean)
	assert(self == Totalizers, "Expected ':' not '.' calling member function SetUpdateRate")
	assert(typeof(enabled) == "boolean", "missing argument #2 to 'SetUpdateRate' (boolean expected)")

	broadcastNewTotalizerValues = enabled
end

MessagingService:SubscribeAsync(TOTALIZER_UPDATE_TOPIC, function(message)
	local reader = DubitUtils.BufferReader.new(message.Data)
	local totalizerName = reader:ReadVarLenString()
	local totalizerCount = reader:Readu40()

	if not lastTotalizerUpdate[totalizerName] then
		return
	end

	if message.Sent < lastTotalizerUpdate[totalizerName] then
		return
	end

	if totalizerValueCache[totalizerName] == totalizerCount then
		return
	end

	lastTotalizerUpdate[totalizerName] = message.Sent
	totalizerValueCache[totalizerName] = totalizerCount

	task.defer(Totalizers.TotalizerUpdated.Fire, Totalizers.TotalizerUpdated, totalizerName, totalizerCount)
end)

if RunService:IsStudio() and not isTotalizerAccessible then
	warn("'Enable Studio Access to API Services' is disabled, Totalizers won't function during this session.")
else
	fetchAvailableTotalizers()

	task.spawn(function()
		while task.wait(currentUpdateRate) do
			updateTotalizers()
		end
	end)
end

return Totalizers
