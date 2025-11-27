--!native
--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MESSAGE_SIZE_LIMIT = 100_000 -- bytes
local F32_WARNING = true -- warn if f32 number is being serialized outside of it's exactly representable range

export type BufferReader = {
	Buffer: buffer,
	Cursor: number,
	UsedInstances: { Instance },

	ReadB8: (self: BufferReader) -> { boolean },

	ReadI8: (self: BufferReader) -> number,
	ReadI16: (self: BufferReader) -> number,
	ReadI24: (self: BufferReader) -> number,
	ReadI32: (self: BufferReader) -> number,

	ReadU8: (self: BufferReader) -> number,
	ReadU16: (self: BufferReader) -> number,
	ReadU24: (self: BufferReader) -> number,
	ReadU32: (self: BufferReader) -> number,
	ReadU40: (self: BufferReader) -> number,
	ReadU56: (self: BufferReader) -> number,

	ReadF32: (self: BufferReader) -> number,
	ReadF64: (self: BufferReader) -> number,

	ReadInstance: (self: BufferReader) -> Instance,

	ReadString: (self: BufferReader, count: number?) -> string,

	ReadVector2: (self: BufferReader) -> Vector2,
	ReadVector3: (self: BufferReader) -> Vector3,
	ReadCFrame: (self: BufferReader) -> CFrame,
	ReadColor3: (self: BufferReader) -> Color3,

	fromBuffer: (buffer: buffer) -> BufferReader,
	fromString: (string: string) -> BufferReader,
}

export type BufferWriter = {
	Buffer: buffer,
	Cursor: number,
	UsedInstances: { Instance },

	WriteB8: (self: BufferWriter, ...boolean) -> (),

	WriteI8: (self: BufferWriter, value: number) -> (),
	WriteI16: (self: BufferWriter, value: number) -> (),
	WriteI24: (self: BufferWriter, value: number) -> (),
	WriteI32: (self: BufferWriter, value: number) -> (),

	WriteU8: (self: BufferWriter, value: number) -> (),
	WriteU16: (self: BufferWriter, value: number) -> (),
	WriteU24: (self: BufferWriter, value: number) -> (),
	WriteU32: (self: BufferWriter, value: number) -> (),
	WriteU40: (self: BufferWriter, value: number) -> (),
	WriteU56: (self: BufferWriter, value: number) -> (),

	WriteF32: (self: BufferWriter, value: number) -> (),
	WriteF64: (self: BufferWriter, value: number) -> (),

	WriteInstance: (self: BufferWriter, instance: Instance) -> (),

	WriteString: (self: BufferWriter, value: string, count: number?) -> (),

	WriteVector2: (self: BufferWriter, value: Vector2) -> (),
	WriteVector3: (self: BufferWriter, value: Vector3) -> (),
	WriteCFrame: (self: BufferWriter, value: CFrame) -> (),
	WriteColor3: (self: BufferWriter, value: Color3) -> (),

	Fit: (self: BufferWriter) -> (),

	new: (size: number) -> BufferWriter,
	fromBuffer: (source: buffer) -> BufferWriter,
}

export type SignalConnection = {
	Disconnect: (self: SignalConnection) -> (),
	Destroy: (self: SignalConnection) -> (),
}

export type RestrictedConnector<T...> = {
	Connect: (self: RestrictedConnector<T...>, callback: (T...) -> ()) -> SignalConnection,
}

export type RestrictableSignal<T...> = {
	Fire: (self: RestrictableSignal<T...>, T...) -> (),
	FireSync: (self: RestrictableSignal<T...>, T...) -> (),
	HasConnections: (self: RestrictableSignal<T...>) -> boolean,
	Connect: (self: RestrictableSignal<T...>, callback: (T...) -> ()) -> SignalConnection,
	GetRestrictedConnector: (self: RestrictableSignal<T...>) -> RestrictedConnector<T...>,
	Once: (self: RestrictableSignal<T...>, callback: (T...) -> ()) -> SignalConnection,
	Wait: (self: RestrictableSignal<T...>) -> T...,
	DisconnectAll: (self: RestrictableSignal<T...>) -> (),
}

export type ReliableEvent<T...> = {
	FireServer: (self: ReliableEvent<T...>, T...) -> (),
	FireClient: (self: ReliableEvent<T...>, player: Player, T...) -> (),
	FireAllClients: (self: ReliableEvent<T...>, T...) -> (),

	OnClientEvent: RestrictedConnector<T...>,
	OnServerEvent: RestrictedConnector<(Player, T...)>,
}

export type RemoteFunction<T..., R...> = {
	InvokeServer: (self: RemoteFunction<T..., R...>, T...) -> R...,

	OnServerInvoke: (Player, T...) -> R...,
}

export type RemoteProperty<T> = {
	Observe: (self: RemoteProperty<T>, callback: (T) -> ()) -> (),
	Get: (self: RemoteProperty<T>) -> T,
	GetFor: (self: RemoteProperty<T>, player: Player) -> T,
	Set: (self: RemoteProperty<T>, newValue: T) -> (),
	SetFor: (self: RemoteProperty<T>, player: Player, newValue: T) -> (),
	ClearFor: (self: RemoteProperty<T>, player: Player) -> (),
}

export type Queue<T> = {
	first: number,
	last: number,

	push: (queue: Queue<T>, value: T) -> (),
	pop: (queue: Queue<T>) -> T,
	peek: (queue: Queue<T>) -> T,
	isEmpty: (queue: Queue<T>) -> boolean,
}

function deepFreezeValue<T>(v: T): T
	if typeof(v) == "table" then
		table.freeze(v)
		for _, value: any in v do
			if typeof(value) == "table" then
				deepFreezeValue(value)
			end
		end
	end

	return v
end

function cloneValue<T>(v: T): T
	if typeof(v) == "table" then
		local newTbl = table.clone(v)
		for key: any, value: any in v do
			if typeof(value) == "table" then
				newTbl[key] = cloneValue(value)
			end
		end

		return (newTbl :: any) :: T
	end

	return v
end

function areValuesEqual<A, B>(source: A, other: B)
	if typeof(source) ~= "table" or typeof(other) ~= "table" then
		return source == other
	end

	-- If either or both tables are an array then it will be the quickest method to determine if they are different
	if #source ~= #other then
		return false
	end

	for key, value in source do
		if not areValuesEqual(value, other[key]) then
			return false
		end
	end

	for key, value in other do
		if not areValuesEqual(value, source[key]) then
			return false
		end
	end

	return true
end

local BufferReader = {}
BufferReader.prototype = {}
BufferReader.interface = {}

