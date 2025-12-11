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

function Number.roundToNearest(numberToRound: number, roundTo: number): number
	local plusHalfRange = numberToRound + (roundTo / 2)
	local result = plusHalfRange - plusHalfRange % roundTo

	return result
end

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
			abbreviatedNumber =
				string.format(`%.{decimalNumbers}f%s%s`, shortNumber, abbreviation, includePlusSymbol and "+" or "")

			chosenAbbreviatonValue = abbreviationValue
		end
	end

	return abbreviatedNumber
end

function Number.commaSeparate(numberToSeparate: number): string
	local formattedNumber = tostring(numberToSeparate)
	local isNegative = numberToSeparate < 0
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
