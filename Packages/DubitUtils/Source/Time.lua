--[=[
	@class DubitUtils.Time
]=]

local Time = {}

--[=[
	Formats seconds to race like timer format (mm:ss:ms).

	```lua
	DubitUtils.Time.formatToRaceTimer(59.99) -- will print 00:59.99
	DubitUtils.Time.formatToRaceTimer(127.13) -- will print 02:07.13
	DubitUtils.Time.formatToRaceTimer(16.55) -- will print 00:16.55
	DubitUtils.Time.formatToRaceTimer(6) -- will print 00:06.00
	```

	@method formatToRaceTimer
	@within DubitUtils.Time

	@param seconds number

	@return string
]=]
--
function Time.formatToRaceTimer(seconds: number): string
	local _seconds: number = seconds
	local minutes: number = (seconds - _seconds % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	return string.format("%02i:%02i.%02i", minutes - hours * 60, _seconds - minutes * 60, (_seconds * 100) % 100)
end

--[=[
	Formats seconds to race like timer format (mm:ss:msms).
	This differs from Time.formatToRaceTimer as this one gives a lot more precise time back. (Useful for racing games)

	```lua
	DubitUtils.Time.formatToRaceTimer(59.99) -- will print 00:59.990
	DubitUtils.Time.formatToRaceTimer(127.138) -- will print 02:07.138
	DubitUtils.Time.formatToRaceTimer(16.552) -- will print 00:16.552
	DubitUtils.Time.formatToRaceTimer(6) -- will print 00:06.000
	```

	@method formatToRaceTimer
	@within DubitUtils.Time

	@param seconds number

	@return string
]=]
--
function Time.formatToRaceTimerDetailed(seconds: number): string
	local _seconds: number = seconds
	local minutes: number = (seconds - _seconds % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	return string.format("%02i:%02i.%03i", minutes - hours * 60, _seconds - minutes * 60, (_seconds * 1000) % 1000)
end

--[=[
	Formats seconds to countdown timer format (hr:mm:ss).

	```lua
	DubitUtils.Time.formatToCountdownTimer(59) -- will print 00:00:59
	DubitUtils.Time.formatToCountdownTimer(127) -- will print 00:02:07
	DubitUtils.Time.formatToCountdownTimer(86399) -- will print 23:59:59
	```

	@method formatToCountdownTimer
	@within DubitUtils.Time

	@param seconds number

	@return string
]=]
--
function Time.formatToCountdownTimer(seconds: number): string
	local _seconds: number = math.round(seconds)
	local minutes: number = (seconds - _seconds % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	return string.format("%02i:%02i:%02i", hours, minutes - hours * 60, _seconds - minutes * 60)
end

--[=[
	Formats the given time of day provided as a timestamp in the format of hours:minutes:seconds,
	formatting the current time of day if no timestamp is provided.

	@within DubitUtils.Time

	@param timeStamp number? -- The timestamp number respresenting the time of day to format. Defaults to the current timestamp based on DateTime.now()

	@return string -- The formatted time of day based on the given timestamp

	#### Example Usage
	
	```lua
	DubitUtils.Time.getFormattedTimeOfDay() -- will print the current os.time(), in the format 00:00:00
	DubitUtils.Time.getFormattedTimeOfDay(1702723900) -- will print 10:51:40
	```
]=]
function Time.getFormattedTimeOfDay(timeStamp: number?): string
	timeStamp = timeStamp or DateTime.now().UnixTimestamp

	local formattedTime = os.date("%X", timeStamp)
	return formattedTime
end

--[=[
	Formats the given time in seconds to minutes and seconds, in the format of minutes:seconds or [minutes]m[seconds]s

	@within DubitUtils.Time

	@param seconds number -- The amount of time in seconds to format
	@param useNotations boolean? -- Determines if the formatted time should use notations (e.g.0m/0s) or not (e.g.00:00)

	@return string -- The formatted time in minutes and seconds

	#### Example Usage
	
	```lua
	DubitUtils.Time.formatSecondsToMinutesAndSeconds(1235) -- will print 20:35
	DubitUtils.Time.formatSecondsToMinutesAndSeconds(12) -- will print 00:12
	DubitUtils.Time.formatSecondsToMinutesAndSeconds(1235, true) -- will print 20m35s
	DubitUtils.Time.formatSecondsToMinutesAndSeconds(12, true) -- will print 12s
	```
]=]
function Time.formatSecondsToMinutesAndSeconds(seconds: number, useNotations: boolean?)
	local isTimeNegative = seconds < 0
	if isTimeNegative then
		seconds = math.abs(seconds)
	end

	local _seconds = math.floor(seconds % 60)
	local minutes = math.floor((seconds % 3600) / 60)

	local formattedTime

	if useNotations then
		if minutes <= 0 then
			formattedTime = string.format("%02ds", _seconds)
		else
			formattedTime = string.format("%02dm%02ds", minutes, _seconds)
		end
	else
		formattedTime = string.format("%02d:%02d", minutes, _seconds)
	end

	if isTimeNegative then
		formattedTime = `-{formattedTime}`
	end

	return formattedTime
end

return Time
