--[=[
	@class DubitUtils.Number
]=]

local NUMBER_ABBREVIATIONS = table.freeze({
	["N"] = 10 ^ 30,
	["O"] = 10 ^ 27,
	["Sp"] = 10 ^ 24,
	["Sx"] = 10 ^ 21,
	["Qn"] = 10 ^ 18,
	["Qd"] = 10 ^ 15,
	["T"] = 10 ^ 12,
	["B"] = 10 ^ 9,
	["M"] = 10 ^ 6,
	["K"] = 10 ^ 3,
})

local Number = {}

--[=[
	Linearly interpolates between valueA and valueB by time.

	When time = 0 returns a
	When time = 1 return b
	When time = 0.5 returns the midpoint of a and b

	The time value isn't clamped!

	```lua
	print(DubitUtils.Number.lerp(1.00, 2.00, 0.50)) -- will print '1.50'
	print(DubitUtils.Number.lerp(0.00, 1.00, 0.70)) -- will print '0.70'
	print(DubitUtils.Number.lerp(15.00, 30.00, 0.20)) -- will print '18.00'
	print(DubitUtils.Number.lerp(0.00, 1.00, 2.00)) -- will print '2.00'
	```

	@method lerp
	@within DubitUtils.Number

	@param valueA number
	@param valueB number
	@param time number

	@return number
]=]
--
function Number.lerp(valueA: number, valueB: number, time: number): number
	return valueA + (valueB - valueA) * time
end

--[=[
	Adds trailing zeros preceding the given number until it is at least the given length of digits.
	
	@within DubitUtils.Number

	@param numberToFormat number -- The number to format with trailing zeros
	@param minimumDigitLength number -- The minimum number of digits which the formatted number must be

	@return string -- The formatted number, as a string

	#### Example Usage

	```lua
	DubitUtils.Number.formatDigitLength(48, 4) -- Will print 0048
	```

	:::note
	Calling 'tonumber' on the returned string will remove the 0s added by this function.
	:::
]=]
function Number.formatDigitLength(numberToFormat: number, minimumDigitLength: number): string
	local flooredNumber = math.floor(tonumber(numberToFormat) or 0)
	local formattedNumber = tostring(flooredNumber)

	while #formattedNumber < minimumDigitLength do
		formattedNumber = "0" .. formattedNumber
	end

	return formattedNumber
end

--[=[
	Rounds a given number to the nearest multiple of the given 'roundTo' number.
	
	@within DubitUtils.Number

	@param numberToRound number -- The number to round
	@param roundTo number -- The number of which numberToRound will be rounded to a multiple of

	@return number -- The rounded number

	#### Example Usage

	```lua
	DubitUtils.Number.roundToNearest(37, 5) -- Will print 35
	```
]=]
function Number.roundToNearest(numberToRound: number, roundTo: number): number
	local plusHalfRange = numberToRound + (roundTo / 2)
	local result = plusHalfRange - plusHalfRange % roundTo

	return result
end

--[=[
	Abbreviates the given number with a large number notation,
	depending on the nearest power of one thousand lower than it, up to 10 ^ 30 ("N").
	
	@within DubitUtils.Number

	@param numberToAbbreviate number -- The number to abbreviate
	@param includePlusSymbol boolean? -- Whether to include the '+' symbol when the result is higher than the appropriate power of 1000. Defaults to 'true'.
	@param decimals number? -- The number of decimal places to include in the result. Defaults to '0'.

	@return string -- The abbreviated number, appended with the appropriate notation

	#### Example Usage

	```lua
	DubitUtils.Number.abbreviate(372) -- Will print 372
	DubitUtils.Number.abbreviate(59678) -- Will print 59K+
	DubitUtils.Number.abbreviate(59678, false) -- Will print 59K
	DubitUtils.Number.abbreviate(1000000000) -- Will print 1B
	DubitUtils.Number.abbreviate(4967827362967902) -- Will print 4Qd+
	DubitUtils.Number.abbreviate(4967827362967902, true, 2) -- Will print 4.96Qd+
	```

	:::note
	This function has no effect if the given number is less than 1000, it will simply return the given number as a string
	:::
]=]
function Number.abbreviate(numberToAbbreviate: number, includePlusSymbol: boolean?, decimals: number?): string
	local abbreviatedNumber = tostring(numberToAbbreviate)
	local chosenAbbreviatonValue = 0

	includePlusSymbol = if typeof(includePlusSymbol) == "boolean" then includePlusSymbol else true
	local decimalNumbers = if typeof(decimals) == "number" then decimals else 0

	for abbreviation, abbreviationValue in NUMBER_ABBREVIATIONS do
		if numberToAbbreviate >= abbreviationValue and abbreviationValue > chosenAbbreviatonValue then
			local shortNumber = numberToAbbreviate / abbreviationValue

			-- We want to floor the decimal part (i.e. 59,678 returns 59.6K, not 59.7K)
			shortNumber = math.floor(shortNumber * 10 ^ decimalNumbers) / 10 ^ decimalNumbers

			includePlusSymbol = includePlusSymbol and numberToAbbreviate > abbreviationValue or false
			abbreviatedNumber = string.format("%." .. decimalNumbers .. "f", shortNumber)
				.. abbreviation
				.. (includePlusSymbol and "+" or "")
			chosenAbbreviatonValue = abbreviationValue
		end
	end

	return abbreviatedNumber
end

--[[
	Separate the given number with commas every three digits to make the number more human-readable.

	@within DubitUtils.Number

	@param numberToSeparate number -- The number to separate with commas

	@return string -- The separated number, as a string

	#### Example Usage

	```lua
	DubitUtils.Number.commaSeparate(528) -- Will print 528
	DubitUtils.Number.commaSeparate(59678) -- Will print 59,678
	DubitUtils.Number.commaSeparate(1000000000) -- Will print 1,000,000,000
	```

	:::note
	This function has no effect if the given number is less than 1000, it will simply return the given number as a string
	:::
]]
function Number.commaSeparate(numberToSeparate: number): string
	local formattedNumber = tostring(numberToSeparate)
	local isNegative = formattedNumber:sub(1, 1) == "-"
	formattedNumber = isNegative and formattedNumber:sub(2) or formattedNumber

	local integerPart, decimalPart = formattedNumber:match("([^%.]*)(%.?.*)")
	local length = #integerPart
	local result = ""

	for i = 1, length do
		local char = string.sub(integerPart, i, i)
		result = result .. char

		if (length - i) % 3 == 0 and i < length then
			result = result .. ","
		end
	end

	if decimalPart and #decimalPart > 0 then
		result = result .. decimalPart
	end

	return (isNegative and "-" or "") .. result
end

return Number
