local STRINGIFY_DEFAULTS = table.freeze({
	numSpaces = 4,
	useSemiColon = ",",
	depth = 1,
})

local Table = {}

function Table.construct<T>(constructingFunction: () -> T): T
	local result = constructingFunction()
	assert(typeof(result) == "table", "Table.construct expects the returned value to be a table")

	return result
end

function Table.compare<A, B>(source: A, other: B)
	if typeof(source) ~= "table" or typeof(other) ~= "table" then
		return source == other
	end

	-- If either or both tables are an array then it will be the quickest method to determine if they are different
	if #source ~= #other then
		return false
	end

	for key, value in source do
		if other[key] ~= value then
			return false
		end
	end

	for key, value in other do
		if source[key] ~= value then
			return false
		end
	end

	return true
end

function Table.compareDeep<A, B>(source: A, other: B)
	if typeof(source) ~= "table" or typeof(other) ~= "table" then
		return source == other
	end

	-- If either or both tables are an array then it will be the quickest method to determine if they are different
	if #source ~= #other then
		return false
	end

	for key, value in source do
		if not Table.compareDeep(value, other[key]) then
			return false
		end
	end

	for key, value in other do
		if not Table.compareDeep(value, source[key]) then
			return false
		end
	end

	return true
end

function Table.deepFreeze<T>(tbl: T): T
	assert(type(tbl) == "table", "First argument expected to be type of table")

	table.freeze(tbl)
	for _, value: any in tbl do
		if typeof(value) == "table" then
			Table.deepFreeze(value)
		end
	end

	return tbl
end

function Table.deepClone<T>(tbl: T): T
	assert(type(tbl) == "table", "First argument expected to be type of table")

	local newTbl = table.clone(tbl)
	for key: any, value: any in tbl do
		if typeof(value) == "table" then
			newTbl[key] = Table.deepClone(value)
		end
	end

	return newTbl
end

function Table.merge<T, O>(sourceTbl: T, otherTbl: O): T & O
	assert(type(sourceTbl) == "table", "First argument expected to be type of table")
	assert(type(otherTbl) == "table", "Second argument expected to be type of table")

	local newTbl = Table.deepClone(sourceTbl)
	for key: any, value: any in otherTbl do
		if typeof(value) == "table" then
			newTbl[key] = Table.deepClone(value)
		else
			newTbl[key] = value
		end
	end

	return newTbl
end

function Table.getRandomDictionaryEntry(dictionary: { [any]: any }): { Key: any, Value: any }
	local keys: { [number]: any } = {}
	for key in dictionary do
		table.insert(keys, key)
	end

	local randomKey = keys[math.random(#keys)]
	return { Key = randomKey, Value = dictionary[randomKey] }
end

function Table.stringify(
	tableBase: { any },
	options: { spaces: number?, usesemicolon: boolean?, depth: number? }?
): string
	if type(tableBase) ~= "table" then
		return tostring(tableBase)
	elseif not next(tableBase) then
		return "{}"
	end

	if not options then
		options = {
			numSpaces = STRINGIFY_DEFAULTS.numSpaces,
			useSemiColon = STRINGIFY_DEFAULTS.useSemiColon,
			depth = STRINGIFY_DEFAULTS.depth,
		}
	else
		if not options.numSpaces then
			options.numSpaces = 4
		end
		if not options.useSemiColon then
			options.useSemiColon = ","
		end
		if not options.depth then
			options.depth = 1
		end
	end

	local space = (" "):rep(options.depth * options.numSpaces)
	local sep = options.useSemiColon and ";" or ","
	local stringBuilder = { "{" }

	for tableKey, tableValue in next, tableBase do
		table.insert(
			stringBuilder,
			("\n%s[%s] = %s%s"):format(
				space,
				type(tableKey) == "number" and tostring(tableKey) or ('"%s"'):format(tostring(tableKey)),
				Table.stringify(tableValue, options),
				sep
			)
		)
	end

	local generatedString = table.concat(stringBuilder)
	local finalString = ("%s\n%s}"):format(generatedString:sub(1, -2), space:sub(1, -options.numSpaces - 1))

	return finalString
end

return Table
