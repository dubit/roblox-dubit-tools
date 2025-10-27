local function deserialiseTweenInfo(object)
	return TweenInfo.new(
		object.time,
		object.easingStyle,
		object.easingDirection,
		object.repeatCount,
		object.reverses,
		object.delayTime
	)
end

local function serialiseTweenInfo(object)
	return {
		time = object.Time,
		easingStyle = object.EasingStyle.Value,
		easingDirection = object.EasingDirection.Value,
		repeatCount = object.RepeatCount,
		reverses = object.Reverses,
		delayTime = object.DelayTime,
	}
end

return function(Serialisation)
	Serialisation:Implement("TweenInfo", serialiseTweenInfo, deserialiseTweenInfo)
end
