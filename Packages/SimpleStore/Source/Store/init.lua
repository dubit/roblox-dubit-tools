local Players = game:GetService("Players")

local DubitStore = require(script.Parent.Parent.DubitStore)
local Sift = require(script.Parent.Parent.Sift)
local Signal = require(script.Parent.Parent.Signal)

local AUTOSAVE_INTERVAL = 5 * 60
local DEFAULT_SPLITTER = "."

local DATA_SCHEMA = "DefaultDataSchema"

DubitStore:CreateDataSchema(DATA_SCHEMA, {
	Data = DubitStore.Container.new(0),
})

local Store = {}

Store.interface = {}
Store.prototype = {}
Store.constructed = {}
Store.constructing = {}

function Store.prototype:Get(fallback: any?)
	local data = DubitStore:GetDataAsync(self.Datastore, self.Key):expect()
	local dataExists = data ~= nil

	if not dataExists then
		data = DubitStore:ReconcileData(data, DATA_SCHEMA)
		data.Data = fallback

		DubitStore:SetDataAsync(self.Datastore, self.Key, data)
	end

	return data.Data, dataExists
end

function Store.prototype:GetKey(path: string, fallback: string?)
	local data = self:Get({})
	local splitPath = string.split(path, DEFAULT_SPLITTER)
	local headNode = data

	for _, nextNode in splitPath do
		if headNode[nextNode] == nil then
			return fallback
		end

		headNode = headNode[nextNode]
	end

	return headNode
end

function Store.prototype:Set(data: any)
	DubitStore:SetDataAsync(self.Datastore, self.Key, {
		Data = data,
	})

	self.Changed:Fire(self:Get(), data)
end

function Store.prototype:SetKey(path: string, value: any)
	local updatedData = self:Get()
	local splitPath = string.split(path, DEFAULT_SPLITTER)
	local headNode = updatedData
	local lastNode

	for index, nextNode in splitPath do
		if index ~= 1 then
			lastNode = splitPath[index - 1]
		end

		if headNode[nextNode] == nil then
			error(`Unable to ':SetKey' for player '{self.Key}', unable to find '{nextNode}' in {lastNode or "data"}`)
		end

		if index ~= #splitPath then
			headNode = headNode[nextNode]
		end
	end

	headNode[splitPath[#splitPath]] = value

	self:Set(updatedData)
end

function Store.prototype:Merge(tableToBeMerged: { [any]: any })
	local data = self:Get()

	if typeof(data) ~= "table" then
		error(`Invalid DataType! Expected Table, got '{typeof(data)}'`)
	end

	local updatedData = Sift.Dictionary.mergeDeep(data, tableToBeMerged)

	self:Set(updatedData)
end

function Store.prototype:MergeKey(path: string, tableToBeMerged: { [any]: any })
	local data = self:GetKey(path)

	if typeof(data) ~= "table" then
		error(`Invalid DataType! Expected Table, got '{typeof(data)}'`)
	end

	data = Sift.Dictionary.mergeDeep(data, tableToBeMerged)

	return self:SetKey(path, data)
end

function Store.prototype:Update(transformFunction: (serverData: any) -> any)
	DubitStore:UpdateDataAsync(self.Datastore, self.Key, function(data)
		data = DubitStore:ReconcileData(data, DATA_SCHEMA)
		data = transformFunction(data.Data)

		return data
	end):expect()
end

function Store.prototype:UpdateKey(path: string, transformFunction: (serverData: any) -> any)
	DubitStore:UpdateDataAsync(self.Datastore, self.Key, function(data)
		data = DubitStore:ReconcileData(data, DATA_SCHEMA)

		local splitPath = string.split(path, DEFAULT_SPLITTER)
		local headNode = data.Data
		local lastNode

		for index, nextNode in splitPath do
			if index ~= 1 then
				lastNode = splitPath[index - 1]
			end

			if headNode[nextNode] == nil then
				error(
					`Unable to ':UpdateKey' for player '{self.Key}', unable to find '{nextNode}' in {lastNode or "data"}`
				)
			end

			if index ~= #splitPath then
				headNode = headNode[nextNode]
			end
		end

		headNode[splitPath[#splitPath]] = transformFunction(headNode[splitPath[#splitPath]])

		return data
	end):expect()
end

function Store.prototype:Save()
	DubitStore:PushAsync(self.Datastore, self.Key, {
		self.Id,
	}):expect()
end

function Store.prototype:Destroy()
	self:Save()

	Store.constructed[self.Datastore][self.Id] = nil

	self.AutosaveConnection:Disconnect()
	self.PlayersConnection:Disconnect()

	DubitStore:CancelAutosave(self.AutosaveId)
	DubitStore:SetDataSessionLocked(self.Datastore, self.Key, false)
end

function Store.interface.new(datastore: string, player: Player): Store
	if not Store.constructing[datastore] then
		Store.constructing[datastore] = {}
	end

	if not Store.constructed[datastore] then
		Store.constructed[datastore] = {}
	end

	while Store.constructing[datastore][player.UserId] do
		task.wait(0.25)
	end

	if Store.constructed[datastore][player.UserId] then
		return Store.constructed[datastore][player.UserId]
	end

	Store.constructing[datastore][player.UserId] = true

	local self = setmetatable({}, {
		__index = Store.prototype,
	})

	self.Datastore = datastore
	self.Id = player.UserId
	self.Key = tostring(self.Id)
	self.AutosaveId = `{datastore}_{self.Key}`
	self.Changed = Signal.new()

	local isSessionUnlocked = false

	task.delay(60, function()
		DubitStore:OverwriteDataSessionLocked(self.Datastore, self.Key, false)

		isSessionUnlocked = true
	end)

	task.spawn(function()
		DubitStore:YieldUntilDataUnlocked(self.Datastore, self.Key)

		isSessionUnlocked = true
	end)

	repeat
		task.wait()
	until isSessionUnlocked

	DubitStore:SetAutosaveInterval(self.AutosaveId, AUTOSAVE_INTERVAL)
	DubitStore:SetDataSessionLocked(self.Datastore, self.Key, true)

	local _, hadDataInDatastore = self:Get({})
	self:Save()

	self.IsNewPlayer = not hadDataInDatastore

	self.AutosaveConnection = DubitStore:OnAutosave(self.AutosaveId):Connect(function()
		self:Save()
	end)

	self.PlayersConnection = Players.PlayerRemoving:Connect(function(leavingPlayer: Player)
		if leavingPlayer.UserId ~= self.Id then
			return
		end

		self:Destroy()
	end)

	Store.constructed[datastore][player.UserId] = self
	Store.constructing[datastore][player.UserId] = nil

	return self
end

export type Store = typeof(Store.prototype)

return Store.interface
