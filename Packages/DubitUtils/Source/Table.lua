--[=[
	@class DubitUtils.Table
]=]

local STRINGIFY_DEFAULTS = {
	numSpaces = 4,
	useSemiColon = ",",
	depth = 1,
}
table.freeze(STRINGIFY_DEFAULTS)

local Table = {}

--[[
	Construct a table from a given function.

	```lua
	local COLOR_PALETTE = DubitUtils.Table.construct(function()
		local hexColors = { "#FF0000", "#00FF00", "#0000FF" }
		local colors = {}
		for i, hex in hexColors do
			colors[i] = Color3.fromHex(hex)
		end
		return colors
	end)
	```

	@method construct
	@within DubitUtils.Table

	@param constructingFunction -- The function that constructs the table.

	@return Table -- The constructed table.
]]
function Table.construct<T>(constructingFunction: () -> T): T
	return constructingFunction()
end

--[=[
	This function roughly (It won't traverse other tables) compares two tables, both arrays and dictionaries are supported.

	Cyclical References not supported.

	```lua
	local tbl_one = { test = true }
	local tbl_two = { test = true, hello = "world" }
	DubitUtils.Table.compare(tbl) -- false

	local tbl_one = { test = true }
	local tbl_two = { test = true }
	DubitUtils.Table.compare(tbl) -- true


	local tbl_one = { test = true, nested = { foo = "bar" } }
	local tbl_two = { test = true, nested = { foo = "bar" } }
	DubitUtils.Table.compare(tbl) -- false, the table entries are roughly compared, both values of nested fields point to different tables
	```

	@method compare
	@within DubitUtils.Table

	@param source { [any]: any }
	@param other { [any]: any }
]=]
--
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

--[=[
	This function deeply compares two tables, both arrays and dictionaries are supported.

	Cyclical References not supported.

	```lua
	local tbl_one = { test = true }
	local tbl_two = { test = true, hello = "world" }
	DubitUtils.Table.compareDeep(tbl) -- false

	local tbl_one = { test = true }
	local tbl_two = { test = true }
	DubitUtils.Table.compareDeep(tbl) -- true


	local tbl_one = { test = true, nested = { foo = "bar" } }
	local tbl_two = { test = true, nested = { foo = "bar" } }
	DubitUtils.Table.compareDeep(tbl) -- true
	```

	@method compareDeep
	@within DubitUtils.Table

	@param source { [any]: any }
	@param other { [any]: any }
]=]
--
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

--[=[
	This function deep freezes the table making it read only.

	Cyclical References not supported.

	```lua
	local tbl = { test = true }
	DubitUtils.Table.deepFreeze(tbl)
	tbl.test = false -- will throw: attempt to modify a readonly table
	```

	@method deepFreeze
	@within DubitUtils.Table

	@param tbl { [any]: any }
]=]
--
function Table.deepFreeze<T>(tbl: T)
	assert(type(tbl) == "table", "First argument expected to be type of table")

	table.freeze(tbl)
	for _, value: any in tbl do
		if typeof(value) == "table" then
			Table.deepFreeze(value)
		end
	end
end

--[=[
	This function creates a deep copy of given table.

	Cyclical References not supported.

	```lua
	local tbl = { test = true }
	local tblClone = DubitUtils.Table.deepClone(tbl)
	tblClone.test = false -- will only modify the table contents of the tblClone
	print(tbl.test, tblClone.test) -- will print true, false
	```

	@method deepClone
	@within DubitUtils.Table

	@param tbl { [any]: any }

	@return { [any]: any }
]=]
--
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

--[=[
	Merges two given tables together, if source table has a property that other table has - it will be overwritten with the value of other table.

	Cyclical References not supported.

	```lua
	local tbl = { test = true, foo = 8 }
	local tblOther = { test = false, bar = 16 }
	local mergedTbl = DubitUtils.Table.merge(tbl, tblOther)
	print(mergedTbl) -- will print { test = false, foo = 8, bar = 16 }
	```

	@method merge
	@within DubitUtils.Table

	@param sourceTbl { [any]: any }
	@param otherTbl { [any]: any }

	@return { [any]: any }
]=]
--
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

--[=[
	Gets a random entry (key-value pair) from a given dictionary.

	@within DubitUtils.Table

	@param dictionary { Key: any, Value: any }) -- The dictionary to get a random entry from.

	@return { Key: any, Value: any } -- The key-value pair from the provided table corresponding to the randomly chosen key.

	#### Example Usage

	```lua
	DubitUtils.Table.getRandomDictionaryEntry({ foo = "apple", bar = "banana", var = "grape" })
	```
]=]
function Table.getRandomDictionaryEntry(dictionary: { [any]: any }): { Key: any, Value: any }
	local keys: { [number]: any } = {}
	for key in dictionary do
		table.insert(keys, key)
	end

	local randomKey = keys[math.random(#keys)]
	return { Key = randomKey, Value = dictionary[randomKey] }
end

--[=[
	'Stringifies' a table, recursively converting it to a string representation of its contents.

	@within DubitUtils.Table

	@param tableBase { any: any }) -- The table to convert to a string.
	@param options { spaces: number?, usesemicolon: boolean?, depth: number? } -- The options to use when converting the table to a string.
		-- spaces: number -- The number of spaces to use for indentation.
		-- usesemicolon: boolean -- Whether to use a semicolon instead of a comma for separating table entries.
		-- depth: number -- The depth of the table in the recursion to stringify up to.

	@return string -- The string representation of the provided table.

	#### Example Usage

	```lua
	local tbl = { test = true, foo = 8 }
	local stringifiedTable = DubitUtils.Table.TableToString(tbl)
	print(stringifiedTable) -- will print the below
		-- {
		-- 	["test"] = true;
		-- 	["foo"] = 8
		-- } 
	```
]=]
function Table.TableToString(
	tableBase: table,
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
	local concatenationBuilder = { "{" }

	for tableKey, tableValue in next, tableBase do
		table.insert(
			concatenationBuilder,
			("\n%s[%s] = %s%s"):format(
				space,
				type(tableKey) == "number" and tostring(tableKey) or ('"%s"'):format(tostring(tableKey)),
				Table.TableToString(tableValue, options),
				sep
			)
		)
	end

	local generatedString = table.concat(concatenationBuilder)
	local finalString = ("%s\n%s}"):format(generatedString:sub(1, -2), space:sub(1, -options.numSpaces - 1))

	return finalString
end

return Table
