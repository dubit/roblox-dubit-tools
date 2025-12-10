local Camera = {}

function Camera.zoomToExtents(camera: Camera, extentsInstance: BasePart | Model)
	--[[ An intermediary variable is used to workaround a LuauLSP error, wherein it cannot correctly infer the properties
	of the variable based on it's type due to it having 2 possible types, thus causing "Missing key" errors. ]]
	local _extentsInstance = extentsInstance

	local instanceCFrame = _extentsInstance:IsA("Model") and _extentsInstance:GetPivot() or _extentsInstance.CFrame
	local extentsSize = _extentsInstance:IsA("Model") and _extentsInstance:GetExtentsSize() or _extentsInstance.Size

	local halfSize = extentsSize.Magnitude / 2
	local fovDivisor = math.tan(math.rad(camera.FieldOfView / 2))
	local cameraOffset = halfSize / fovDivisor

	local cameraRotation = camera.CFrame - camera.CFrame.Position

	local instancePosition = instanceCFrame.Position
	camera.CFrame = cameraRotation + instancePosition + (-cameraRotation.LookVector * cameraOffset)
	camera.Focus = cameraRotation + instancePosition
end

return Camera
