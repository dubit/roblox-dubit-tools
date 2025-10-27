--!strict
--!native

export type BufferReader = {
	Buffer: buffer,
	Offset: number,

	Readb8: (self: BufferReader) -> { boolean },

	Readi8: (self: BufferReader) -> number,
	Readi16: (self: BufferReader) -> number,
	Readi24: (self: BufferReader) -> number,

	Readu8: (self: BufferReader) -> number,
	Readu16: (self: BufferReader) -> number,
	Readu24: (self: BufferReader) -> number,
	Readu32: (self: BufferReader) -> number,
	Readu40: (self: BufferReader) -> number,
	Readu56: (self: BufferReader) -> number,

	Readf32: (self: BufferReader) -> number,
	Readf64: (self: BufferReader) -> number,

	ReadString: (self: BufferReader, count: number) -> string,
	ReadVarLenString: (self: BufferReader) -> string,

	new: (size: number) -> BufferReader,
}

local BufferReader = {}
BufferReader.prototype = {}
BufferReader.interface = {}

function BufferReader.prototype.Readb8(self: BufferReader)
	local bools = table.create(8, false)

	local byte = buffer.readu8(self.Buffer, self.Offset)
	for i = 0, 7 do
		-- selene: allow(undefined_variable)
		bools[i + 1] = bit32.band(byte, bit32.lshift(1, i)) ~= 0
	end
	self.Offset += 1

	return bools
end

function BufferReader.prototype.Readu8(self: BufferReader)
	local v = buffer.readu8(self.Buffer, self.Offset)
	self.Offset += 1
	return v
end

function BufferReader.prototype.Readu16(self: BufferReader)
	local v = buffer.readu16(self.Buffer, self.Offset)
	self.Offset += 2
	return v
end

function BufferReader.prototype.Readu24(self: BufferReader)
	local v = bit32.bor(
		bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 2), 16),
		bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 1), 8),
		buffer.readu8(self.Buffer, self.Offset)
	)

	self.Offset += 3
	return v
end

function BufferReader.prototype.Readu32(self: BufferReader)
	local v = buffer.readu32(self.Buffer, self.Offset)
	self.Offset += 4
	return v
end

function BufferReader.prototype.Readu40(self: BufferReader)
	-- modulo operator is needed in this case as bit32.lshift has a range of [-31..31]
	-- selene: allow(undefined_variable)
	local v = (buffer.readu8(self.Buffer, self.Offset + 4) * 2 ^ 32)
		-- selene: allow(undefined_variable)
		+ (bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 3), 24))
		-- selene: allow(undefined_variable)
		+ (bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 2), 16))
		-- selene: allow(undefined_variable)
		+ (bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 1), 8))
		-- selene: allow(undefined_variable)
		+ buffer.readu8(self.Buffer, self.Offset)

	self.Offset += 5
	return v
end

function BufferReader.prototype.Readu56(self: BufferReader)
	-- The actual value of 2^56 is 72057594037927940 but Luau doesn't have enough precision to represent such number
	--  so we limit it at 2^54 which is 18014398509481984 as this number can be represented by Luau
	-- The reason why I haven't changed the method name is because we are writing 56 bit number but Luau just cannot represent it
	local low = buffer.readu32(self.Buffer, self.Offset)
	self.Offset += 4

	local high = BufferReader.prototype.Readu24(self)

	return high * 4294967296 + low
end

function BufferReader.prototype.Readi8(self: BufferReader)
	local v = buffer.readi8(self.Buffer, self.Offset)
	self.Offset += 1
	return v
end

function BufferReader.prototype.Readi16(self: BufferReader)
	local v = buffer.readi16(self.Buffer, self.Offset)
	self.Offset += 2
	return v
end

function BufferReader.prototype.Readi24(self: BufferReader)
	local v = bit32.bor(
		bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 2), 16),
		bit32.lshift(buffer.readu8(self.Buffer, self.Offset + 1), 8),
		buffer.readu8(self.Buffer, self.Offset)
	)

	if bit32.band(v, 0x800000) ~= 0 then
		v = v - 0x1000000
	end

	self.Offset += 3
	return v
end

function BufferReader.prototype.Readi32(self: BufferReader)
	local v = buffer.readi32(self.Buffer, self.Offset)
	self.Offset += 4
	return v
end

function BufferReader.prototype.Readf32(self: BufferReader)
	local v = buffer.readf32(self.Buffer, self.Offset)
	self.Offset += 4
	return v
end

function BufferReader.prototype.Readf64(self: BufferReader)
	local v = buffer.readf64(self.Buffer, self.Offset)
	self.Offset += 8
	return v
end

function BufferReader.prototype.ReadString(self: BufferReader, count: number)
	local v = buffer.readstring(self.Buffer, self.Offset, count)
	self.Offset += count
	return v
end

-- the purpose of this Variable Length string is to not have to worry about saving the string length argument
--  one thing to note tho it is meant to be used with strings that have up to 254 characters
function BufferReader.prototype.ReadVarLenString(self: BufferReader)
	local stringLen = buffer.readu8(self.Buffer, self.Offset)
	local v = buffer.readstring(self.Buffer, self.Offset + 1, stringLen)
	self.Offset += stringLen + 1
	return v
end

function BufferReader.interface.new(buffer: buffer): BufferReader
	return setmetatable(
		{
			Buffer = buffer,
			Offset = 0,
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
			Offset = 0,
		} :: any,
		{
			__index = BufferReader.prototype,
		}
	)
end

return BufferReader.interface
