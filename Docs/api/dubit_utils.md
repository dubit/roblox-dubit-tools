# API

## Accessory

### Functions

#### .isAssetTypeAccessory
```luau { .fn_type }
DubitUtils.Accessory.isAssetTypeAccessory(assetType: Enum.AssetType): boolean
```

Checks if the given asset type is an accessory.

??? example "Example Usage"
	```luau
	print(DubitUtils.Accessory.isAssetTypeAccessory(Enum.AssetType.ShortsAccessory)) --> true
	print(DubitUtils.Accessory.isAssetTypeAccessory(Enum.AssetType.Animation)) --> false
	```

---

#### .matchAssetTypeToAccessoryType
```luau { .fn_type }
DubitUtils.Accessory.matchAssetTypeToAccessoryType(assetType: Enum.AssetType): Enum.AccessoryType
```

Matches the given asset type to its corresponding accessory type.

??? example "Example Usage"
	```luau
	print(DubitUtils.Accessory.matchAssetTypeToAccessoryType(Enum.AssetType.Hat)) --> Enum.AccessoryType.Hat
	```

## Camera

### Functions

#### .zoomToExtents
```luau { .fn_type }
DubitUtils.Camera.zoomToExtents(camera: Camera, extentsInstance: BasePart | Model): ()
```

Zooms the provided Camera instance to the extents of the provided BasePart or Model instance.

## Character

### Functions

#### .cloneCharacter
```luau { .fn_type }
DubitUtils.Character.cloneCharacter(character: Model, isAnchored: boolean?): Model?
```

Creates a clone of the provided character, without overhead display of display name & health.

---

#### .resetCharacterTransparency
```luau { .fn_type }
DubitUtils.Character.resetCharacterTransparency(character: Model, tweenInfo: TweenInfo?): ()
```

Resets the transparency of all parts within the provided character to the original value, if it was made invisible via Character.setCharacterTransparency.