function BufferReader.prototype.ReadB8(self: BufferReader)
	local bools = table.create(8, false)

	local byte = buffer.readu8(self.Buffer, self.Cursor)
	for i = 0, 7 do
		-- selene: allow(undefined_variable)
		bools[i + 1] = bit32.band(byte, bit32.lshift(1, i)) ~= 0
	end
	self.Cursor += 1

	return bools
end

function BufferReader.prototype.ReadU8(self: BufferReader)
	local v = buffer.readu8(self.Buffer, self.Cursor)
	self.Cursor += 1
	return v
end

function BufferReader.prototype.ReadU16(self: BufferReader)
	local v = buffer.readu16(self.Buffer, self.Cursor)
	self.Cursor += 2
	return v
end

function BufferReader.prototype.ReadU24(self: BufferReader)
	local v = bit32.bor(
		bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 2), 16),
		bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 1), 8),
		buffer.readu8(self.Buffer, self.Cursor)
	)

	self.Cursor += 3
	return v
end

function BufferReader.prototype.ReadU32(self: BufferReader)
	local v = buffer.readu32(self.Buffer, self.Cursor)
	self.Cursor += 4
	return v
end

function BufferReader.prototype.ReadU40(self: BufferReader)
	-- modulo operator is needed in this case as bit32.lshift has a range of [-31..31]
	-- selene: allow(undefined_variable)
	local v = (buffer.readu8(self.Buffer, self.Cursor + 4) * 2 ^ 32)
		-- selene: allow(undefined_variable)
		+ (bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 3), 24))
		-- selene: allow(undefined_variable)
		+ (bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 2), 16))
		-- selene: allow(undefined_variable)
		+ (bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 1), 8))
		-- selene: allow(undefined_variable)
		+ buffer.readu8(self.Buffer, self.Cursor)

	self.Cursor += 5
	return v
end

function BufferReader.prototype.ReadU56(self: BufferReader)
	-- The actual value of 2^56 is 72057594037927940 but Luau doesn't have enough precision to represent such number
	--  so we limit it at 2^54 which is 18014398509481984 as this number can be represented by Luau
	-- The reason why I haven't changed the method name is because we are writing 56 bit number but Luau just cannot represent it
	local low = buffer.readu32(self.Buffer, self.Cursor)
	self.Cursor += 4

	local high = BufferReader.prototype.ReadU24(self)

	return high * 4294967296 + low
end

function BufferReader.prototype.ReadI8(self: BufferReader)
	local v = buffer.readi8(self.Buffer, self.Cursor)
	self.Cursor += 1
	return v
end

function BufferReader.prototype.ReadI16(self: BufferReader)
	local v = buffer.readi16(self.Buffer, self.Cursor)
	self.Cursor += 2
	return v
end

function BufferReader.prototype.ReadI24(self: BufferReader)
	local v = bit32.bor(
		bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 2), 16),
		bit32.lshift(buffer.readu8(self.Buffer, self.Cursor + 1), 8),
		buffer.readu8(self.Buffer, self.Cursor)
	)

	if bit32.band(v, 0x800000) ~= 0 then
		v = v - 0x1000000
	end

	self.Cursor += 3
	return v
end

function BufferReader.prototype.ReadI32(self: BufferReader)
	local v = buffer.readi32(self.Buffer, self.Cursor)
	self.Cursor += 4
	return v
end

function BufferReader.prototype.ReadF32(self: BufferReader)
	local v = buffer.readf32(self.Buffer, self.Cursor)
	self.Cursor += 4
	return v
end

function BufferReader.prototype.ReadF64(self: BufferReader)
	local v = buffer.readf64(self.Buffer, self.Cursor)
	self.Cursor += 8
	return v
end

function BufferReader.prototype.ReadInstance(self: BufferReader)
	local instanceIndex = buffer.readu16(self.Buffer, self.Cursor)
	self.Cursor += 2

	return self.UsedInstances[instanceIndex]
end

function BufferReader.prototype.ReadString(self: BufferReader, count: number?)
	if count then
		local v = buffer.readstring(self.Buffer, self.Cursor, count)
		self.Cursor += count
		return v
	end

	local stringLen = buffer.readu8(self.Buffer, self.Cursor)
	local v = buffer.readstring(self.Buffer, self.Cursor + 1, stringLen)
	self.Cursor += stringLen + 1
	return v
end

function BufferReader.prototype.ReadVector2(self: BufferReader)
	local v = Vector2.new(buffer.readf32(self.Buffer, self.Cursor), buffer.readf32(self.Buffer, self.Cursor + 4))
	self.Cursor += 8
	return v
end

function BufferReader.prototype.ReadVector3(self: BufferReader)
	local v = Vector3.new(
		buffer.readf32(self.Buffer, self.Cursor),
		buffer.readf32(self.Buffer, self.Cursor + 4),
		buffer.readf32(self.Buffer, self.Cursor + 8)
	)
	self.Cursor += 12
	return v
end

function BufferReader.prototype.ReadCFrame(self: BufferReader)
	local x, y, z =
		buffer.readf32(self.Buffer, self.Cursor),
		buffer.readf32(self.Buffer, self.Cursor + 4),
		buffer.readf32(self.Buffer, self.Cursor + 8)

	local rX = buffer.readi16(self.Buffer, self.Cursor + 12) / 1000
	local rY = buffer.readi16(self.Buffer, self.Cursor + 14) / 1000
	local rZ = buffer.readi16(self.Buffer, self.Cursor + 16) / 1000
	self.Cursor += 18

	return CFrame.new(x, y, z) * CFrame.fromEulerAnglesXYZ(rX, rY, rZ)
end

function BufferReader.prototype.ReadColor3(self: BufferReader)
	local v = Color3.fromRGB(
		buffer.readu8(self.Buffer, self.Cursor),
		buffer.readu8(self.Buffer, self.Cursor + 1),
		buffer.readu8(self.Buffer, self.Cursor + 2)
	)
	self.Cursor += 3
	return v
end

function BufferReader.interface.fromBuffer(buffer: buffer): BufferReader
	return setmetatable(
		{
			Buffer = buffer,
			Cursor = 0,
			UsedInstances = {},
		} :: any,
		{
			__index = BufferReader.prototype,
		}
	)
end

function BufferReader.interface.fromString(value: string): BufferReader
	return setmetatable(
		{
			Buffer = buffer.fromstring(value),
			Cursor = 0,
			UsedInstances = {},
		} :: any,
		{
			__index = BufferReader.prototype,
		}
	)
end

local BufferWriter = {}
BufferWriter.prototype = {}
BufferWriter.interface = {}

function BufferWriter.prototype.Fit(self: BufferWriter)
	local resizedBuffer = buffer.create(self.Cursor)
	buffer.copy(resizedBuffer, 0, self.Buffer, 0, self.Cursor)
	self.Buffer = resizedBuffer
