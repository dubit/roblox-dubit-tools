--!strict
--!native

export type BufferWriter = {
	Buffer: buffer,
	Offset: number,

	Writeb8: (self: BufferWriter, ...boolean) -> (),

	Writei8: (self: BufferWriter, value: number) -> (),
	Writei16: (self: BufferWriter, value: number) -> (),
	Writei24: (self: BufferWriter, value: number) -> (),

	Writeu8: (self: BufferWriter, value: number) -> (),
	Writeu16: (self: BufferWriter, value: number) -> (),
	Writeu24: (self: BufferWriter, value: number) -> (),
	Writeu32: (self: BufferWriter, value: number) -> (),
	Writeu40: (self: BufferWriter, value: number) -> (),
	Writeu56: (self: BufferWriter, value: number) -> (),

	Writef32: (self: BufferWriter, value: number) -> (),
	Writef64: (self: BufferWriter, value: number) -> (),

	WriteString: (self: BufferWriter, value: string, count: number) -> (),
	WriteVarLenString: (self: BufferWriter, value: string) -> (),

	Fit: (self: BufferWriter) -> (),

	new: (size: number) -> BufferWriter,
}

local BufferWriter = {}
BufferWriter.prototype = {}
BufferWriter.interface = {}

function BufferWriter.prototype.Fit(self: BufferWriter)
	local resizedBuffer = buffer.create(self.Offset)
	buffer.copy(resizedBuffer, 0, self.Buffer, 0, self.Offset)
	self.Buffer = resizedBuffer
end

function BufferWriter.prototype.Writeb8(self: BufferWriter, ...)
	local args = { ... }
	assert(#args <= 8, "writeb8 allows only up to 8 booleans to be written")

	local byte = 0
	for i = 0, #args - 1 do
		assert(type(args[i + 1]) == "boolean", "writeb8 only allows booleans to be written")
		byte = bit32.bor(byte, bit32.lshift((args[i + 1] and 1 or 0), i))
	end
	buffer.writeu8(self.Buffer, self.Offset, byte)
	self.Offset += 1
end

function BufferWriter.prototype.Writeu8(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 255, "number is out of range [0..255]")

	buffer.writeu8(self.Buffer, self.Offset, value)
	self.Offset += 1
end

function BufferWriter.prototype.Writeu16(self: BufferWriter, value: number)
	assert(value >= 0 and value < 65536, "number is out of range [0..65,536]")

	buffer.writeu16(self.Buffer, self.Offset, value)
	self.Offset += 2
end

function BufferWriter.prototype.Writeu24(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 16777215, "number is out of range [0..16,777,215]")

	buffer.writeu8(self.Buffer, self.Offset, bit32.band(value, 0xFF))
	buffer.writeu8(self.Buffer, self.Offset + 1, bit32.band(bit32.rshift(value, 8), 0xFF))
	buffer.writeu8(self.Buffer, self.Offset + 2, bit32.band(bit32.rshift(value, 16), 0xFF))

	self.Offset += 3
end

function BufferWriter.prototype.Writeu32(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 4294967296, "number is out of range [0..4,294,967,296]")

	buffer.writeu32(self.Buffer, self.Offset, value)
	self.Offset += 4
end

function BufferWriter.prototype.Writeu40(self: BufferWriter, value: number)
	assert(value >= 0 and value <= 1099511627775, "number is out of range [0..1,099,511,627,775]")

	for i = 0, 4 do
		buffer.writeu8(self.Buffer, self.Offset + i, bit32.band(value, 0xFF))
		-- modulo operator and floor is needed in this case as bit32.rshift has a range of [-31..31]
		value = math.floor(value / 2 ^ 8)
	end
	self.Offset += 5
end

function BufferWriter.prototype.Writeu56(self: BufferWriter, value: number)
	-- The actual value of 2^56 is 72057594037927940 but Luau doesn't have enough precision to represent such number
	--  so we limit it at 2^54 which is 18014398509481984 as this number can be represented by Luau
	-- The reason why I haven't changed the method name is because we are writing 56 bit number but Luau just cannot represent it
	assert(value >= 0 and value <= 18014398509481984, "number is out of range [0..18,014,398,509,481,984]")

	buffer.writeu32(self.Buffer, self.Offset, value % 4294967296)
	self.Offset += 4

	BufferWriter.prototype.Writeu24(self, math.floor(value / 4294967296))
end

function BufferWriter.prototype.Writei8(self: BufferWriter, value: number)
	assert(value >= -128 and value <= 127, "number is out of range [-128..127]")

	buffer.writei8(self.Buffer, self.Offset, value)
	self.Offset += 1
end

function BufferWriter.prototype.Writei16(self: BufferWriter, value: number)
	assert(value >= -32768 and value <= 32767, "number is out of range [-32,768..32,767]")

	buffer.writei16(self.Buffer, self.Offset, value)
	self.Offset += 2
end

function BufferWriter.prototype.Writei24(self: BufferWriter, value: number)
	assert(value >= -8388608 and value <= 8388607, "number is out of range [-8,388,608..8,388,607]")

	-- if the value is negative, convert it to two's complement form
	if value < 0 then
		value = 0x1000000 + value
	end

	buffer.writeu8(self.Buffer, self.Offset, bit32.band(value, 0xFF))
	buffer.writeu8(self.Buffer, self.Offset + 1, bit32.band(bit32.rshift(value, 8), 0xFF))
	buffer.writeu8(self.Buffer, self.Offset + 2, bit32.band(bit32.rshift(value, 16), 0xFF))

	self.Offset += 3
end

function BufferWriter.prototype.Writei32(self: BufferWriter, value: number)
	assert(value >= -2147483648 and value <= 2147483647, "number is out of range [-2,147,483,648..2,147,483,647]")

	buffer.writei8(self.Buffer, self.Offset, value)
	self.Offset += 4
end

function BufferWriter.prototype.Writef32(self: BufferWriter, value: number)
	buffer.writef32(self.Buffer, self.Offset, value)
	self.Offset += 4
end

function BufferWriter.prototype.Writef64(self: BufferWriter, value: number)
	buffer.writef64(self.Buffer, self.Offset, value)
	self.Offset += 8
end

function BufferWriter.prototype.WriteString(self: BufferWriter, value: string, count: number)
	buffer.writestring(self.Buffer, self.Offset, value, count)
	self.Offset += count
end

-- the purpose of this Variable Length string is to not have to worry about saving the string length argument
--  one thing to note tho it is meant to be used with strings that have up to 254 characters
function BufferWriter.prototype.WriteVarLenString(self: BufferWriter, value: string)
	local stringLen = string.len(value)
	buffer.writeu8(self.Buffer, self.Offset, stringLen)
	buffer.writestring(self.Buffer, self.Offset + 1, value, stringLen)
	self.Offset += stringLen + 1
end

function BufferWriter.interface.new(size: number): BufferWriter
	return setmetatable(
		{
			Buffer = buffer.create(size),
			Offset = 0,
		} :: any,
		{
			__index = BufferWriter.prototype,
		}
	)
end

function BufferWriter.interface.fromString(value: string): BufferWriter
	return setmetatable(
		{
			Buffer = buffer.fromstring(value),
			Offset = 0,
		} :: any,
		{
			__index = BufferWriter.prototype,
		}
	)
end

return BufferWriter.interface
