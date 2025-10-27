local IAB_MAX_AD_SCREEN_ANGLE = 55

--[[
	Determines if a part's facing direction is within a specified angular threshold compared to a target direction.

	This function calculates the angle between the part's LookVector and a provided target vector (which should be
	normalized). It then checks if this angle is less than or equal to the maximum allowed angle
]]
return function(faceCFrame: CFrame, targetDirection: Vector3)
	local localTarget = faceCFrame:VectorToObjectSpace(targetDirection.Unit)
	local dotValue = localTarget:Dot(Vector3.new(0, 0, 1))

	dotValue = math.clamp(dotValue, -1, 1)

	local angleDeg = math.deg(math.acos(dotValue))

	return angleDeg <= IAB_MAX_AD_SCREEN_ANGLE
end
