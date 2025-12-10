local Time = {}

function Time.formatToRaceTimer(seconds: number): string
	local _seconds: number = seconds
	local minutes: number = (seconds - _seconds % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	return string.format("%02i:%02i.%02i", minutes - hours * 60, _seconds - minutes * 60, (_seconds * 100) % 100)
end

function Time.formatToRaceTimerDetailed(seconds: number): string
	local _seconds: number = seconds
	local minutes: number = (seconds - _seconds % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	return string.format("%02i:%02i.%03i", minutes - hours * 60, _seconds - minutes * 60, (_seconds * 1000) % 1000)
end

function Time.formatToCountdownTimer(seconds: number): string
	local _seconds: number = math.round(seconds)
	local minutes: number = (seconds - _seconds % 60) / 60
	local hours: number = (minutes - minutes % 60) / 60

	return string.format("%02i:%02i:%02i", hours, minutes - hours * 60, _seconds - minutes * 60)
end

function Time.getFormattedTimeOfDay(timeStamp: number?): string
	timeStamp = timeStamp or DateTime.now().UnixTimestamp

	local formattedTime = os.date("%X", timeStamp)
	return formattedTime
end

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
