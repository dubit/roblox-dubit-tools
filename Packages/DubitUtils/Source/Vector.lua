local Vector = {}

function Vector.findRandomGroundAroundPoint(origin: Vector3, radius: number, params: RaycastParams?): Vector3
	local randomAngle = math.random(0, 359)
	local randomRadius = math.random(radius * 0.75, radius)
	local x = math.sin(randomAngle) * randomRadius
	local z = math.cos(randomAngle) * randomRadius

	local raycastResult = workspace:Raycast(
		origin + Vector3.new(x, radius, z),
		Vector3.new(0, -(radius * 2), 0),
		params or RaycastParams.new()
	)

	return raycastResult and raycastResult.Position or origin
end

function Vector.findNearestGroundAroundPoint(origin: Vector3, radius: number, params: RaycastParams?): Vector3
	local raycastResult = workspace:Spherecast(origin, Vector3.one * radius, params or RaycastParams.new())

	return raycastResult and raycastResult.Position or origin
end

function Vector.quadraticBezier(time: number, p0, p1, p2)
	return (1 - time) ^ 2 * p0 + 2 * (1 - time) * time * p1 + time ^ 2 * p2
end

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