!!! notice
	This function must be used in conjunction with **[setCharacterTransparency](#setcharactertransparency)**, which stores the original transparency values of each part. If the character did not have its transparency modified via that function, this function will fail.

---

#### .setCharacterFrozen
```luau { .fn_type }
DubitUtils.Character.setCharacterFrozen(character: Model, frozen: boolean?): ()
```

Set a provided character to be frozen or unfrozen.

---

#### .setCharacterTransparency
```luau { .fn_type }
DubitUtils.Character.setCharacterTransparency(character: Model, targetTransparency: number, tweenInfo: TweenInfo?): ()
```

Sets the transparency of all valid parts within the provided character to the provided value. This will also apply to any valid parts which become a descendant of the character before transparency values are reset.

!!! notice
	This function is usually intended to be used in conjunction with **[resetCharacterTransparency](#resetcharactertransparency)**, as it will restore the original transparency values of each part, which are stored through this function.

## Instance

### Functions

#### .findAncestorWithTag
```luau { .fn_type }
DubitUtils.InstanceUtility.findAncestorWithTag(instance: Instance, tag: string): Instance?
```

Finds & returns the first ancestor of the given instance with the provided tag, if there is one.

!!! notice
	This function will ignore the provided instance, and only check its ancestors.

---

#### .findDescendantsWithTag
```luau { .fn_type }
DubitUtils.InstanceUtility.findDescendantsWithTag(instance: Instance, tag: string): Instance?
```

!!! danger
	It is advised to use **[QueryDescendants](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants)** instead.

Finds & returns a table of descendants of the given instance which have the provided tag.

!!! notice
	This function will ignore the provided instance, and only check its ancestors.

---

#### .setDescendantTransparency
```luau { .fn_type }
DubitUtils.InstanceUtility.setDescendantTransparency(instance: Instance, transparency: number): Instance?
```

Sets the transparency of a given instance and all of its descendants to a provided value. The transprency to set may be any number, however only values between 0 and 1 are supported (e.g. providing a value above 1 will be equivalent to providing 1).

!!! notice
	This function will dynamically set either the LocalTransparencyModifier (client, will not replicate) or the Transparency of the instance (server, will replicate), depending on whether the function is called from the client or the server.

---

#### .verifyInstance
```luau { .fn_type }
DubitUtils.InstanceUtility.verifyInstance(instanceName: string, instanceType: string, instanceParent: Instance?, timeout: number?): Instance?
```

!!! danger
	This function yields.

Ensure that an Instance exists within the given parent Instance, and create it if it does not exist.=

!!! danger
	Developers should ensure that the provided 'instanceType' equates to a valid Instance subclass. This is something that as of current can not be natively checked in Lua/Luau, so will cause an error if it is not valid.

---

#### .waitForChildren
```luau { .fn_type }
DubitUtils.InstanceUtility.waitForChildren(instance: Instance, query: string, timeout: number?): Instance?
```

!!! danger
	This function yields.

Wait for a series of children to appear in an instance.

!!! warning
	Will return nil if any of the children do not appear within the provided timeout.

## Number

### Functions

#### .abbreviate
```luau { .fn_type }
DubitUtils.Number.abbreviate(numberToAbbreviate: number, includePlusSymbol: boolean?, decimals: number?): string
```

Abbreviates the given number with a large number notation, depending on the nearest power of one thousand lower than it, up to 10 ^ 30 ("N").

??? example "Example Usage"
	```lua
	print(DubitUtils.Number.abbreviate(372)) --> 372
	print(DubitUtils.Number.abbreviate(59678)) --> 59K+
	print(DubitUtils.Number.abbreviate(59678, false)) --> 59K
	print(DubitUtils.Number.abbreviate(1000000000)) --> 1B
	print(DubitUtils.Number.abbreviate(4967827362967902)) --> 4Qd+
	print(DubitUtils.Number.abbreviate(4967827362967902, true, 2)) --> 4.96Qd+
	```

---

#### .formatDigitLength
```luau { .fn_type }
DubitUtils.Number.formatDigitLength(numberToFormat: number, minimumDigitLength: number): string
```

!!! danger
	It is advised to use **[string.format](https://www.lua.org/pil/20.html)** instead, there is really no reason for this function to exist.

Adds trailing zeros preceding the given number until it is at least the given length of digits.

??? example "Example Usage"
	```lua
	print(DubitUtils.Number.formatDigitLength(48, 4)) --> 0048
	```

---

#### .roundToNearest
```luau { .fn_type }
DubitUtils.Number.roundToNearest(numberToRound: number, roundTo: number): number
```

Rounds a given number to the nearest multiple of the given 'roundTo' number.

??? example "Example Usage"
	```lua
	print(DubitUtils.Number.roundToNearest(37, 5)) --> 35
	```

---

#### .lerp
```luau { .fn_type }
DubitUtils.Number.roundToNearest(valueA: number, valueB: number, time: number): number
```

!!! danger
	It is advised to use **[math.lerp](https://luau.org/library#math-library)** instead.

Linearly interpolates between valueA and valueB by time.

When time = 0 returns a When time = 1 return b When time = 0.5 returns the midpoint of a and b

The time value isn't clamped!

??? example "Example Usage"
	```lua
	print(DubitUtils.Number.lerp(1.00, 2.00, 0.50)) --> 1.50
	print(DubitUtils.Number.lerp(0.00, 1.00, 0.70)) --> 0.70
	print(DubitUtils.Number.lerp(15.00, 30.00, 0.20)) --> 18.00
	print(DubitUtils.Number.lerp(0.00, 1.00, 2.00)) --> 2.00
	```


## RobloxGroup

### Functions

#### .getMemberRank
```luau { .fn_type }
DubitUtils.RobloxGroup.getMemberRank(player: Player, groupId: number?, retries: number?): number?
```

Get the rank of the given player in the group with the ID provided.

!!! warning
	If **groupId** is not provided and the creator ID of the current experience is not that of a group, this function will fail and return nil.

---

#### .isPlayerAboveGroupRank
```luau { .fn_type }
DubitUtils.RobloxGroup.isPlayerAboveGroupRank(player: Player, minimumGroupRank: number, whitelist: {[number]: any}?, retries: number?, creatorIdOverride: number?): boolean
```

Check if the specified player is at or above the provided group rank, or otherwise succeeds the permissions of that rank. Returns true if any of the following conditions have been met:
- The group rank of the player in the specified group matches or exceeds the minimum group rank
- The player is the owner of the game
- The player is whitelisted
- The game is running in Studio

## Table

### Functions

#### .compare
```luau { .fn_type }
DubitUtils.Table.compare(source: {[any]: any}, other: {[any]: any}): boolean
```

This function roughly (It won't traverse other tables) compares two tables, both arrays and dictionaries are supported.

Cyclical References not supported.

??? example "Example Usage"
	```lua
	local tbl_one = { test = true }
	local tbl_two = { test = true, hello = "world" }
	print(DubitUtils.Table.compare(tbl)) --> false

	local tbl_one = { test = true }
	local tbl_two = { test = true }
	print(DubitUtils.Table.compare(tbl)) --> true


	local tbl_one = { test = true, nested = { foo = "bar" } }
	local tbl_two = { test = true, nested = { foo = "bar" } }
	print(DubitUtils.Table.compare(tbl)) --> false, the table entries are roughly compared, both values of nested fields point to different tables
	```

---

#### .compareDeep
```luau { .fn_type }
DubitUtils.Table.compareDeep(source: {[any]: any}, other: {[any]: any}): boolean
```

This function deeply compares two tables, both arrays and dictionaries are supported.

Cyclical References not supported.

??? example "Example Usage"
	```lua
	local tbl_one = { test = true }
	local tbl_two = { test = true, hello = "world" }
	print(DubitUtils.Table.compareDeep(tbl)) --> false

	local tbl_one = { test = true }
	local tbl_two = { test = true }
	print(DubitUtils.Table.compareDeep(tbl)) --> true


	local tbl_one = { test = true, nested = { foo = "bar" } }
	local tbl_two = { test = true, nested = { foo = "bar" } }
	print(DubitUtils.Table.compareDeep(tbl)) --> true
	```

---

#### .deepClone
```luau { .fn_type }
DubitUtils.Table.deepClone(tbl: T): T
```

This function creates a deep copy of given table.

Cyclical References not supported.

??? example "Example Usage"
	```lua
	local tbl = { test = true }
	local tblClone = DubitUtils.Table.deepClone(tbl)
	tblClone.test = false -- will only modify the table contents of the tblClone
	print(tbl.test, tblClone.test) --> true, false
	```

---

#### .deepFreeze
```luau { .fn_type }
DubitUtils.Table.deepFreeze(tbl: {[any]: any})
```

This function deep freezes the table making it read only.

Cyclical References not supported.

??? example "Example Usage"
	```lua
	local tbl = { test = true }
	DubitUtils.Table.deepFreeze(tbl)
	tbl.test = false --> attempt to modify a readonly table
	```

---

#### .merge
```luau { .fn_type }
DubitUtils.Table.merge(source: {[any]: any}, other: {[any]: any})
```

Merges two given tables together, if source table has a property that other table has - it will be overwritten with the value of other table.

Cyclical References not supported.

??? example "Example Usage"
	```lua
	local tbl = { test = true, foo = 8 }
	local tblOther = { test = false, bar = 16 }
	print(DubitUtils.Table.merge(tbl, tblOther)) --> { test = false, foo = 8, bar = 16 }
	```

---

#### .getRandomDictionaryEntry
```luau { .fn_type }
DubitUtils.Table.merge(source: {[string]: any}, other: {[string]: any})
```

Gets a random entry (key-value pair) from a given dictionary.

---

#### .TableToString
```luau { .fn_type }
DubitUtils.Table.TableToString(tableBase: {[any]: any}), options: { spaces: number?, usesemicolon: boolean?, depth: number? }): string
```

'Stringifies' a table, recursively converting it to a string representation of its contents.

Options:
**spaces** - The number of spaces to use for indentation
**usesemicolon** - Whether to use a semicolon instead of a comma for separating table entries
**depth** - The depth of the table in the recursion to stringify up to

??? example "Example Usage"
	```lua
	local tbl = { test = true, foo = 8 }
	local stringifiedTable = DubitUtils.Table.TableToString(tbl)
	print(stringifiedTable)
	--> {
	--> 	["test"] = true;
	--> 	["foo"] = 8
	--> } 
	```

## Time

### Functions

#### .formatToCountdownTimer
```luau { .fn_type }
DubitUtils.Time.formatToCountdownTimer(seconds: number): string
```

Formats seconds to countdown timer format (hr:mm:ss).

??? example "Example Usage"
	```lua
	print(DubitUtils.Time.formatToCountdownTimer(59)) --> 00:00:59
	print(DubitUtils.Time.formatToCountdownTimer(127)) --> 00:02:07
	print(DubitUtils.Time.formatToCountdownTimer(86399)) --> 23:59:59
	```

---

#### .formatToRaceTimer
```luau { .fn_type }
DubitUtils.Time.formatToRaceTimer(seconds: number): string
```

Formats seconds to race like timer format (mm:ss:msms). This differs from Time.formatToRaceTimer as this one gives a lot more precise time back. (Useful for racing games)

??? example "Example Usage"
	```lua
	print(DubitUtils.Time.formatToRaceTimer(59.99)) --> 00:59.990
	print(DubitUtils.Time.formatToRaceTimer(127.138)) --> 02:07.138
	print(DubitUtils.Time.formatToRaceTimer(16.552)) --> 00:16.552
	print(DubitUtils.Time.formatToRaceTimer(6)) --> 00:06.000
	```

---

#### .formatSecondsToMinutesAndSeconds
```luau { .fn_type }
DubitUtils.Time.formatSecondsToMinutesAndSeconds(seconds: number, useNotations: boolean?): string
```

Formats the given time in seconds to minutes and seconds, in the format of minutes:seconds or \[minutes\]m\[seconds\]s

??? example "Example Usage"
	```lua
	print(DubitUtils.Time.formatSecondsToMinutesAndSeconds(1235)) --> 20:35
	print(DubitUtils.Time.formatSecondsToMinutesAndSeconds(12)) --> 00:12
	print(DubitUtils.Time.formatSecondsToMinutesAndSeconds(1235, true)) --> 20m35s
	print(DubitUtils.Time.formatSecondsToMinutesAndSeconds(12, true)) --> 12s
	```

---
	
#### .getFormattedTimeOfDay
```luau { .fn_type }
DubitUtils.Time.getFormattedTimeOfDay(unixTimestamp: number?): string
```

Formats the given time of day provided as a timestamp in the format of hours:minutes:seconds, formatting the current time of day if no timestamp is provided.

??? example "Example Usage"
	```lua
	print(DubitUtils.Time.getFormattedTimeOfDay()) -- will print current time in the 00:00:00 format
	print(DubitUtils.Time.getFormattedTimeOfDay(1702723900)) --> 10:51:40
	```

## Vector

### Functions

#### .findNearestGroundAroundPoint
```luau { .fn_type }
DubitUtils.Vector.findNearestGroundAroundPoint(origin: Vector3, radius: number, params: RaycastParams?): Vector3
```

Returns the nearest ground point within a sphere radius around origin, if it doesn't find any ground point it returns the origin.

---

#### .findRandomGroundAroundPoint
```luau { .fn_type }
DubitUtils.Vector.findRandomGroundAroundPoint(origin: Vector3, radius: number, params: RaycastParams?): Vector3
```

Returns a random point on the ground within a sphere radius around origin, if it doesn't find any ground point it returns the origin.

---

#### .getRandomPointInPart
```luau { .fn_type }
DubitUtils.Vector.getRandomPointInPart(part: BasePart, randomiseYPosition: boolean?): Vector3
```

Gets and returns a random position within a given part, with the option to only randomise along the X & Z axes and optionally Y axis.

## fzy

### Functions

#### .filter
```luau { .fn_type }
DubitUtils.fzy.filter(needle: string, haystack: string, caseSensitive: boolean?): {{number,{number},number}}
```

---

#### .hasMatch
```luau { .fn_type }
DubitUtils.fzy.hasMatch(needle: string, haystack: string, caseSensitive: boolean?): boolean
```

Check if needle is a subsequence of the haystack.

Usually called before score or positions.

---

#### .positions
```luau { .fn_type }
DubitUtils.fzy.positions(needle: string, haystack: string, caseSensitive: boolean?): {[number]: number}
```

Compute the locations where fzy matches a string.

Determine where each character of the needle is matched to the haystack in the optimal match.

---

#### .score
```luau { .fn_type }
DubitUtils.fzy.score(needle: string, haystack: string, caseSensitive: boolean?): number
```

Compute a matching score.