end

function BufferWriter.prototype.WriteB8(self: BufferWriter, ...)
	local args = { ... }
	assert(#args <= 8, "WriteB8 allows only up to 8 booleans to be written")

	local byte = 0
	for i = 0, #args - 1 do
		assert(type(args[i + 1]) == "boolean", "WriteB8 only allows booleans to be written")
		byte = bit32.bor(byte, bit32.lshift((args[i + 1] and 1 or 0), i))
	end
	buffer.writeu8(self.Buffer, self.Cursor, byte)
	self.Cursor += 1
end

function BufferWriter.prototype.WriteU8(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 255, "number is out of range [0..255]")

	buffer.writeu8(self.Buffer, self.Cursor, value)
	self.Cursor += 1
end

function BufferWriter.prototype.WriteU16(self: BufferWriter, value: number)
	assert(value >= 0 and value < 65536, "number is out of range [0..65,536]")

	buffer.writeu16(self.Buffer, self.Cursor, value)
	self.Cursor += 2
end

function BufferWriter.prototype.WriteU24(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 16777215, "number is out of range [0..16,777,215]")

	buffer.writeu8(self.Buffer, self.Cursor, bit32.band(value, 0xFF))
	buffer.writeu8(self.Buffer, self.Cursor + 1, bit32.band(bit32.rshift(value, 8), 0xFF))
	buffer.writeu8(self.Buffer, self.Cursor + 2, bit32.band(bit32.rshift(value, 16), 0xFF))

	self.Cursor += 3
end

function BufferWriter.prototype.WriteU32(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 4294967296, "number is out of range [0..4,294,967,296]")

	buffer.writeu32(self.Buffer, self.Cursor, value)
	self.Cursor += 4
end

function BufferWriter.prototype.WriteU40(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 1099511627775, "number is out of range [0..1,099,511,627,775]")

	for i = 0, 4 do
		buffer.writeu8(self.Buffer, self.Cursor + i, bit32.band(value, 0xFF))
		-- modulo operator and floor is needed in this case as bit32.rshift has a range of [-31..31]
		value = math.floor(value / 2 ^ 8)
	end
	self.Cursor += 5
end

function BufferWriter.prototype.WriteU56(self: BufferWriter, value: number)
	-- The actual value of 2^56 is 72057594037927940 but Luau doesn't have enough precision to represent such number
	--  so we limit it at 2^54 which is 18014398509481984 as this number can be represented by Luau
	-- The reason why I haven't changed the method name is because we are writing 56 bit number but Luau just cannot represent it
	assert(value >= 0 and value <= 18014398509481984, "number is out of range [0..18,014,398,509,481,984]")

	buffer.writeu32(self.Buffer, self.Cursor, value % 4294967296)
	self.Cursor += 4

	BufferWriter.prototype.WriteU24(self, math.floor(value / 4294967296))
end

function BufferWriter.prototype.WriteI8(self: BufferWriter, value: number)
	assert(value >= -128 and value <= 127, "number is out of range [-128..127]")

	buffer.writei8(self.Buffer, self.Cursor, value)
	self.Cursor += 1
end

function BufferWriter.prototype.WriteI16(self: BufferWriter, value: number)
	assert(value >= -32768 and value <= 32767, "number is out of range [-32,768..32,767]")

	buffer.writei16(self.Buffer, self.Cursor, value)
	self.Cursor += 2
end

function BufferWriter.prototype.WriteI24(self: BufferWriter, value: number)
	assert(value >= -8388608 and value <= 8388607, "number is out of range [-8,388,608..8,388,607]")

	-- if the value is negative, convert it to two's complement form
	if value < 0 then
		value = 0x1000000 + value
	end

	buffer.writeu8(self.Buffer, self.Cursor, bit32.band(value, 0xFF))
	buffer.writeu8(self.Buffer, self.Cursor + 1, bit32.band(bit32.rshift(value, 8), 0xFF))
	buffer.writeu8(self.Buffer, self.Cursor + 2, bit32.band(bit32.rshift(value, 16), 0xFF))

	self.Cursor += 3
end

function BufferWriter.prototype.WriteI32(self: BufferWriter, value: number)
	assert(value >= -2147483648 and value <= 2147483647, "number is out of range [-2,147,483,648..2,147,483,647]")

	buffer.writei32(self.Buffer, self.Cursor, value)
	self.Cursor += 4
end

function BufferWriter.prototype.WriteF32(self: BufferWriter, value: number)
	if F32_WARNING and math.abs(value) > 16777215 then
		warn(`number '{value}' is out of the exact precision range of f32, precision loss may occur.`)
		warn(debug.traceback(nil, 2))
	end

	buffer.writef32(self.Buffer, self.Cursor, value)
	self.Cursor += 4
end

function BufferWriter.prototype.WriteF64(self: BufferWriter, value: number)
	buffer.writef64(self.Buffer, self.Cursor, value)
	self.Cursor += 8
end

function BufferWriter.prototype.WriteInstance(self: BufferWriter, instance: Instance)
	local instanceIndex: number
	local usedInstancesIndex = table.find(self.UsedInstances, instance)

	if usedInstancesIndex then
		instanceIndex = usedInstancesIndex
	end

	if not instanceIndex then
		table.insert(self.UsedInstances, instance)
		instanceIndex = #self.UsedInstances
	end

	buffer.writeu16(self.Buffer, self.Cursor, instanceIndex)
	self.Cursor += 2
end

function BufferWriter.prototype.WriteString(self: BufferWriter, value: string, count: number?)
	if count then
		buffer.writestring(self.Buffer, self.Cursor, value, count)
		self.Cursor += count
		return
	end

	local stringLength = string.len(value)
	buffer.writeu8(self.Buffer, self.Cursor, stringLength)
	buffer.writestring(self.Buffer, self.Cursor + 1, value)
	self.Cursor += stringLength + 1
end

function BufferWriter.prototype.WriteVector2(self: BufferWriter, value: Vector2)
	buffer.writef32(self.Buffer, self.Cursor, value.X)
	buffer.writef32(self.Buffer, self.Cursor + 4, value.Y)
	self.Cursor += 8
end

function BufferWriter.prototype.WriteVector3(self: BufferWriter, value: Vector3)
	buffer.writef32(self.Buffer, self.Cursor, value.X)
	buffer.writef32(self.Buffer, self.Cursor + 4, value.Y)
	buffer.writef32(self.Buffer, self.Cursor + 8, value.Z)
	self.Cursor += 12
end

function BufferWriter.prototype.WriteCFrame(self: BufferWriter, value: CFrame)
	local position = value.Position
	local rX, rY, rZ = value:ToEulerAnglesXYZ()

	buffer.writef32(self.Buffer, self.Cursor, position.X)
	buffer.writef32(self.Buffer, self.Cursor + 4, position.Y)
	buffer.writef32(self.Buffer, self.Cursor + 8, position.Z)

	buffer.writei16(self.Buffer, self.Cursor + 12, rX * 1000)
	buffer.writei16(self.Buffer, self.Cursor + 14, rY * 1000)
	buffer.writei16(self.Buffer, self.Cursor + 16, rZ * 1000)

	self.Cursor += 18
end

function BufferWriter.prototype.WriteColor3(self: BufferWriter, color3: Color3)
	buffer.writeu8(self.Buffer, self.Cursor, math.clamp(color3.R * 255, 0, 255))
	buffer.writeu8(self.Buffer, self.Cursor + 1, math.clamp(color3.G * 255, 0, 255))
	buffer.writeu8(self.Buffer, self.Cursor + 2, math.clamp(color3.B * 255, 0, 255))

	self.Cursor += 3
end

function BufferWriter.interface.new(size: number): BufferWriter
	return setmetatable(
		{
			Buffer = buffer.create(size),
			Cursor = 0,
			UsedInstances = {},
		} :: any,
		{
			__index = BufferWriter.prototype,
		}
	)
end

function BufferWriter.interface.fromBuffer(source: buffer): BufferWriter
	return setmetatable(
		{
			Buffer = source,
			Cursor = 0,
			UsedInstances = {},
		} :: any,
		{
			__index = BufferWriter.prototype,
		}
	)
end

--[[
	This is a modified fork of https://github.com/Sleitnick/RbxUtil/blob/main/modules/signal/init.lua
	The modifications that were done to it allow us to expose a method that can be used to listen
	to signal being fired but doesn't give a direct reference to the Signal which can be used to
	tamper with the given Signal.
]]

local RestrictableSignal = {}
RestrictableSignal.__index = RestrictableSignal

local Connection = {}
Connection.__index = Connection

function Connection.new<T...>(signal: RestrictableSignal<T...>, callback: (T...) -> ()): SignalConnection
	local connection = {
		Callback = callback,

		Disconnect = function(self: SignalConnection)
			signal[self] = nil
		end,

		Destroy = function(self: SignalConnection)
			self:Disconnect()
		end,
	}

	return connection
end

function RestrictableSignal.new<T...>(): RestrictableSignal<T...>
	return setmetatable({} :: any, RestrictableSignal)
end

function RestrictableSignal.GetRestrictedConnector<T...>(self: RestrictableSignal<T...>)
	return {
		Connect = function(_, ...)
			return RestrictableSignal.Connect(self, ...)
		end,
	}
end

function RestrictableSignal.Connect<T...>(self: RestrictableSignal<T...>, callback: (T...) -> ()): SignalConnection
	local connection = Connection.new(self, callback)
	self[connection] = true
	return connection
end

function RestrictableSignal.Once<T...>(self: RestrictableSignal<T...>, callback: (T...) -> ())
	local connection
	connection = Connection.new(self, function(...)
		connection:Disconnect()
		callback(...)
	end)
	self[connection] = true
	return connection
end

function RestrictableSignal.Wait<T...>(self: RestrictableSignal<T...>)
	local waitingCoroutine = coroutine.running()
	local cn
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function RestrictableSignal.HasConnections<T...>(self: RestrictableSignal<T...>)
	return next(self) ~= nil
end

function RestrictableSignal.DisconnectAll<T...>(self: RestrictableSignal<T...>)
	table.clear(self)
end

local freeThread: thread?

local function functionCaller(taskFunction, ...)
	local usedThread = freeThread
	freeThread = nil
	taskFunction(...)
	freeThread = usedThread
end

local function taskExecutor()
	while true do
		functionCaller(coroutine.yield())
	end
end

local function spawnReusableTask(taskFunction, ...)
	if not freeThread then
		freeThread = coroutine.create(taskExecutor)
		coroutine.resume((freeThread :: any) :: thread)
	end

	task.spawn(freeThread :: thread, taskFunction, ...)
end

function RestrictableSignal.Fire<T...>(self: RestrictableSignal<T...>, ...)
	if next(self) then
		for connection in pairs(self) do
			spawnReusableTask(connection.Callback, ...)
		end
	end
end

function RestrictableSignal.FireSync<T...>(self: RestrictableSignal<T...>, ...)
	if next(self) then
		for connection in pairs(self) do
			connection.Callback(...)
		end
	end
end

local Queue = {}

function Queue.new<T>(): Queue<T>
	return setmetatable(
		{
			first = 0,
			last = -1,
		} :: any,
		{
			__index = Queue,
		}
	)
end

function Queue.push<T>(queue: Queue<T>, value: T)
	local last = queue.last + 1
	queue.last = last
	queue[last] = value
end

function Queue.pop<T>(queue: Queue<T>): T?
	local first = queue.first

	if first > queue.last then
		return nil
	end

	local value = queue[first]
	queue[first] = nil
	queue.first = first + 1

	return value
end

function Queue.peek<T>(queue: Queue<T>): T?
	return queue[queue.first]
end

function Queue.isEmpty<T>(queue: Queue<T>): boolean
	return queue.first > queue.last
end

type InternalEvent = {
	Type: "Ready" | "EventDetailsReceived" | "EventDetails",
}

type InternalEvent_EventDetailsReceived = InternalEvent & {
	Type: "EventDetailsReceived",

	Id: number,
}

type InternalEvent_EventDetails = InternalEvent & {
	Type: "EventDetails",

	Name: string,
	Id: number,
}

type IncomingPaylod = {
	Buffer: buffer,
	UsedInstances: { [string]: { Instance } }?,
}

type OutcomingPayload = {
	Id: number,
	Payload: any,
	UsedInstances: { Instance }?,
}

local IS_SERVER = RunService:IsServer()
local PAYLOAD_METADATA_OVERHEAD = 3 -- bytes

local ReliableEvent: RemoteEvent
if IS_SERVER then
	ReliableEvent = Instance.new("RemoteEvent")
	ReliableEvent.Name = "__BOLT_TRAFFIC_RELIABLE"
	ReliableEvent.Parent = ReplicatedStorage
else
	ReliableEvent = ReplicatedStorage:WaitForChild("__BOLT_TRAFFIC_RELIABLE", math.huge) :: RemoteEvent
end

local events = {} :: {
	[string]: {
		Id: number?,
		Client: RestrictableSignal<...any>,
		Server: RestrictableSignal<(Player, ...any)>,
		Serializer: (writer: BufferWriter, ...any) -> (),
		Deserializer: (reader: BufferReader) -> ...any,
	},
}
local eventIdMap = {
	FromNameToId = {} :: { [string]: number },
	FromIdToName = {} :: { [number]: string },
}
local freeEventId = 0

local targetsData = {} :: { [number]: {
	Player: Player?,

	RemoteKnowledge: { [number]: boolean },
} }

local incomingQueue = {} :: { [number]: Queue<IncomingPaylod> }
local outgoingQueue: { [number]: Queue<OutcomingPayload> } = {}

-- Used for traffic between internals of Bolt, queue processing gets halted until all of the information
-- 	about a remote is deliveted to the target, however targets should always have internal event registered
-- 	and be available for use at all times.
local internalOutgoingQueue: { [number]: Queue<OutcomingPayload> } = {}

local internalEvent: ReliableEvent<InternalEvent?>

local function createTarget(targetId: number, player: Player?)
	if targetsData[targetId] then
		return
	end

	outgoingQueue[targetId] = Queue.new()
	internalOutgoingQueue[targetId] = Queue.new()

	incomingQueue[targetId] = Queue.new()

	targetsData[targetId] = {
		Player = player,

		RemoteKnowledge = {
			[0] = true,
		},
	}
end

local function removeTarget(targetId: number)
	outgoingQueue[targetId] = nil
	incomingQueue[targetId] = nil
	targetsData[targetId] = nil
end

local SERIALIZABLE_TYPES = table.freeze({
	-- index 0 used as end of table
	["table"] = 1,
	["boolean"] = 2,
	["number"] = 3,
	["string"] = 4,
	["buffer"] = 5,
	["Instance"] = 6,
	["Vector2"] = 7,
	["Vector3"] = 8,
	["CFrame"] = 9,
	["Color3"] = 10,
	["EnumItem"] = 11,
})
local ALL_ENUMS = table.freeze(Enum:GetEnums())

local function isSerializable(value): boolean
	return SERIALIZABLE_TYPES[typeof(value)] or false
end

local function defaultSerializer(writer: BufferWriter, ...)
	local function serializeTable(content)
		local function serializeValue(value: any)
			local valueType = typeof(value)

			if valueType == "number" then
				writer:WriteF64(value)
			elseif valueType == "string" then
				writer:WriteString(value)
			elseif valueType == "boolean" then
				writer:WriteU8(value == true and 1 or 0)
			elseif valueType == "table" then
				serializeTable(value)
			elseif valueType == "buffer" then
				local bufferLen = buffer.len(value)
				writer:WriteU16(bufferLen)
				buffer.copy(writer.Buffer, writer.Cursor, value, 0, bufferLen)
				writer.Cursor += bufferLen
			elseif valueType == "Instance" then
				writer:WriteInstance(value)
			elseif valueType == "Vector2" then
				writer:WriteVector2(value)
			elseif valueType == "Vector3" then
				writer:WriteVector3(value)
			elseif valueType == "CFrame" then
				writer:WriteCFrame(value)
			elseif valueType == "Color3" then
				writer:WriteColor3(value)
			elseif valueType == "EnumItem" then
				writer:WriteU16(table.find(ALL_ENUMS, value.EnumType) :: number)
				writer:WriteU32(value.Value)
			end
		end

		for key, value in content do
			if not isSerializable(key) then
				warn(
					`The key of type '{typeof(key)}' is not supported by the default serializer. The value will not be serialized but the message will still be sent without its presence.`
				)
				continue
			end

			if not isSerializable(value) then
				warn(
					`The value of type '{typeof(value)}' is not supported by the default serializer. The value will not be serialized but the message will still be sent without its presence.`
				)
				continue
			end

			writer:WriteU8(
				bit32.bor(SERIALIZABLE_TYPES[typeof(key)], bit32.lshift(SERIALIZABLE_TYPES[typeof(value)], 4))
			)

			serializeValue(key)
			serializeValue(value)
		end
		writer:WriteU8(0)
	end

	serializeTable({ ... })
end

local function defaultDeserializer(reader: BufferReader)
	local KEY_MASK = 15 -- 00001111
	local VALUE_MASK = 240 -- 11110000

	local function deserializePairHeader(): (number, number)
		local pairHeader = reader:ReadU8()

		return bit32.band(pairHeader, KEY_MASK), bit32.rshift(bit32.band(pairHeader, VALUE_MASK), 4)
	end

	local function deserializeTable()
		local function deserializeValue(valueType: number): any
			if valueType == 1 then -- table
				return deserializeTable()
			elseif valueType == 2 then -- boolean
				return reader:ReadU8() == 1
			elseif valueType == 3 then -- number
				return reader:ReadF64()
			elseif valueType == 4 then -- string
				return reader:ReadString()
			elseif valueType == 5 then -- buffer
				local bufferLen = reader:ReadU16()
				local targetBuffer = buffer.create(bufferLen)
				buffer.copy(targetBuffer, 0, reader.Buffer, reader.Cursor, bufferLen)
				reader.Cursor += bufferLen
				return targetBuffer
			elseif valueType == 6 then -- Instance
				return reader:ReadInstance()
			elseif valueType == 7 then -- Vector2
				return reader:ReadVector2()
			elseif valueType == 8 then -- Vector3
				return reader:ReadVector3()
			elseif valueType == 9 then -- CFrame
				return reader:ReadCFrame()
			elseif valueType == 10 then -- Color3
				return reader:ReadColor3()
			elseif valueType == 11 then -- EnumItem
				local enum = ALL_ENUMS[reader:ReadU16()]
				return enum:FromValue(reader:ReadU32())
			end

			return nil
		end

		local output = {}

		while true do
			local keyType, valueType = deserializePairHeader()

			-- end of table
			if keyType == 0 then
				break
			end

			output[deserializeValue(keyType)] = deserializeValue(valueType)
		end

		return output
	end

	local outputTable = deserializeTable()

	return table.unpack(outputTable, 1, table.maxn(outputTable))
end

local buffersToReuse = {}

local function createEvent<T...>(
	eventName: string,
	serializer: ((writer: BufferWriter, T...) -> ())?,
	deserializer: ((reader: BufferReader) -> T...)?
): ReliableEvent<T...>
	local eventId
	if IS_SERVER then
		eventId = freeEventId
		freeEventId += 1

		eventIdMap.FromIdToName[eventId] = eventName
		eventIdMap.FromNameToId[eventName] = eventId
	end

	local event

	if IS_SERVER then
		local clientSignal = RestrictableSignal.new()
		local serverSignal = RestrictableSignal.new()

		events[eventName] = {
			Id = eventId,
			Client = clientSignal,
			Server = serverSignal,
			Serializer = serializer or defaultSerializer,
			Deserializer = deserializer or defaultDeserializer,
		}

		event = {
			-- selene: allow(unused_variable)
			FireServer = function(_self: ReliableEvent<T...>, ...: T...)
				error("FireServer cannot be used on server side.")
			end,
			FireClient = function(_self: ReliableEvent<T...>, player: Player, ...)
				if not player.Parent then
					return
				end

				if not targetsData[player.UserId] then
					createTarget(player.UserId, player)
				end

				local eventData = events[eventName]

				local payload
				local usedInstances
				if #buffersToReuse <= 0 then
					local writer = BufferWriter.interface.new(MESSAGE_SIZE_LIMIT)
					eventData.Serializer(writer, ...)

					payload = buffer.create(writer.Cursor)
					buffer.copy(payload, 0, writer.Buffer, 0, writer.Cursor)

					usedInstances = writer.UsedInstances

					-- Clear used buffer and put it back for reuse later
					buffer.fill(writer.Buffer, 0, 0)
					table.insert(buffersToReuse, writer.Buffer)
				else
					local firstBuffer = buffersToReuse[1]
					table.remove(buffersToReuse, 1)

					local writer = BufferWriter.interface.fromBuffer(firstBuffer)
					eventData.Serializer(writer, ...)

					usedInstances = writer.UsedInstances

					payload = buffer.create(writer.Cursor)
					buffer.copy(payload, 0, writer.Buffer, 0, writer.Cursor)

					-- Clear used buffer and put it back for reuse later
					buffer.fill(writer.Buffer, 0, 0)
					table.insert(buffersToReuse, writer.Buffer)
				end

				local queue = outgoingQueue[player.UserId]
				if eventId == 0 then
					queue = internalOutgoingQueue[player.UserId]
				end

				queue:push({
					Id = eventId,
					Payload = payload,
					UsedInstances = #usedInstances > 0 and usedInstances or nil,
				})
			end,
			FireAllClients = function(_self: ReliableEvent<T...>, ...)
				local eventData = events[eventName]

				local payload
				local usedInstances
				if #buffersToReuse <= 0 then
					local writer = BufferWriter.interface.new(MESSAGE_SIZE_LIMIT)
					eventData.Serializer(writer, ...)

					payload = buffer.create(writer.Cursor)
					buffer.copy(payload, 0, writer.Buffer, 0, writer.Cursor)

					usedInstances = writer.UsedInstances

					-- Clear used buffer and put it back for reuse later
					buffer.fill(writer.Buffer, 0, 0)
					table.insert(buffersToReuse, writer.Buffer)
				else
					local firstBuffer = buffersToReuse[1]
					table.remove(buffersToReuse, 1)

					local writer = BufferWriter.interface.fromBuffer(firstBuffer)
					eventData.Serializer(writer, ...)

					usedInstances = writer.UsedInstances

					payload = buffer.create(writer.Cursor)
					buffer.copy(payload, 0, writer.Buffer, 0, writer.Cursor)

					-- Clear used buffer and put it back for reuse later
					buffer.fill(writer.Buffer, 0, 0)
					table.insert(buffersToReuse, writer.Buffer)
				end

				for playerId in targetsData do
					local queue = outgoingQueue[playerId]
					if eventId == 0 then
						queue = internalOutgoingQueue[playerId]
					end

					queue:push({
						Id = eventId,
						Payload = payload,
						UsedInstances = #usedInstances > 0 and usedInstances or nil,
					})
				end
			end,

			OnClientEvent = clientSignal:GetRestrictedConnector(),
			OnServerEvent = serverSignal:GetRestrictedConnector(),
		}
	else
		local clientSignal = RestrictableSignal.new()
		local serverSignal = RestrictableSignal.new()

		events[eventName] = {
			Client = clientSignal,
			Server = serverSignal,
			Serializer = serializer or defaultSerializer,
			Deserializer = deserializer or defaultDeserializer,
		}

		event = {
			FireServer = function(_self: ReliableEvent<T...>, ...)
				local eventData = events[eventName]

				local payload
				local usedInstances
				if #buffersToReuse <= 0 then
					local writer = BufferWriter.interface.new(MESSAGE_SIZE_LIMIT)
					eventData.Serializer(writer, ...)

					payload = buffer.create(writer.Cursor)
					buffer.copy(payload, 0, writer.Buffer, 0, writer.Cursor)

					usedInstances = writer.UsedInstances

					-- Clear used buffer and put it back for reuse later
					buffer.fill(writer.Buffer, 0, 0)
					table.insert(buffersToReuse, writer.Buffer)
				else
					local firstBuffer = buffersToReuse[1]
					table.remove(buffersToReuse, 1)

					local writer = BufferWriter.interface.fromBuffer(firstBuffer)
					eventData.Serializer(writer, ...)

					usedInstances = writer.UsedInstances

					payload = buffer.create(writer.Cursor)
					buffer.copy(payload, 0, writer.Buffer, 0, writer.Cursor)

					-- Clear used buffer and put it back for reuse later
					buffer.fill(writer.Buffer, 0, 0)
					table.insert(buffersToReuse, writer.Buffer)
				end

				-- selene: allow(shadowing)
				local eventId = eventIdMap.FromNameToId[eventName]
				while not eventId do
					eventId = eventIdMap.FromNameToId[eventName]
					task.wait()
				end

				local queue = outgoingQueue[0]
				if eventId == 0 then
					queue = internalOutgoingQueue[0]
				end

				queue:push({
					Id = eventId,
					Payload = payload,
					UsedInstances = #usedInstances > 0 and usedInstances or nil,
				})
			end,
			-- selene: allow(unused_variable)
			FireClient = function(_self: ReliableEvent<T...>, _player: Player, ...: T...)
				error("FireClient cannot be used on client side.")
			end,
			-- selene: allow(unused_variable)
			FireAllClients = function(_self: ReliableEvent<T...>, ...: T...)
				error("FireAllClients cannot be used on client side.")
			end,

			OnClientEvent = clientSignal:GetRestrictedConnector(),
			OnServerEvent = serverSignal:GetRestrictedConnector(),
		}
	end

	return event
end

local function processInQueue()
	for targetId, targetData in targetsData do
		-- Each target gets its own pcall in case there are errors or malicious users are tampering with the payload
		pcall(function()
			local queue = incomingQueue[targetId]

			while not queue:isEmpty() do
				local dataDetails = queue:pop()

				local dataBuffer = dataDetails.Buffer
				local usedInstances = dataDetails.UsedInstances

				local payloadIndex = 1
				local offset = 0
				local bufferLen = buffer.len(dataBuffer)

				while offset < bufferLen do
					local eventId = buffer.readu8(dataBuffer, offset)
					local bufferSize = buffer.readu16(dataBuffer, offset + 1)
					offset += 3

					-- TODO: What if eventId is something we don't know - should not be possible
					if not targetData.RemoteKnowledge[eventId] then
						offset += bufferSize
						continue
					end

					local eventName = eventIdMap.FromIdToName[eventId]
					local eventData = events[eventName]

					local payloadBuffer = buffer.create(bufferSize)
					buffer.copy(payloadBuffer, 0, dataBuffer, offset, bufferSize)

					local reader = BufferReader.interface.fromBuffer(payloadBuffer)

					-- Map the instances
					if usedInstances then
						local payloadInstances = usedInstances[tostring(payloadIndex)]
						if payloadInstances then
							reader.UsedInstances = payloadInstances
						end
					end

					local success, results = pcall(function()
						return table.pack(eventData.Deserializer(reader))
					end)

					if success then
						if IS_SERVER then
							eventData.Server:Fire(targetData.Player :: Player, table.unpack(results))
						else
							eventData.Client:Fire(table.unpack(results))
						end
					elseif RunService:IsStudio() then
						-- Printing is expensive so we wanna only warn about payload issues in studio,
						--  otherwise if there are exploiters then we just get spam in the console about them
						--  messing with the payload.
						warn("A problem ocurred while trying to decode the payload.")
						warn(results)
					end

					offset += bufferSize
					payloadIndex += 1
				end
			end
		end)
	end
end

local function processOutQueue()
	for targetId, targetData in targetsData do
		pcall(function()
			local queue = outgoingQueue[targetId]
			local internalQueue = internalOutgoingQueue[targetId]
			if internalQueue:isEmpty() and queue:isEmpty() then
				return
			end

			local outgoingData = {}
			local totalDataSize = 0
			local internalBreakHappened = false

			while totalDataSize < MESSAGE_SIZE_LIMIT and not internalQueue:isEmpty() do
				local outData = internalQueue:peek()

				local payloadSize = buffer.len(outData.Payload)
				if (totalDataSize + payloadSize) > MESSAGE_SIZE_LIMIT then
					internalBreakHappened = true
					break -- we are breaking in order to keep the correct ordering of messages
				end

				internalQueue:pop()

				totalDataSize += 3 -- metadata overhead
				totalDataSize += payloadSize
				table.insert(outgoingData, outData)
			end

			while not internalBreakHappened and totalDataSize < MESSAGE_SIZE_LIMIT and not queue:isEmpty() do
				local outData = queue:peek()

				-- The target doesn't know yet how to interpret the payload
				if not targetData.RemoteKnowledge[outData.Id] then
					break -- we are breaking in order to keep the correct ordering of messages
				end

				local payloadSize = buffer.len(outData.Payload)
				if (totalDataSize + payloadSize) > MESSAGE_SIZE_LIMIT then
					break -- we are breaking in order to keep the correct ordering of messages
				end

				queue:pop()

				totalDataSize += 3 -- metadata overhead
				totalDataSize += payloadSize
				table.insert(outgoingData, outData)
			end

			if totalDataSize <= 0 then
				return
			end

			local outBuffer = buffer.create(totalDataSize)
			local usedInstances = nil

			local cursorOffset = 0
			for dataIndex, outData in outgoingData do
				local dataSize = buffer.len(outData.Payload)

				buffer.writeu8(outBuffer, cursorOffset, outData.Id)
				buffer.writeu16(outBuffer, cursorOffset + 1, dataSize)
				buffer.copy(outBuffer, cursorOffset + PAYLOAD_METADATA_OVERHEAD, outData.Payload, 0, dataSize)

				if outData.UsedInstances then
					if not usedInstances then
						usedInstances = {}
					end

					usedInstances[tostring(dataIndex)] = outData.UsedInstances
				end

				cursorOffset += dataSize + PAYLOAD_METADATA_OVERHEAD
			end

			if targetId ~= 0 then
				ReliableEvent:FireClient(targetData.Player :: Player, outBuffer, usedInstances)
			else
				ReliableEvent:FireServer(outBuffer, usedInstances)
			end
		end)
	end
end

internalEvent = createEvent("__BOLT_INTERNAL", function(writer, data: any)
	if not data then
		return
	end

	if data.Type == "Ready" then
		writer:WriteU8(0)
	elseif data.Type == "EventDetailsReceived" then
		writer:WriteU8(1)
		writer:WriteU8(data.Id)
	elseif data.Type == "EventDetails" then
		writer:WriteU8(2)
		writer:WriteU8(data.Id)
		writer:WriteString(data.Name)
	end
end, function(reader)
	local dataType = reader:ReadU8()

	if dataType == 0 then
		return {
			Type = "Ready",
		}
	elseif dataType == 1 then
		return {
			Type = "EventDetailsReceived",
			Id = reader:ReadU8(),
		}
	elseif dataType == 2 then
		return {
			Type = "EventDetails",
			Id = reader:ReadU8(),
			Name = reader:ReadString(),
		}
	end

	return nil
end)

local Bolt = {
	BufferReader = BufferReader.interface,
	BufferWriter = BufferWriter.interface,
}

--[[
	TODO: Write description
]]
function Bolt.ReliableEvent<T...>(
	eventName: string,
	serializer: ((writer: BufferWriter, T...) -> ())?,
	deserializer: ((reader: BufferReader) -> T...)?
): ReliableEvent<T...>
	local event = createEvent(eventName, serializer, deserializer) :: any

	if IS_SERVER then
		internalEvent:FireAllClients({
			Type = "EventDetails",
			Name = eventName,
			Id = events[eventName].Id,
		})
	end

	return event
end

--[[
	TODO: Write description
]]
function Bolt.RemoteProperty<T>(
	propertyName: string,
	defaultValue: T,
	serializer: ((writer: BufferWriter, T) -> ())?,
	deserializer: ((reader: BufferReader) -> T)?
): RemoteProperty<T>
	local propertyEvent = Bolt.ReliableEvent(`__P{propertyName}`, serializer, deserializer) :: ReliableEvent<...any>

	local masterValue = defaultValue
	local targetValue = {}
	local observers = {} :: { (value: T) -> () }

	local function triggerObservers()
		for _, callback in observers do
			callback(cloneValue(masterValue))
		end
	end

	if not IS_SERVER then
		propertyEvent.OnClientEvent:Connect(function(value)
			if areValuesEqual(masterValue, value) then
				return
			end

			masterValue = value

			triggerObservers()
		end)
		propertyEvent:FireServer()
	else
		propertyEvent.OnServerEvent:Connect(function(player)
			propertyEvent:FireClient(player, targetValue[player] or masterValue)
		end)

		Players.PlayerRemoving:Connect(function(player)
			targetValue[player] = nil
		end)
	end

	return {
		Observe = function(_self: RemoteProperty<T>, callback: (value: T) -> ())
			table.insert(observers, callback)

			callback(cloneValue(masterValue))

			return function()
				local callbackIndex = table.find(observers, callback)
				if not callbackIndex then
					return
				end

				table.remove(observers, callbackIndex)
			end
		end,
		Get = function(_self: RemoteProperty<T>)
			return cloneValue(masterValue)
		end,
		GetFor = function(_self: RemoteProperty<T>, player: Player): T
			return cloneValue(targetValue[player] ~= nil and targetValue[player] or masterValue)
		end,
		Set = function(_self: RemoteProperty<T>, newValue: T)
			assert(IS_SERVER, "Cannot set a remote property value from client side")

			if areValuesEqual(masterValue, newValue) then
				return
			end

			masterValue = cloneValue(newValue)
			deepFreezeValue(masterValue)

			targetValue = {}

			propertyEvent:FireAllClients(masterValue)
			triggerObservers()
		end,
		SetFor = function(_self: RemoteProperty<T>, player: Player, newValue: T)
			assert(IS_SERVER, "Cannot set a remote property value from client side")

			if not player.Parent then
				return
			end

			if targetValue[player] and areValuesEqual(targetValue[player], newValue) then
				return
			elseif not targetValue[player] and areValuesEqual(masterValue, newValue) then
				return
			end

			local newValueClone = cloneValue(newValue)
			deepFreezeValue(newValueClone)

			targetValue[player] = newValueClone

			propertyEvent:FireClient(player, newValueClone == nil and masterValue or newValueClone)
		end,
		ClearFor = function(_self: RemoteProperty<T>, player: Player)
			assert(IS_SERVER, "Cannot set a remote property value from client side")

			if not player.Parent then
				return
			end

			if not targetValue[player] then
				return
			end

			local oldValue = targetValue[player]

			targetValue[player] = nil

			if areValuesEqual(masterValue, oldValue) then
				return
			end

			propertyEvent:FireClient(player, masterValue)
		end,
	}
end

function Bolt.RemoteFunction<T..., R...>(functionName: string): RemoteFunction<T..., R...>
	local functionEvent = Bolt.ReliableEvent(`__F{functionName}`)

	local remoteFunction = {
		InvokeServer = function(_self: RemoteFunction<T..., R...>, ...: T...)
			local guid = HttpService:GenerateGUID(false)

			local returnData

			local connection: SignalConnection?
			connection = functionEvent.OnClientEvent:Connect(function(returnGuid, ...)
				if returnGuid ~= guid then
					return
				end

				returnData = table.pack(...)

				if connection then
					connection:Disconnect()
					connection = nil
				end
			end)
			functionEvent:FireServer(guid, ...)

			while connection do
				task.wait()
			end

			return table.unpack(returnData)
		end,
		OnServerInvoke = function(player: Player, ...: T...): R...
			error(`OnServerInvoke not overwritten for '{functionName}'`)
		end,
	}

	if RunService:IsServer() then
		functionEvent.OnServerEvent:Connect(function(player, guid, ...)
			local returnValue = table.pack(remoteFunction.OnServerInvoke(player, ...))

			functionEvent:FireClient(player, guid, table.unpack(returnValue))
		end)
	end

	return remoteFunction
end

if IS_SERVER then
	Players.PlayerAdded:Connect(function(player)
		createTarget(player.UserId, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		removeTarget(player.UserId)
	end)

	-- Instead of using RunService.Heartbeat directly, we spawn a new thread and execute the functions
	--  then we yield and wait for Heartbeat, the reason being that we want the two functions to finish before
	--  we wait for another heartbeat, this way we make sure there is no two functions working on the same piece
	--  of data.
	task.spawn(function()
		while true do
			processOutQueue()
			processInQueue()
			RunService.Heartbeat:Wait()
		end
	end)

	ReliableEvent.OnServerEvent:Connect(
		function(player: Player, inData: buffer, inInstances: { [string]: { Instance } }?)
			local playerId = player.UserId

			if not targetsData[playerId] then
				return
			end

			if typeof(inData) ~= "buffer" or (inInstances and typeof(inInstances) ~= "table") then
				return
			end

			if buffer.len(inData) > MESSAGE_SIZE_LIMIT + PAYLOAD_METADATA_OVERHEAD then
				return
			end

			incomingQueue[playerId]:push({
				Buffer = inData,
				UsedInstances = inInstances,
			})
		end
	)

	internalEvent.OnServerEvent:Connect(function(player, event)
		if not event then
			return
		end

		local targetData = targetsData[player.UserId]
		if not targetData then
			return
		end

		if event.Type == "Ready" then
			local remoteKnowledge = targetsData[player.UserId].RemoteKnowledge

			for eventName, event in events do
				if event.Id and remoteKnowledge[event.Id] then
					continue
				end

				internalEvent:FireClient(player, {
					Type = "EventDetails",
					Name = eventName,
					Id = event.Id,
				})
			end
		elseif event.Type == "EventDetailsReceived" then
			local eventDetails = event :: InternalEvent_EventDetailsReceived

			if targetData.RemoteKnowledge[eventDetails.Id] then
				return
			end

			targetData.RemoteKnowledge[eventDetails.Id] = true
		end
	end)

	for _, player in Players:GetPlayers() do
		createTarget(player.UserId, player)
	end
else
	internalEvent.OnClientEvent:Connect(function(event)
		if not event then
			return
		end

		if event.Type == "EventDetails" then
			local data: InternalEvent_EventDetails = event :: InternalEvent_EventDetails

			eventIdMap.FromIdToName[data.Id] = data.Name
			eventIdMap.FromNameToId[data.Name] = data.Id
			targetsData[0].RemoteKnowledge[data.Id] = true

			internalEvent:FireServer({
				Type = "EventDetailsReceived",
				Id = data.Id,
			})
		end
	end)

	ReliableEvent.OnClientEvent:Connect(function(inData: buffer, inInstances: { [string]: { Instance } }?)
		if typeof(inData) ~= "buffer" then
			return
		end

		incomingQueue[0]:push({
			Buffer = inData,
			UsedInstances = inInstances,
		})
	end)

	-- Instead of using RunService.Heartbeat directly, we spawn a new thread and execute the functions
	--  then we yield and wait for Heartbeat, the reason being that we want the two functions to finish before
	--  we wait for another heartbeat, this way we make sure there is no two functions working on the same piece
	--  of data.
	task.spawn(function()
		while true do
			processOutQueue()
			processInQueue()
			RunService.Heartbeat:Wait()
		end
	end)

	-- Default internal event
	createTarget(0)
	eventIdMap.FromIdToName[0] = "__BOLT_INTERNAL"
	eventIdMap.FromNameToId["__BOLT_INTERNAL"] = 0

	internalEvent:FireServer({
		Type = "Ready",
	})
end

return Bolt
