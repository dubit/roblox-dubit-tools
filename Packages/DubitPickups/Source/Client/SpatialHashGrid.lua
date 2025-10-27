--[[
	A Luau implementation of a Spatial Hash Grid, enabling us to efficiently compute the location of 
	objects within a given range of a given position.
]]

local SpatialHashGrid = {}

function SpatialHashGrid:RemoveObject(object: Instance)
	local hashKey = self.keys[object]

	if not hashKey then
		return
	end

	local cell = hashKey and self.cells[hashKey]

	if not cell then
		return
	end

	local index = cell and table.find(cell, object)

	if index then
		self.keys[object] = nil

		table.remove(cell, index)
	end
end

function SpatialHashGrid:AddObject(position: Vector3, object: any)
	local hashKey = self:NormalizeVector(position)

	if not self.cells[hashKey] then
		self.cells[hashKey] = {}
	end

	self.keys[object] = hashKey

	table.insert(self.cells[hashKey], object)
end

function SpatialHashGrid:InRange(position: Vector3, range: number)
	local normalizedPosition = self:NormalizeVector(position)
	local normalizedRange = math.round(range / self.cellSize)

	local objects = {}

	--[[
		Cell - a box, space, container inside of a virtual grid, this isn't an instance, but a representation
			of a space that we can manipulate.

		Below, we iterate from the cell that matches the position passed in at argument 1, out - by however much argument 2 defines.
			this allows us to search neighboring cells for objects we can return at the end of this call.
	]]

	for cellPositionX = -normalizedRange, normalizedRange do
		for cellPositionY = -normalizedRange, normalizedRange do
			for cellPositionZ = -normalizedRange, normalizedRange do
				local positionToCheck = Vector3.new(
					normalizedPosition.X + cellPositionX,
					normalizedPosition.Y + cellPositionY,
					normalizedPosition.Z + cellPositionZ
				)

				local cell = self.cells[positionToCheck]

				if not cell or #cell == 0 then
					continue
				end

				table.move(cell, 1, #cell, #objects + 1, objects)
			end
		end
	end

	return objects
end

function SpatialHashGrid:NormalizeVector(position: Vector3)
	return Vector3.new(
		math.floor(position.X / self.cellSize),
		math.floor(position.Y / self.cellSize),
		math.floor(position.Z / self.cellSize)
	)
end

function SpatialHashGrid.new()
	return setmetatable({
		cells = {},
		keys = {},

		cellSize = 24,
	}, {
		__index = SpatialHashGrid,
	})
end

return SpatialHashGrid
