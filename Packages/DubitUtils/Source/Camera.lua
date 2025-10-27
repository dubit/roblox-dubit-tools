--[=[
	@class DubitUtils.Camera
]=]

local Camera = {}

--[=[
	Zooms the provided Camera instance to the extents of the provided BasePart or Model instance.

	@within DubitUtils.Camera

	@param camera Camera -- The camera instance to zoom.
	@param extentsInstance BasePart | Model -- The BasePart or Model instance to zoom the camera to the extents of.

	#### Example Usage

	```lua
	DubitUtils.Camera.zoomToExtents(workspace.CurrentCamera, currentShopItemModel)
	```
]=]
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
