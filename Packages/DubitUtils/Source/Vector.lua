--[=[
	@class DubitUtils.Vector
]=]

local Vector = {}

--[=[
	Returns a random point on the ground within a sphere radius around origin,
	if it doesn't find any ground point it returns the origin.

	@method findRandomGroundAroundPoint
	@within DubitUtils.Vector

	@param origin Vector3
	@param radius number
	@param params RaycastParams?

	@return Vector3
]=]
function Vector.findRandomGroundAroundPoint(origin: Vector3, radius: number, params: RaycastParams?): Vector3
	local randomAngle: number = math.random(0, 359)
	local randomRadius: number = math.random(radius * 0.75, radius)
	local x: number = math.sin(randomAngle) * randomRadius
	local z: number = math.cos(randomAngle) * randomRadius

	local raycastResult: RaycastResult = workspace:Raycast(
		origin + Vector3.new(x, radius, z),
		Vector3.new(0, -(radius * 2), 0),
		params or RaycastParams.new()
	)

	return raycastResult and raycastResult.Position or origin
end

--[=[
	Returns the nearest ground point within a sphere radius around origin, if it doesn't find any ground point it returns the origin.

	@method findNearestGroundAroundPoint
	@within DubitUtils.Vector

	@param origin Vector3
	@param radius number
	@param params RaycastParams?

	@return Vector3
]=]
function Vector.findNearestGroundAroundPoint(origin: Vector3, radius: number, params: RaycastParams?): Vector3
	local raycastResult: RaycastResult =
		workspace:Spherecast(origin, Vector3.one * radius, params or RaycastParams.new())

	return raycastResult and raycastResult.Position or origin
end

function Vector.quadraticBezier(time: number, p0, p1, p2)
	return (1 - time) ^ 2 * p0 + 2 * (1 - time) * time * p1 + time ^ 2 * p2
end

--[=[
	Gets and returns a random position within a given part, with the option to only randomise along the X & Z axes.

	@within DubitUtils.Vector

	@param part BasePart -- The part to get a random point within
	@param randomiseYPosition boolean? -- Whether or not to randomise the Y position of the point. Defaults to false.

	@return Vector3 -- The randomised Vector3 position within the part

	#### Example Usage

	```lua
	local teleportLocation = DubitUtils.Vector.getRandomPointInPart(workspace.TeleportArea, false)
	```
]=]
function Vector.getRandomPointInPart(part: BasePart, randomiseYPosition: boolean?): Vector3
	local random = Random.new()
	local yPosition = random:NextNumber(-part.Size.Y / 2, part.Size.Y / 2)
	if not randomiseYPosition then
		yPosition = 0
	end

	local xPosition = random:NextNumber(-part.Size.X / 2, part.Size.X / 2)
	local zPosition = random:NextNumber(-part.Size.Z / 2, part.Size.Z / 2)

	local randomPosition = Vector3.new(xPosition, yPosition, zPosition)
	return randomPosition
end

return Vector
