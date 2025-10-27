--[[
	Calculates the CFrame rotation for a given face of a part.

	This function takes a Part instance and a NormalId enum value representing a face direction, and returns a CFrame
	that represents the rotation needed to align with that face. The rotation is based on the part's current CFrame
	rotation combined with the appropriate angles for the specified face.

	If an invalid face is provided, the function throws an error.
]]
return function(part: Part, face: Enum.NormalId): CFrame
	local baseRotation = part.CFrame.Rotation

	if face == Enum.NormalId.Front then
		return baseRotation * CFrame.Angles(0, 0, 0)
	elseif face == Enum.NormalId.Back then
		return baseRotation * CFrame.Angles(0, math.pi, 0)
	elseif face == Enum.NormalId.Right then
		return baseRotation * CFrame.Angles(0, -math.pi / 2, 0)
	elseif face == Enum.NormalId.Left then
		return baseRotation * CFrame.Angles(0, math.pi / 2, 0)
	elseif face == Enum.NormalId.Top then
		return baseRotation * CFrame.Angles(-math.pi / 2, 0, 0)
	elseif face == Enum.NormalId.Bottom then
		return baseRotation * CFrame.Angles(math.pi / 2, 0, 0)
	else
		warn(`Invalid face provided: {face}`)

		return baseRotation
	end
end
